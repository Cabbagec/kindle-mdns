#!/bin/sh
# ARM mDNS daemon watchdog script for systems without init systems
# This script provides daemon functionality for the arm-mdns service

# Default values
HOST_NAME="device"
BINARY_PATH="/usr/local/bin/arm-mdns"
DAEMON_NAME="arm-mdns"
PID_FILE="/var/run/$DAEMON_NAME.pid"
LOG_FILE="/var/log/$DAEMON_NAME.log"
CHECK_INTERVAL=30  # Check every 30 seconds

# Create directories if they don't exist
ensure_dirs() {
    mkdir -p "$(dirname "$PID_FILE")" 2>/dev/null
    mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null

    # If we can't write to /var, use local directory
    if [ ! -w "$(dirname "$PID_FILE")" ]; then
        PID_FILE="$HOME/.$DAEMON_NAME.pid"
    fi

    if [ ! -w "$(dirname "$LOG_FILE")" ]; then
        LOG_FILE="$HOME/.$DAEMON_NAME.log"
    fi
}

# Log message to log file
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo "$1"
}

# Check if process is running
is_running() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            return 0  # Process is running
        else
            return 1  # Process is not running but PID file exists
        fi
    else
        return 1  # PID file doesn't exist
    fi
}

# Start the daemon
start_daemon() {
    if is_running; then
        log "$DAEMON_NAME is already running with PID $(cat "$PID_FILE")"
        return 0
    fi

    log "Starting $DAEMON_NAME..."

    # Start the daemon with the specified hostname
    nohup "$BINARY_PATH" "$HOST_NAME" > "$LOG_FILE" 2>&1 &
    PID=$!

    # Save PID to file
    echo $PID > "$PID_FILE"

    # Check if process started successfully
    sleep 1
    if is_running; then
        log "$DAEMON_NAME started with PID $PID"
        return 0
    else
        log "Failed to start $DAEMON_NAME"
        return 1
    fi
}

# Stop the daemon
stop_daemon() {
    # First stop the main daemon
    if is_running; then
        PID=$(cat "$PID_FILE")
        log "Stopping $DAEMON_NAME with PID $PID..."

        # Try graceful termination first
        kill "$PID"

        # Wait for process to terminate
        for i in 1 2 3 4 5; do
            if ! is_running; then
                break
            fi
            sleep 1
        done

        # Force kill if still running
        if is_running; then
            log "Force killing $DAEMON_NAME..."
            kill -9 "$PID"
            sleep 1
        fi

        if ! is_running; then
            rm -f "$PID_FILE"
            log "$DAEMON_NAME stopped"
        else
            log "Failed to stop $DAEMON_NAME"
            return 1
        fi
    else
        log "$DAEMON_NAME is not running"
        rm -f "$PID_FILE"
    fi

    # Now stop the monitor daemon if it's running
    MONITOR_PID_FILE="${PID_FILE}.monitor"
    if [ -f "$MONITOR_PID_FILE" ]; then
        MONITOR_PID=$(cat "$MONITOR_PID_FILE")
        if kill -0 "$MONITOR_PID" 2>/dev/null; then
            log "Stopping monitor daemon with PID $MONITOR_PID..."

            # Try graceful termination first
            kill "$MONITOR_PID"

            # Wait for process to terminate
            for i in 1 2 3 4 5; do
                if ! kill -0 "$MONITOR_PID" 2>/dev/null; then
                    break
                fi
                sleep 1
            done

            # Force kill if still running
            if kill -0 "$MONITOR_PID" 2>/dev/null; then
                log "Force killing monitor daemon..."
                kill -9 "$MONITOR_PID"
                sleep 1
            fi

            if ! kill -0 "$MONITOR_PID" 2>/dev/null; then
                rm -f "$MONITOR_PID_FILE"
                log "Monitor daemon stopped"
            else
                log "Failed to stop monitor daemon"
            fi
        else
            log "Monitor daemon is not running"
            rm -f "$MONITOR_PID_FILE"
        fi
    fi

    return 0
}

# Monitor and restart the daemon if it crashes
monitor_daemon() {
    log "Starting watchdog for $DAEMON_NAME..."

    # Start daemon if not running
    if ! is_running; then
        start_daemon
    fi

    # Monitor loop
    while true; do
        if ! is_running; then
            log "$DAEMON_NAME has crashed, restarting..."
            start_daemon
        fi

        sleep $CHECK_INTERVAL
    done
}

# Show daemon status
show_status() {
    DAEMON_RUNNING=0

    # Check main daemon status
    if is_running; then
        PID=$(cat "$PID_FILE")
        log "$DAEMON_NAME is running with PID $PID"
        ps -p "$PID" -o pid,ppid,cmd,etime,rss,vsz 2>/dev/null
        DAEMON_RUNNING=1
    else
        log "$DAEMON_NAME is not running"
    fi

    # Check monitor daemon status
    MONITOR_PID_FILE="${PID_FILE}.monitor"
    if [ -f "$MONITOR_PID_FILE" ]; then
        MONITOR_PID=$(cat "$MONITOR_PID_FILE")
        if kill -0 "$MONITOR_PID" 2>/dev/null; then
            log "Monitor daemon is running with PID $MONITOR_PID"
            ps -p "$MONITOR_PID" -o pid,ppid,cmd,etime,rss,vsz 2>/dev/null
        else
            log "Monitor daemon is not running (stale PID file)"
            rm -f "$MONITOR_PID_FILE"
        fi
    else
        log "Monitor daemon is not running"
    fi

    return $((1 - DAEMON_RUNNING))
}

# Main function
main() {
    ensure_dirs

    case "$1" in
        start)
            start_daemon
            ;;
        stop)
            stop_daemon
            ;;
        restart)
            stop_daemon
            start_daemon
            ;;
        status)
            show_status
            ;;
        monitor)
            # Start monitoring in background
            if [ "$2" = "background" ]; then
                nohup "$0" monitor_loop > /dev/null 2>&1 &
                echo $! > "${PID_FILE}.monitor"
                log "Watchdog started in background with PID $!"
            else
                monitor_daemon
            fi
            ;;
        monitor_loop)
            # This is called by the monitor background command
            monitor_daemon
            ;;
        *)
            echo "Usage: $0 {start|stop|restart|status|monitor [background]}"
            echo "  start    - Start the daemon"
            echo "  stop     - Stop the daemon"
            echo "  restart  - Restart the daemon"
            echo "  status   - Show daemon status"
            echo "  monitor  - Monitor and auto-restart the daemon if it crashes"
#            echo "    background - Run monitor in background"
            exit 1
            ;;
    esac
}

# Set hostname if provided as second argument to start or monitor
if [ "$2" != "" ] && [ "$2" != "background" ]; then
    HOST_NAME="$2"
fi

main "$@"
