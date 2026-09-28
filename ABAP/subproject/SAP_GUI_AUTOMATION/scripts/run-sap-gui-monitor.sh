#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="/data/Projects/SAP/ABAP/subproject/SAP_GUI_AUTOMATION"
START_SCRIPT="${ROOT_DIR}/scripts/start-sap-gui-monitor.sh"
STOP_SCRIPT="${ROOT_DIR}/scripts/stop-sap-gui-monitor.sh"
BASE_DIR="${HOME}/.local/opt/gui-display"
PID_DIR="${BASE_DIR}/pids"
DISPLAY_NUM="${SAP_GUI_DISPLAY:-99}"
DISPLAY=":${DISPLAY_NUM}"

shutdown() {
  trap - TERM INT EXIT
  /usr/bin/bash "${STOP_SCRIPT}" || true
}
trap shutdown TERM INT EXIT

/usr/bin/bash "${START_SCRIPT}"

components_ready() {
  DISPLAY="${DISPLAY}" xdpyinfo >/dev/null 2>&1 || return 1

  for name in xvfb openbox sap-gui cua-driver x11vnc-viewonly x11vnc-writable websockify-6080 websockify-6083; do
    pid_file="${PID_DIR}/${name}.pid"
    [[ -s "${pid_file}" ]] || return 1
    pid="$(cat "${pid_file}")"
    kill -0 "${pid}" 2>/dev/null || return 1
  done

  for port in 5998 5999 6080 6083; do
    ss -ltnH "sport = :${port}" | grep -q LISTEN || return 1
  done
}

# Child-process dibuat asynchronous; beri waktu maksimum 45 detik hingga
# seluruh display, PID, dan listener benar-benar siap sebelum health loop.
ready=0
for _ in $(seq 1 45); do
  if components_ready; then
    ready=1
    break
  fi
  sleep 1
done
[[ "${ready}" == "1" ]] || exit 20

# Tetap foreground agar systemd dapat mendeteksi kerusakan child-process.
# Satu kegagalan komponen kritis memicu restart atomik seluruh virtual stack.
while true; do
  components_ready || exit 21
  sleep 5
done
