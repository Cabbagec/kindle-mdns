#!/bin/sh
EXTENSION_DIR='/mnt/us/extensions/kindle-mdns'
BIN='kindle-mdns'
HOST_NAME='kindle'
IPTABLES='/usr/sbin/iptables'
MDNS_CHAIN='KINDLE_MDNS'
MDNS_INTERFACE='wlan0'

open_mdns_firewall() {
  [ -x "${IPTABLES}" ] || return 1

  # Use a private chain so startup is idempotent and shutdown only removes
  # firewall rules owned by this extension.
  "${IPTABLES}" -N "${MDNS_CHAIN}" 2>/dev/null || true
  "${IPTABLES}" -F "${MDNS_CHAIN}" || return 1
  "${IPTABLES}" -A "${MDNS_CHAIN}" -i "${MDNS_INTERFACE}" \
    -d 224.0.0.251 -p udp --dport 5353 -j ACCEPT || return 1

  while "${IPTABLES}" -D INPUT -j "${MDNS_CHAIN}" 2>/dev/null; do :; done
  "${IPTABLES}" -I INPUT 1 -j "${MDNS_CHAIN}"
}

close_mdns_firewall() {
  [ -x "${IPTABLES}" ] || return 0

  while "${IPTABLES}" -D INPUT -j "${MDNS_CHAIN}" 2>/dev/null; do :; done
  "${IPTABLES}" -F "${MDNS_CHAIN}" 2>/dev/null || true
  "${IPTABLES}" -X "${MDNS_CHAIN}" 2>/dev/null || true
}

# clearing
start() {
  output=
  /usr/sbin/eips 0 32 '                                                               '
  /usr/sbin/eips 0 32 'Starting mDNS...'

  if ! open_mdns_firewall; then
    /usr/sbin/eips 0 32 '                                                               '
    /usr/sbin/eips 0 32 'Warning: mDNS firewall not configured'
  fi

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

  close_mdns_firewall
}

if [ "$1" = "start" ]; then
  start
elif [ "$1" = "stop" ]; then
  stop
else
  /usr/sbin/eips 0 32 '                                                               '
  /usr/sbin/eips 0 32 "Unknown command: $1"
fi
