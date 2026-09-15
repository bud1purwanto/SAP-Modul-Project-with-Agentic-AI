# Checkpoint jaringan noVNC

2026-09-11

- User mengonfirmasi akses Tailscale 100.73.54.71:6080 berhasil.
- noVNC /home/abap/.local/opt/novnc-web; websockify venv /home/abap/.local/opt/novnc-venv; listen 0.0.0.0:6080 menuju 127.0.0.1:5999 (VNC view-only).
- Bukti kernel UFW BLOCK: eno1 SRC=192.168.88.92 DST=192.168.88.83 DPT=6080; WiFi wlx40ed00b87d6b SRC=192.168.88.1 DST=192.168.254.58 DPT=6080. Sumber WiFi tersebut menunjukkan jalur routed/kemungkinan NAT; konfigurasi NAT router belum diverifikasi.
- Rule UFW berhasil ditambahkan dan diverifikasi aktif: TCP 6080 pada WiFi dari 192.168.252.0/22; pada eno1 dari 192.168.88.0/24; pada WiFi dari 192.168.88.1.
- HTTP lokal menuju 192.168.254.58:6080/vnc.html mendapat 200 (0.003763s). Ini bukan bukti akses end-to-end laptop setelah perubahan firewall.
- Gateway WiFi terkonfigurasi 192.168.254.1 tidak merespons ping dan ARP INCOMPLETE saat probe. Default utama melalui eno1 192.168.88.1. Jalur balik routed WiFi masih mungkin asimetris; jangan ubah gateway tanpa verifikasi.
- URL WiFi: http://192.168.254.58:6080/vnc.html?autoconnect=1&port=6080
- Belum ada konfirmasi laptop untuk WiFi/LAN setelah rule diubah. Jangan klaim selesai end-to-end.

## 2026-09-11 — Persistensi reboot noVNC

- Root cause setelah reboot terverifikasi: script awal hanya menghidupkan Xvfb/SAP GUI/x11vnc pada 127.0.0.1:5999, tetapi tidak menjalankan websockify sehingga HTTP port 6080 menolak koneksi.
- `scripts/start-sap-gui-monitor.sh` diperluas untuk memulai dua x11vnc lokal dan dua proxy noVNC: 6080 ke 5999 (view-only) dan 6081 ke 5998 (writable, bind Tailscale).
- User service dibuat di `~/.config/systemd/user/sap-gui-monitor.service`; shortcut symlink tanpa spasi: `~/.local/share/sap-gui-automation`.
- Service enabled, `loginctl enable-linger abap` berhasil (`Linger=yes`) agar user service dijalankan setelah boot walau sesi grafis belum login.
- Uji restart service nyata lulus setelah memaksa environment X11 (`UnsetEnvironment=WAYLAND_DISPLAY` dan `XDG_SESSION_TYPE=x11`). Sebelumnya x11vnc mendeteksi Wayland dan exit; kondisi tersebut sudah diperbaiki.
- Bukti terakhir: service `active`, 6080 listen `0.0.0.0`, 6081 listen `100.73.54.71`, raw VNC 5999/5998 hanya localhost, HTTP ke `http://100.73.54.71:6080/vnc.html` mendapat `200 OK`, dan kedua upstream menjawab handshake `RFB 003.008`.
- URL monitor: `http://100.73.54.71:6080/vnc.html?autoconnect=1&reconnect=1&port=6080`.
- Akses browser laptop secara aktual tetap perlu konfirmasi dari Baginda; verifikasi server-side bukan bukti lintasan jaringan laptop/firewall sepenuhnya.
