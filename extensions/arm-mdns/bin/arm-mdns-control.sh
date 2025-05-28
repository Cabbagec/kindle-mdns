#!/bin/sh
# ARM mDNS daemon control script

# Default values
HOST_NAME="device"
BINARY_PATH="/usr/local/bin/arm-mdns"
DAEMON_NAME="arm-mdns"

# Systemd paths
SYSTEMD_SERVICE_FILE="/etc/systemd/system/$DAEMON_NAME.service"

# Init.d paths
INITD_SERVICE_FILE="/etc/init.d/$DAEMON_NAME"
DEFAULT_CONFIG="/etc/default/$DAEMON_NAME"

# Watchdog paths
WATCHDOG_DIR="/usr/local/lib/$DAEMON_NAME"
WRAPPER_SCRIPT="/usr/local/bin/$DAEMON_NAME-control"

# Detect init system
detect_init_system() {
    if command -v systemctl >/dev/null 2>&1; then
        echo "systemd"
    elif [ -d "/etc/init.d" ]; then
        echo "initd"
    else
        echo "unknown"
    fi
}

INIT_SYSTEM=$(detect_init_system)

# Function to install the service
install() {
    echo "Installing ARM mDNS daemon..."

    # Copy binary to system path
    if [ -f "./arm-mdns" ]; then
        cp ./arm-mdns $BINARY_PATH
        chmod +x $BINARY_PATH
    else
        echo "Error: arm-mdns binary not found in current directory"
        exit 1
    fi

    # Set hostname if provided
    if [ "$1" != "" ]; then
        HOST_NAME="$1"
    fi

    # Install service based on init system
    case "$INIT_SYSTEM" in
        systemd)
            install_systemd
            ;;
        initd)
            install_initd
            ;;
        *)
            install_watchdog
            ;;
    esac
}

# Install for systemd
install_systemd() {
    if [ -f "./arm-mdns.service" ]; then
        cp ./arm-mdns.service $SYSTEMD_SERVICE_FILE
        chmod 644 $SYSTEMD_SERVICE_FILE

        # Update hostname in service file
        sed -i "s/arm-mdns device/arm-mdns $HOST_NAME/g" $SYSTEMD_SERVICE_FILE

        # Reload systemd
        systemctl daemon-reload
        echo "Service installed (systemd). You can now start it with: systemctl start $DAEMON_NAME"
    else
        echo "Error: arm-mdns.service file not found in current directory"
        exit 1
    fi
}

# Install for init.d
install_initd() {
    if [ -f "./init.d-script" ]; then
        cp ./init.d-script $INITD_SERVICE_FILE
        chmod 755 $INITD_SERVICE_FILE

        # Create default config
        mkdir -p $(dirname $DEFAULT_CONFIG)
        echo "# Configuration for $DAEMON_NAME" > $DEFAULT_CONFIG
        echo "DAEMON_ARGS=\"$HOST_NAME\"" >> $DEFAULT_CONFIG

        # Enable service
        if command -v update-rc.d >/dev/null 2>&1; then
            update-rc.d $DAEMON_NAME defaults
        elif command -v chkconfig >/dev/null 2>&1; then
            chkconfig --add $DAEMON_NAME
        fi

        echo "Service installed (init.d). You can now start it with: $INITD_SERVICE_FILE start"
    else
        echo "Error: init.d-script file not found in current directory"
        exit 1
    fi
}

# Install for systems without init system using watchdog script
install_watchdog() {
    if [ -f "./arm-mdns-watchdog.sh" ]; then
        # Create installation directory
#        WATCHDOG_DIR="/usr/local/lib/$DAEMON_NAME"
        mkdir -p $WATCHDOG_DIR

        # Copy watchdog script
        cp ./arm-mdns-watchdog.sh $WATCHDOG_DIR/
        chmod 755 $WATCHDOG_DIR/arm-mdns-watchdog.sh

        # Create a simple wrapper script in /usr/local/bin
#        WRAPPER_SCRIPT="/usr/local/bin/$DAEMON_NAME-control"
#        echo "#!/bin/sh" > $WRAPPER_SCRIPT
#        echo "# Wrapper for $DAEMON_NAME watchdog" >> $WRAPPER_SCRIPT
#        echo "$WATCHDOG_DIR/arm-mdns-watchdog.sh \$@" >> $WRAPPER_SCRIPT
#        chmod 755 $WRAPPER_SCRIPT

        echo "Service installed (watchdog). You can now start it with: $WATCHDOG_DIR/arm-mdns-watchdog.sh start $HOST_NAME"
        echo "To enable auto-restart, run: $WATCHDOG_DIR/arm-mdns-watchdog.sh monitor background $HOST_NAME"

        # Create a simple rc.local entry for autostart if /etc/rc.local exists
        if [ -f "/etc/rc.local" ]; then
            # Check if entry already exists
            if ! grep -q "$WATCHDOG_DIR/arm-mdns-watchdog.sh monitor background $HOST_NAME" /etc/rc.local; then
                # Add before exit 0 if it exists, otherwise append
                if grep -q "exit 0" /etc/rc.local; then
                    sed -i "s|exit 0|$WATCHDOG_DIR/arm-mdns-watchdog.sh monitor background $HOST_NAME\\nexit 0|" /etc/rc.local
                else
                    echo "$WATCHDOG_DIR/arm-mdns-watchdog.sh monitor background $HOST_NAME" >> /etc/rc.local
                fi
                echo "Added startup entry to /etc/rc.local"
            fi
        fi
    else
        echo "Error: arm-mdns-watchdog.sh file not found in current directory"
        exit 1
    fi
}

# Function to start the service
start() {
    echo "Starting ARM mDNS daemon..."
    case "$INIT_SYSTEM" in
        systemd)
            systemctl start $DAEMON_NAME
            systemctl status $DAEMON_NAME
            ;;
        initd)
            $INITD_SERVICE_FILE start
            $INITD_SERVICE_FILE status
            ;;
        *)
#            WATCHDOG_DIR="/usr/local/lib/$DAEMON_NAME"
#            WRAPPER_SCRIPT="/usr/local/bin/$DAEMON_NAME-control"

            if [ -f "$WRAPPER_SCRIPT" ]; then
                $WRAPPER_SCRIPT start $HOST_NAME
            elif [ -f "$WATCHDOG_DIR/arm-mdns-watchdog.sh" ]; then
                $WATCHDOG_DIR/arm-mdns-watchdog.sh start $HOST_NAME
            else
                echo "Watchdog script not found. Starting daemon directly..."
                $BINARY_PATH $HOST_NAME &
                echo "Started with PID: $!"
            fi
            ;;
    esac
}

# Function to stop the service
stop() {
    echo "Stopping ARM mDNS daemon..."
    case "$INIT_SYSTEM" in
        systemd)
            systemctl stop $DAEMON_NAME
            systemctl status $DAEMON_NAME
            ;;
        initd)
            $INITD_SERVICE_FILE stop
            $INITD_SERVICE_FILE status
            ;;
        *)
#            WATCHDOG_DIR="/usr/local/lib/$DAEMON_NAME"
#            WRAPPER_SCRIPT="/usr/local/bin/$DAEMON_NAME-control"

            if [ -f "$WRAPPER_SCRIPT" ]; then
                $WRAPPER_SCRIPT stop
            elif [ -f "$WATCHDOG_DIR/arm-mdns-watchdog.sh" ]; then
                $WATCHDOG_DIR/arm-mdns-watchdog.sh stop
            else
                echo "Watchdog script not found. Stopping daemon manually..."
                pkill -f "$BINARY_PATH"
                echo "Stopped"
            fi
            ;;
    esac
}

# Function to enable service at boot
enable() {
    echo "Enabling ARM mDNS daemon to start at boot..."
    case "$INIT_SYSTEM" in
        systemd)
            systemctl enable $DAEMON_NAME
            ;;
        initd)
            if command -v update-rc.d >/dev/null 2>&1; then
                update-rc.d $DAEMON_NAME defaults
            elif command -v chkconfig >/dev/null 2>&1; then
                chkconfig $DAEMON_NAME on
            else
                echo "Could not enable service: update-rc.d or chkconfig not found"
                exit 1
            fi
            ;;
        *)
#            WATCHDOG_DIR="/usr/local/lib/$DAEMON_NAME"
#            WRAPPER_SCRIPT="/usr/local/bin/$DAEMON_NAME-control"

            # Try to add to rc.local if it exists
            if [ -f "/etc/rc.local" ]; then
                # Check if entry already exists
                if ! grep -q "$WATCHDOG_DIR/arm-mdns-watchdog.sh monitor background $HOST_NAME" /etc/rc.local; then
                    # Add before exit 0 if it exists, otherwise append
                    if grep -q "exit 0" /etc/rc.local; then
                        sed -i "s|exit 0|$WATCHDOG_DIR/arm-mdns-watchdog.sh monitor background $HOST_NAME\\nexit 0|" /etc/rc.local
                    else
                        echo "$WATCHDOG_DIR/arm-mdns-watchdog.sh monitor background $HOST_NAME" >> /etc/rc.local
                    fi
                    chmod +x /etc/rc.local
                    echo "Added startup entry to /etc/rc.local"
                else
                    echo "Service already enabled in /etc/rc.local"
                fi
            # Try to add to crontab
            elif command -v crontab >/dev/null 2>&1; then
                (crontab -l 2>/dev/null; echo "@reboot $WATCHDOG_DIR/arm-mdns-watchdog.sh monitor background $HOST_NAME") | crontab -
                echo "Added startup entry to crontab"
            else
                echo "Could not enable service: neither /etc/rc.local nor crontab is available"
                echo "To start at boot, manually add this line to your startup scripts:"
                echo "$WATCHDOG_DIR/arm-mdns-watchdog.sh monitor background $HOST_NAME"
            fi
            ;;
    esac
}

# Function to disable service at boot
disable() {
    echo "Disabling ARM mDNS daemon from starting at boot..."
    case "$INIT_SYSTEM" in
        systemd)
            systemctl disable $DAEMON_NAME
            ;;
        initd)
            if command -v update-rc.d >/dev/null 2>&1; then
                update-rc.d -f $DAEMON_NAME remove
            elif command -v chkconfig >/dev/null 2>&1; then
                chkconfig $DAEMON_NAME off
            else
                echo "Could not disable service: update-rc.d or chkconfig not found"
                exit 1
            fi
            ;;
        *)
#            WATCHDOG_DIR="/usr/local/lib/$DAEMON_NAME"

            # Remove from rc.local if it exists
            if [ -f "/etc/rc.local" ]; then
                # Remove the line containing the watchdog script
                sed -i "\|$WATCHDOG_DIR/arm-mdns-watchdog.sh monitor background|d" /etc/rc.local
                echo "Removed startup entry from /etc/rc.local"
            fi

            # Remove from crontab if possible
            if command -v crontab >/dev/null 2>&1; then
                # Check if entry exists in crontab
                if crontab -l 2>/dev/null | grep -q "$WATCHDOG_DIR/arm-mdns-watchdog.sh"; then
                    (crontab -l 2>/dev/null | grep -v "$WATCHDOG_DIR/arm-mdns-watchdog.sh") | crontab -
                    echo "Removed startup entry from crontab"
                fi
            fi

            echo "Service disabled from starting at boot"
            ;;
    esac
}

# Function to uninstall the service
uninstall() {
    echo "Uninstalling ARM mDNS daemon..."

    # Stop and disable service based on init system
    case "$INIT_SYSTEM" in
        systemd)
            systemctl stop $DAEMON_NAME
            systemctl disable $DAEMON_NAME
            rm -f $SYSTEMD_SERVICE_FILE
            systemctl daemon-reload
            ;;
        initd)
            $INITD_SERVICE_FILE stop
            if command -v update-rc.d >/dev/null 2>&1; then
                update-rc.d -f $DAEMON_NAME remove
            elif command -v chkconfig >/dev/null 2>&1; then
                chkconfig --del $DAEMON_NAME
            fi
            rm -f $INITD_SERVICE_FILE
            rm -f $DEFAULT_CONFIG
            ;;
        *)
#            WATCHDOG_DIR="/usr/local/lib/$DAEMON_NAME"
#            WRAPPER_SCRIPT="/usr/local/bin/$DAEMON_NAME-control"

            # Stop the service using the watchdog script if available
            if [ -f "$WRAPPER_SCRIPT" ]; then
                $WRAPPER_SCRIPT stop
            elif [ -f "$WATCHDOG_DIR/arm-mdns-watchdog.sh" ]; then
                $WATCHDOG_DIR/arm-mdns-watchdog.sh stop
            else
                echo "Stopping daemon manually..."
                pkill -f "$BINARY_PATH"
            fi

            # Disable from startup
            # Remove from rc.local if it exists
            if [ -f "/etc/rc.local" ]; then
                sed -i "\|$WATCHDOG_DIR/arm-mdns-watchdog.sh monitor background|d" /etc/rc.local
            fi

            # Remove from crontab if possible
            if command -v crontab >/dev/null 2>&1; then
                if crontab -l 2>/dev/null | grep -q "$WATCHDOG_DIR/arm-mdns-watchdog.sh"; then
                    (crontab -l 2>/dev/null | grep -v "$WATCHDOG_DIR/arm-mdns-watchdog.sh") | crontab -
                fi
            fi

            # Remove watchdog script and wrapper
            rm -f "$WRAPPER_SCRIPT"
            rm -rf "$WATCHDOG_DIR"
            ;;
    esac

    # Remove binary
    rm -f $BINARY_PATH
    echo "Service uninstalled"
}

# Function to show status
status() {
    case "$INIT_SYSTEM" in
        systemd)
            systemctl status $DAEMON_NAME
            ;;
        initd)
            $INITD_SERVICE_FILE status
            ;;
        *)
#            WATCHDOG_DIR="/usr/local/lib/$DAEMON_NAME"
#            WRAPPER_SCRIPT="/usr/local/bin/$DAEMON_NAME-control"

            if [ -f "$WRAPPER_SCRIPT" ]; then
                $WRAPPER_SCRIPT status
            elif [ -f "$WATCHDOG_DIR/arm-mdns-watchdog.sh" ]; then
                $WATCHDOG_DIR/arm-mdns-watchdog.sh status
            else
                if pgrep -f "$BINARY_PATH" >/dev/null; then
                    echo "$DAEMON_NAME is running"
                    ps -ef | grep "$BINARY_PATH" | grep -v grep
                else
                    echo "$DAEMON_NAME is not running"
                fi
            fi

            # Check if watchdog monitor is running
            if [ -f "${WATCHDOG_DIR}/arm-mdns-watchdog.sh" ]; then
                if pgrep -f "$WATCHDOG_DIR/arm-mdns-watchdog.sh monitor" >/dev/null; then
                    echo "Watchdog monitor is active"
                else
                    echo "Watchdog monitor is not active"
                fi
            fi
            ;;
    esac
}

# Function to show usage
usage() {
    echo "Usage: $0 {install [hostname]|start|stop|enable|disable|uninstall|status}"
    echo "  install [hostname] - Install the service (optionally specify hostname, default: device)"
    echo "  start             - Start the service"
    echo "  stop              - Stop the service"
    echo "  enable            - Enable service to start at boot"
    echo "  disable           - Disable service from starting at boot"
    echo "  uninstall         - Uninstall the service"
    echo "  status            - Show service status"
    echo ""
    echo "Detected init system: $INIT_SYSTEM"
}

# Main script logic
case "$1" in
    install)
        install "$2"
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    enable)
        enable
        ;;
    disable)
        disable
        ;;
    uninstall)
        uninstall
        ;;
    status)
        status
        ;;
    *)
        usage
        exit 1
        ;;
esac

exit 0
