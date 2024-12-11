#!/bin/sh
EXTENSION_DIR='/mnt/us/extensions/kindle-mdns'
BIN='kindle-mdns'
HOST_NAME='kindle'

# clearing
start() {
  output=
  /usr/sbin/eips 0 32 '                                                               '
  /usr/sbin/eips 0 32 'Starting mDNS...'

  [ -x ${EXTENSION_DIR}/bin/${BIN} ] || chmod +x ${EXTENSION_DIR}/bin/${BIN}
  output=$(/sbin/start-stop-daemon -v -m -p ${EXTENSION_DIR}/pid -x ${EXTENSION_DIR}/bin/${BIN} -b -c root -S -- ${HOST_NAME})

  if [ $? -ne 0 ]; then
    /usr/sbin/eips 0 32 '                                                               '
    /usr/sbin/eips 0 32 "Failed to start: $output"
  else
    /usr/sbin/eips 0 32 '                                                               '
    /usr/sbin/eips 0 32 "Started with pid: $(cat ${EXTENSION_DIR}/pid)"
  fi
}

stop() {
  output=
  /usr/sbin/eips 0 32 '                                                               '
  /usr/sbin/eips 0 32 'Stopping mDNS...'

  [ -x ${EXTENSION_DIR}/bin/${BIN} ] || chmod +x ${EXTENSION_DIR}/bin/${BIN}
  output=$(/sbin/start-stop-daemon -v -m -p ${EXTENSION_DIR}/pid -x ${EXTENSION_DIR}/bin/${BIN} -b -K)

  if [ $? -ne 0 ]; then
    /usr/sbin/eips 0 32 '                                                               '
    /usr/sbin/eips 0 32 "Failed to stop: $output"
  else
    /usr/sbin/eips 0 32 '                                                               '
    /usr/sbin/eips 0 32 "Stopped: pid $(cat ${EXTENSION_DIR}/pid)"
    rm ${EXTENSION_DIR}/pid
  fi
}

if [ "$1" = "start" ]; then
  start
elif [ "$1" = "stop" ]; then
  stop
else
  /usr/sbin/eips 0 32 '                                                               '
  /usr/sbin/eips 0 32 "Unknown command: $1"
fi
