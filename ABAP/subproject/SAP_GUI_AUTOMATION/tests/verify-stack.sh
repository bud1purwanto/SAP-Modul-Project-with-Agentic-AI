#!/usr/bin/env bash
set -euo pipefail
DISPLAY_NUM="${SAP_GUI_DISPLAY:-99}"
DISPLAY=":${DISPLAY_NUM}"

DISPLAY="${DISPLAY}" xdpyinfo >/dev/null
pgrep -u "$(id -u)" -f "com.sap.platin.Gui" >/dev/null
ss -ltn | grep -q "127.0.0.1:5999"
DISPLAY="${DISPLAY}" XDG_SESSION_TYPE=x11 cua-driver doctor --json | grep -q '"ok": true'
printf 'PASS: display=%s, SAP GUI aktif, VNC view-only listener aktif, cua-driver sehat\n' "${DISPLAY}"
