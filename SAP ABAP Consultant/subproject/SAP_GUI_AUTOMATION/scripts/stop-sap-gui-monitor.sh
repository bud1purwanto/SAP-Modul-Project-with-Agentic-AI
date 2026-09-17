#!/usr/bin/env bash
set -euo pipefail
BASE_DIR="${HOME}/.local/opt/gui-display"
PID_DIR="${BASE_DIR}/pids"
for name in nginx-pcr-auth websockify-6083 websockify-6081 websockify-6080 x11vnc-writable x11vnc-viewonly x11vnc cua-driver sap-gui openbox xvfb; do
  pid_file="${PID_DIR}/${name}.pid"
  if [[ -f "${pid_file}" ]]; then
    pid="$(cat "${pid_file}")"
    kill "${pid}" 2>/dev/null || true
    if [[ "${name}" == "nginx-pcr-auth" ]]; then
       /usr/sbin/nginx -s quit -p /home/abap/.local/opt/pcr-auth-proxy -c /home/abap/.local/opt/pcr-auth-proxy/nginx.conf 2>/dev/null || true
       pkill -f "nginx.*pcr-auth-proxy" || true
    fi
    rm -f "${pid_file}"
  fi
done
