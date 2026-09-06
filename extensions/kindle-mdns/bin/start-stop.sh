#!/bin/sh
EXTENSION_DIR='/mnt/us/extensions/kindle-mdns'
BIN='kindle-mdns'
CONFIG_FILE="${EXTENSION_DIR}/kindle-mdns.conf"
MENU_FILE="${EXTENSION_DIR}/menu.json"
IPTABLES='/usr/sbin/iptables'
MDNS_CHAIN='KINDLE_MDNS'
MDNS_INTERFACE='wlan0'

HOST_NAME='kindle'
SERVICE_TYPE='_kindle-service._tcp'
INSTANCE_NAME='Kindle Service'
PORT='0'

if [ -r "${CONFIG_FILE}" ]; then
  . "${CONFIG_FILE}"
fi

refresh_menu() {
  case "${HOST_NAME}" in
    ''|*[!A-Za-z0-9-]*|-*|*-)
      return 1
      ;;
  esac

  [ "${#HOST_NAME}" -le 63 ] || return 1
  [ -r "${MENU_FILE}" ] || return 1
  grep -q '"name": "Kindle mDNS (name: [^"]*)"' "${MENU_FILE}" || return 1

  menu_tmp="${MENU_FILE}.tmp.$$"
  if ! sed "s/\"name\": \"Kindle mDNS (name: [^\"]*)\"/\"name\": \"Kindle mDNS (name: ${HOST_NAME}.local)\"/" \
    "${MENU_FILE}" > "${menu_tmp}"; then
    rm -f "${menu_tmp}"
    return 1
  fi

  if ! mv "${menu_tmp}" "${MENU_FILE}"; then
    rm -f "${menu_tmp}"
    return 1
  fi
}

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

  if ! refresh_menu; then
    /usr/sbin/eips 0 32 '                                                               '
    /usr/sbin/eips 0 32 'Warning: mDNS menu name not refreshed'
  fi

  if ! open_mdns_firewall; then
    /usr/sbin/eips 0 32 '                                                               '
    /usr/sbin/eips 0 32 'Warning: mDNS firewall not configured'
  fi

  [ -x ${EXTENSION_DIR}/bin/${BIN} ] || chmod +x ${EXTENSION_DIR}/bin/${BIN}
  output=$(/sbin/start-stop-daemon -v -m -p ${EXTENSION_DIR}/pid -x ${EXTENSION_DIR}/bin/${BIN} -b -c root -S -- \
    -s "${SERVICE_TYPE}" -i "${INSTANCE_NAME}" -p "${PORT}" "${HOST_NAME}")

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
