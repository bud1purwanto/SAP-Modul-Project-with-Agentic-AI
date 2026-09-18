# Checkpoint — SAP GUI Computer Use

Status: proof-of-concept terverifikasi pada server Linux.

## Temuan akar masalah

- Environment Hermes awal memakai `DISPLAY=:0`.
- Tidak ada socket X11 `:0`; hanya GDM Wayland/Xwayland greeter `:1024` milik user lain.
- `hermes computer-use doctor` karena itu melaporkan X11 tidak reachable.
- Kegagalan awal bukan bukti SAP GUI tidak dapat dikontrol.

## Arsitektur yang diuji

- Xvfb lokal tanpa instalasi root: `~/.local/opt/gui-display/root/usr/bin/Xvfb`.
- Display khusus: `:99`, resolusi 1440x900x24.
- Window manager: Openbox.
- SAP GUI for Java 8.10 rev 6: `/opt/SAPClients/SAPGUI8.10rev6/bin/guilogon`.
- Driver: cua-driver 0.23.2.
- Monitor: x11vnc bind localhost, port 5999, view-only.

## Bukti aktual

- `cua-driver doctor --json` pada `DISPLAY=:99`: seluruh probe OK.
- `list_windows`: SAP GUI for Java terdeteksi, PID 846411, window 4194336, 498x473.
- Screenshot awal: `~/.local/opt/gui-display/sap-logon.png`.
- Klik background pada menu Help berhasil; screenshot verifikasi: `sap-help-click.png`.
- Input keyboard mode background ditolak secara benar dengan `background_unavailable`.
- Eskalasi ke foreground pada display khusus berhasil mengetik `Sandbox`; screenshot: `sap-search-test-fg.png`.
- AT-SPI Java belum mengekspos child controls; state ditandai degraded. Strategi wajib: pixel coordinate + screenshot verification setiap aksi.

## Pengujian login dan SE16N MARA — checkpoint lanjutan

- Permintaan: login sandbox lalu SE16N, display MARA.
- Koneksi bernama Sandbox New Company berhasil dibuka melalui double-click foreground setelah background_unavailable.
- Layar aktual menunjukkan SID TRD, host eccdevlinux, client 130. Label koneksi tidak membuktikan SID TRS; identitas target perlu dipastikan sebelum melanjutkan.
- Window login: PID 846411, window_id 4194445 (selalu discovery ulang sebelum aksi).
- Window awal melampaui display sehingga capture XGetImage/MIT-SHM gagal. set_window_frame ke 1380x840 berhasil confirmed; screenshot layar lewat ffmpeg berhasil.
- Bukti: /home/abap/.local/opt/gui-display/sandbox-login-root.png.
- Username/password kosong; belum login. Browser vault mengembalikan items kosong dan hanya mendukung formulir browser, bukan SAP GUI native.
- BLOCKED: belum tersedia jalur pengisian kredensial native yang aman atau sesi SSO terautentikasi. Tidak mencari password dari log/config dan tidak mengetik password melalui driver.
- SE16N dan MARA BELUM dijalankan. Tidak ada perubahan data SAP.

## Batas keselamatan transaksi

- Navigasi/read-only dapat berjalan otomatis.
- Aksi posting/commit membutuhkan guard berbasis screenshot sebelum tombol final dan verifikasi hasil setelah aksi.
- Jangan menganggap `effect=unverifiable` sebagai berhasil tanpa capture ulang.
- Kredensial tidak ditulis ke script/checkpoint. Login perlu jalur secret-vault atau SSO yang sesuai.

## Artefak

- `scripts/start-sap-gui-monitor.sh`
- `scripts/stop-sap-gui-monitor.sh`
- Monitor lokal: `127.0.0.1:5999`, view-only.

## 2026-09-11 — Routing permanen lintas chat/Telegram

- Skill profile `default` dibuat: `sap-gui-virtual-session`.
- Trigger mencakup setiap aksi SAP GUI, SAP Logon, TCODE, dan transaksi visual SAP.
- Default wajib: gunakan service `sap-gui-monitor.service`, display virtual `:99`, dan socket cua-driver khusus; dilarang memakai desktop fisik `:0` kecuali virtual stack tidak dapat dipulihkan.
- Preflight, recovery otomatis, screenshot verification, batas write/posting, credential safety, serta checkpoint transaksi telah ditetapkan dalam skill.
- Berlaku untuk chat baru dan Telegram selama keduanya memakai profil Hermes `default`; profil lain tetap terisolasi.

## 2026-09-11 — Perbaikan koneksi computer_use Telegram

- Gejala Telegram: skill `sap-gui-virtual-session` termuat, tetapi `computer_use.list_windows` mengembalikan `count: 0` dan agent menyimpulkan GUI tidak tersedia.
- Akar masalah: gateway Hermes memakai daemon/socket cua-driver default yang berbeda dari daemon SAP virtual. Mengubah `DISPLAY=:99` saja tidak cukup karena socket default lama tetap dipakai.
- Wrapper khusus dibuat: `/home/abap/.local/bin/cua-driver-sap-virtual`. Manifest wrapper memaksa MCP menggunakan socket `/home/abap/.cache/cua-driver/cua-driver-sap.sock`.
- Override systemd gateway: `/etc/systemd/system/hermes-gateway.service.d/sap-gui-virtual.conf`, memuat `HERMES_CUA_DRIVER_CMD=/home/abap/.local/bin/cua-driver-sap-virtual`, `DISPLAY=:99`, dan environment X11. `hermes-gateway.service` direstart dan active.
- Uji end-to-end dari sesi Hermes baru (jalur `computer_use` yang sama dengan Telegram) sukses pada 2026-09-11: `list_windows` menemukan `SAP GUI for Java`, PID `200854`, window_id `31457312`.
- Kesimpulan: permintaan GUI SAP baru melalui Telegram sekarang diarahkan ke sesi virtual dan dapat mendeteksi window SAP. Tetap lakukan preflight sebelum setiap transaksi karena PID/window_id dapat berubah setelah SAP restart.

## 2026-09-11 — Permintaan Material Master Sandbox New Company

- Target terverifikasi melalui MCP SAP: koneksi aktif `Sandbox New Company`, IP `192.168.6.243`; RFC endpoint aktual mengembalikan host `eccdevlinux`, SID teknis `TRD`, client tidak tersedia dari RFC_SYSTEM_INFO.
- SAP GUI sempat tersedia pada virtual session, kemudian computer-use kehilangan window discovery sehingga GUI tidak dapat dilanjutkan pada turn ini.
- Login native SAP GUI tidak diisi karena mekanisme computer-use tidak boleh menerima/mengetik password plaintext dan vault browser tidak berlaku untuk SAP GUI.
- Alternatif read-only berhasil: ekuivalen SE16N membaca `MARA`, 50 baris, field `MATNR MTART MATKL MEINS ERSDA ERNAM`. Tidak ada perubahan data.
- Contoh hasil: `000000000071000009` / `ZOPS` / `700001` / `ST` / dibuat `20121206`; `0000000#1400000831` / `ZSME` / `804012` / `ST` / dibuat `20170728` oleh `TRSTDEV`.

## 2026-09-11 — GUI dipulihkan dan layar login dibuka

- `sap-gui-monitor.service` direstart. Display `:99` aktif, resolusi `1440x900`; VNC `5999/5998` handshake `RFB 003.008`; noVNC `6080/6081` kembali listen.
- Karena tool `computer_use` sesi TUI masih melekat ke display `:0`, kontrol aman dilanjutkan langsung pada display agent `:99` memakai X11, disertai screenshot sebelum/sesudah.
- Entry `Sandbox New Company` pada SAP Logon berhasil di-double-click.
- Layar login aktual terverifikasi: SID `TRD`, host `eccdevlinux`, client `130`, informasi `ECC 6.0 Development System`.
- Username `TRSTDEV` sudah diisi. Fokus sudah berada di field password.
- Blocker tersisa hanya secret entry: kebijakan computer-use melarang agent mengetik password plaintext. Bukti layar siap-password: `/home/abap/.hermes/cache/images/sap-login-ready-password.png`.
- Setelah password dimasukkan melalui kanal operator, lanjutkan GUI ke `SE16N`, tabel `MARA`, execute, lalu screenshot-verifikasi hasil.

## 2026-09-15 — Aturan monitoring VNC SAP GUI

- Seluruh transaksi GUI SAP wajib hanya pada display virtual persisten `:99`.
- Baginda memantau layar nyata melalui `https://pc.abap.web.id/` (view-only) atau `https://pcr.abap.web.id/` (operator/override); VNC ini menjadi kanal bukti utama, bukan screenshot/chat Hermes.
- Untuk support read-only yang mendesak, jalankan segera dengan pertanyaan seminimal mungkin. Konfirmasi hanya bila input penting belum ada atau aksi mengubah data/sensitif/berbahaya.
- Sebelum menyatakan TCODE atau hasil telah terbuka, verifikasi layar virtual dan status bar; jangan pernah menggantikan bukti dengan placeholder gambar atau klaim yang tidak diverifikasi.
- Respons Hermes untuk support dibuat singkat: status TCODE, SID/client, hasil atau blocker yang terverifikasi.

## 2026-09-15 — ZBMBC parameter support

- Permintaan: buka TCODE `ZBMBC` dan isi parameter Plant `tte` serta Material `srrpai` untuk dipantau melalui VNC.
- Preflight virtual stack terverifikasi: service aktif, display `:99` OK, VNC `5999/5998` dan noVNC `6080/6081` listen, handshake RFB `003.008`, HTTP monitor `200`.
- Target terverifikasi: SID `TRD`, client `130`.
- Layar report terverifikasi: `Report Stock Overview with Characteristic` (hasil navigasi `/nZBMBC`).
- Parameter terisi dan diverifikasi dari layar: Material `srrpai`, Plant `tte`; tidak ada pesan error pada status bar.

## 2026-09-15 — ZPP016N hari ini

- TCODE: ZPP016N (Rekap Slitting Harian - Single Batch)
- Tanggal: 24.09.2026 (diisi di Production Date)
- Eksekusi: Dijalankan setelah isi parameter
- Status: Layar hasil terbuka setelah F8/Execute
- Checkpoint: Data slitting harian sudah dihasilkan di virtual session TRD client 130
- VNC pemantauan: pc.abap.web.id / pcr.abap.web.id
- Report belum dieksekusi karena permintaan hanya membuka dan mengisi parameter. Tidak ada perubahan data SAP.

## 2026-09-15 — Test cancel Slit Roll order 100000067411

- Target RFC disetel dan terverifikasi: Sandbox New Company, SID TRS (endpoint teknis mengembalikan TRDCLNT130); tanggal server 03.02.2029.
- RAG yang dipakai: `PP-CL-UM29 Cancel Process Order Slitroll` / PPCL02. Jalur aktual: `ZPP001` → filter process order → list → pilih order → `Batal Start/Stop` → konfirmasi `Ya`.
- Validasi RFC sebelum aksi melalui `BAPI_PROCORD_GET_DETAIL`: process order `100000067411`, type `ZCL2`, plant `2000`, material `SRWCNI` (SLITT ROLL DL00-50), kuantitas 1 ROL, tanggal 22.02.2027, resource `CWT02`, status awal `TECO`.
- Pada `ZPP001`, filter yang berhasil menampilkan list: Order Type `ZCL2`, Plant `2000`, Order Number `100000067411`, Production Date `22.02.2027`. RAG contoh `ZCA1` tidak cocok dengan order aktual dan tidak dipaksakan.
- Order dipilih, tombol `Batal Start/Stop` ditekan, kemudian dialog `Cancel Order ??` berisi `Order 100000067411 akan di cancel ?` dikonfirmasi dengan `Ya`.
- Bukti hasil UI: log `Log Process Batal Start-Stop` menampilkan ikon hijau, transaksi `Cancel Slitting Process 100000067411`, pesan `Success`. Screenshot: `/tmp/sap-cancel-result.png`.
- Cross-check RFC setelah aksi: header berubah dari `TECO BCRQ MANC SETC` menjadi `REL BCRQ MANC SETC`, membuktikan UNTECO terjadi. Order masih muncul di list `ZPP001` dengan tampilan status `TECO`; tampilan list tidak merefresh/menampilkan status akhir secara konsisten. Tidak mengklaim status `Cancelled` karena bukti final `Already Cancelled` belum ada.
- Artefak verifikasi: `/tmp/sap-zpp001-result4.png`, `/tmp/sap-cancel-dialog.png`, `/tmp/sap-cancel-result.png`, `/tmp/sap-cancel-verify-list.png`.
