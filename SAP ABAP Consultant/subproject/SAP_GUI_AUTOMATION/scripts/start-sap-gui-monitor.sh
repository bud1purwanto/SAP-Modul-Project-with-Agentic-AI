#!/usr/bin/env bash
set -euo pipefail

DISPLAY_NUM="${SAP_GUI_DISPLAY:-99}"
DISPLAY=":${DISPLAY_NUM}"
BASE_DIR="${HOME}/.local/opt/gui-display"
XVFB="${BASE_DIR}/root/usr/bin/Xvfb"
SAP_GUI="/opt/SAPClients/SAPGUI8.10rev6/bin/guilogon"
CUA_SOCKET="${HOME}/.cache/cua-driver/cua-driver-sap.sock"
VNC_PORT="${SAP_GUI_VNC_PORT:-5999}"
LOG_DIR="${BASE_DIR}/logs"
PID_DIR="${BASE_DIR}/pids"

mkdir -p "${LOG_DIR}" "${PID_DIR}" "$(dirname "${CUA_SOCKET}")"

start_if_missing() {
  local name="$1"
  local match="$2"
  shift 2
  if ! pgrep -u "$(id -u)" -f "${match}" >/dev/null; then
    "$@" >>"${LOG_DIR}/${name}.log" 2>&1 &
    echo $! >"${PID_DIR}/${name}.pid"
  fi
}

start_if_missing xvfb "Xvfb ${DISPLAY}" \
  "${XVFB}" "${DISPLAY}" -screen 0 1440x900x24 -nolisten tcp

for _ in $(seq 1 30); do
  DISPLAY="${DISPLAY}" xdpyinfo >/dev/null 2>&1 && break
  sleep 0.2
done
DISPLAY="${DISPLAY}" xdpyinfo >/dev/null

start_if_missing openbox "openbox --replace" \
  env DISPLAY="${DISPLAY}" XDG_SESSION_TYPE=x11 dbus-run-session -- openbox --replace

start_if_missing sap-gui "com.sap.platin.Gui" \
  env DISPLAY="${DISPLAY}" XDG_SESSION_TYPE=x11 \
      XDG_RUNTIME_DIR="/run/user/$(id -u)" \
      DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus" \
      "${SAP_GUI}"

start_if_missing cua-driver "cua-driver serve --socket ${CUA_SOCKET}" \
  env DISPLAY="${DISPLAY}" XDG_SESSION_TYPE=x11 \
      DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus" \
      cua-driver serve --socket "${CUA_SOCKET}"

start_if_missing x11vnc-viewonly "x11vnc -display ${DISPLAY}.*-rfbport ${VNC_PORT}" \
  env -u WAYLAND_DISPLAY DISPLAY="${DISPLAY}" XDG_SESSION_TYPE=x11 \
      x11vnc -display "${DISPLAY}" -localhost -rfbport "${VNC_PORT}" \
      -viewonly -forever -shared -nopw

start_if_missing x11vnc-writable "x11vnc -display ${DISPLAY}.*-rfbport 5998" \
  env -u WAYLAND_DISPLAY DISPLAY="${DISPLAY}" XDG_SESSION_TYPE=x11 \
      x11vnc -display "${DISPLAY}" -localhost -rfbport 5998 \
      -forever -shared -nopw

NOVNC_WEB="${HOME}/.local/opt/novnc-web"
WEBSOCKIFY="${HOME}/.local/opt/novnc-venv/bin/websockify"
start_if_missing websockify-6080 "websockify.*6080" \
  "${WEBSOCKIFY}" --web "${NOVNC_WEB}" 0.0.0.0:6080 127.0.0.1:5999

start_if_missing websockify-6081 "websockify.*6081" \
  "${WEBSOCKIFY}" --web "${NOVNC_WEB}" 100.73.54.71:6081 127.0.0.1:5998

printf 'DISPLAY=%s\nCUA_SOCKET=%s\nVNC=127.0.0.1:%s (view-only)\n' \
  "${DISPLAY}" "${CUA_SOCKET}" "${VNC_PORT}"
