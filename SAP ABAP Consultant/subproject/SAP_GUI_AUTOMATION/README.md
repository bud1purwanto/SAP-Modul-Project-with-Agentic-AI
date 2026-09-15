# SAP GUI Automation

PoC pengendalian SAP GUI for Java lewat display X11 khusus.

## Start

`scripts/start-sap-gui-monitor.sh`

Output memberi DISPLAY, socket cua-driver, dan endpoint VNC view-only.

## Control

Gunakan environment:

- `DISPLAY=:99`
- `XDG_SESSION_TYPE=x11`
- socket cua-driver: `~/.cache/cua-driver/cua-driver-sap.sock`

Urutan stabil:

1. `list_windows` untuk PID dan window_id terbaru.
2. `get_window_state` dan simpan screenshot.
3. Gunakan AT-SPI element bila tersedia; SAP GUI Java saat ini membutuhkan koordinat piksel.
4. Jalankan input background lebih dulu.
5. Jika verdict `background_unavailable`, eskalasi ke foreground. Display ini khusus agent.
6. Capture ulang. Verifikasi visual sebelum lanjut.

## Monitor

x11vnc hanya bind localhost, view-only, port 5999. Tidak diekspos publik.
