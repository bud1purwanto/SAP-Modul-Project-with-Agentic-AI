# Checkpoint — SAP GUI noVNC publik: monitor dan override

Tanggal: 2026-09-15 WIB

## Endpoint publik

- Monitor view-only: `https://pc.abap.web.id/vnc.html`
- Override writable: `https://pcr.abap.web.id/vnc.html`

DNS kedua hostname diarahkan ke Cloudflare Tunnel `862b6d68-11e7-4468-b81a-3390defd19f0.cfargotunnel.com` melalui record CNAME proxied di zona `abap.web.id`.

## Arsitektur aktif

```text
pc.abap.web.id  -> Cloudflare Tunnel -> 127.0.0.1:6080 -> noVNC/websockify -> x11vnc :99 port 5999 (view-only)
pcr.abap.web.id -> Cloudflare Tunnel -> 127.0.0.1:6081 -> Nginx Basic Auth -> 127.0.0.1:6083 -> noVNC/websockify -> x11vnc :99 port 5998 (writable)
```

- Raw VNC port 5998/5999 hanya bind localhost.
- `pc` tidak meminta login dan tidak dapat dikendalikan, karena x11vnc memakai `-viewonly`.
- `pcr` meminta dialog Basic Auth browser sebelum noVNC terbuka.
- Kredensial `pcr`: username `abap`; password disimpan hanya sebagai hash Apache MD5 di `/home/abap/.local/opt/pcr-auth-proxy/.htpasswd` (mode 600), tidak di URL.
- Service persistensi gateway: `~/.config/systemd/user/pcr-auth-proxy.service`, status enabled dan active.
- Service stack SAP GUI/noVNC: `sap-gui-monitor.service`.

## Verifikasi end-to-end aktual

Dilakukan 2026-09-15:

- `https://pc.abap.web.id/vnc.html` -> HTTP 200.
- WebSocket `pc.abap.web.id/websockify` -> HTTP 101 Switching Protocols.
- `https://pcr.abap.web.id/vnc.html` tanpa kredensial -> HTTP 401 Unauthorized.
- `pcr` dengan username benar tetapi password salah -> HTTP 401 Unauthorized.
- `pcr` dengan kredensial benar -> HTTP 200; WebSocket -> HTTP 101 Switching Protocols.

Ini membuktikan halaman noVNC dan koneksi WebSocket melewati Cloudflare berfungsi; bukan sekadar halaman HTTP yang merespons.

## URL ringkas (wrapper domain)

`/home/abap/.local/opt/novnc-web/index.html` adalah wrapper root noVNC. Ia otomatis mengarahkan domain root ke `/vnc.html?autoconnect=1&reconnect=1` dan meneruskan query tambahan bila ada.

- Cukup buka `https://pc.abap.web.id` untuk monitor.
- Cukup buka `https://pcr.abap.web.id` untuk override. Browser meminta Basic Auth sebelum wrapper/noVNC dimuat.

Uji 2026-09-15: `pc` root memuat wrapper; `pcr` root tanpa login -> 401, dengan login benar memuat wrapper; kedua target `vnc.html` -> 200.

## Re-autentikasi setelah sesi lama

Basic Auth dapat ditolak pada WebSocket ketika halaman noVNC lama masih terbuka. Browser tidak selalu menampilkan dialog Basic Auth untuk penolakan WebSocket; gejalanya sebelumnya adalah `Failed to reconnect` sampai halaman di-refresh.

`app/ui.js` noVNC diperbarui untuk hostname `pcr.abap.web.id`: pada disconnect tidak bersih, halaman otomatis sekali kembali ke root gateway yang dilindungi (`/?reauth=<timestamp>`). Root ini menghasilkan challenge Basic Auth browser sehingga popup muncul tanpa refresh manual. Batas 30 detik pada `sessionStorage` mencegah refresh-loop bila origin sedang benar-benar mati. `pc` tidak berubah dan tetap memakai auto-reconnect biasa.

Verifikasi 2026-09-15: patch JavaScript terlihat melalui HTTPS pada `pc` dan `pcr`; `pcr` dengan kredensial valid tetap HTTP 200.

## Operasional

Baginda dan teman kantor dapat membuka `pc` untuk melihat. Akses `pcr` hanya untuk operator yang diberi username/password. SAP login tetap lapisan terpisah setelah noVNC tersambung.
