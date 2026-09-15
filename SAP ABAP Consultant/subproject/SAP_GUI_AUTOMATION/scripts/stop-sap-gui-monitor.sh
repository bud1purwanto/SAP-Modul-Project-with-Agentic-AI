#!/usr/bin/env bash
set -euo pipefail
BASE_DIR="${HOME}/.local/opt/gui-display"
PID_DIR="${BASE_DIR}/pids"
for name in websockify-6081 websockify-6080 x11vnc-writable x11vnc-viewonly x11vnc cua-driver sap-gui openbox xvfb; do
  pid_file="${PID_DIR}/${name}.pid"
  if [[ -f "${pid_file}" ]]; then
    pid="$(cat "${pid_file}")"
    kill "${pid}" 2>/dev/null || true
    rm -f "${pid_file}"
  fi
done
