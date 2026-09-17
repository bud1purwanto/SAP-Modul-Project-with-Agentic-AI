# SUBPROJECTS — Peta Sub-Project SAP FICO Consultant

Baca file ini **pertama kali** setiap mulai kerja di project "SAP FICO Consultant".
Fungsinya: menentukan sub-project mana yang relevan dengan permintaan user, lalu bekerja
hanya di dalam folder sub-project tersebut.

Semua sub-project berada di dalam folder induk `subproject/`.

```
SAP FICO Consultant/
├── AGENTS.md               <- Konteks otomatis agent saat New Chat & routing langsung
├── CLAUDE.md               <- Aturan kerja & environment SAP FICO
├── SUBPROJECTS.md          <- File ini (peta routing sub-project)
├── subproject/
│   ├── UPLOAD_FAKTUR/      <- Program ZFIC_UPLOAD_FAKTUR, ZFI106, BKPF-AEDAT
│   ├── GL_ACCOUNTING/      <- Chart of Accounts, Journal FB50, FAGL_FCV, OB58
│   ├── AP_PAYMENT/         <- Vendor master, MIRO, F110 APP, clearing F-44
│   ├── AR_CREDIT/          <- Customer invoice FB70, incoming F-28, dunning F150, FD32
│   ├── ASSET_ACCOUNTING/   <- Asset master AS01, depreciation AFAB, AuC AIAB/AIBU
│   └── COST_CONTROLLING/   <- Cost Center KS01, Order KO01/KO88, CK11N, CO-PA
├── _SHARED/                <- Helper / script / config generik lintas sub-project
```

## Struktur Umum Tiap Sub-Project

Setiap sub-project memakai subfolder standar:

- `src/` — program / source code penunjang (ABAP include/sample) / formula validasi
- `scripts/` — script otomasi query / test RFC
- `docs/` — dokumen analisis teknis, FS/TS, SOP accounting, mapping akun OBYC/VKOA (`.md`, `.docx`, `.xlsx`)
- `tests/` — skenario uji posting / data dummy jurnal
- `outputs/` — hasil dump tabel `BKPF`/`BSEG`, snapshot balance, log posting

## Peta Sub-Project

| Sub-Project (folder) | Topik / Objek Utama | Cakupan | Kata Kunci untuk Routing |
|---|---|---|---|
| `subproject/UPLOAD_FAKTUR/` | `ZFIC_UPLOAD_FAKTUR` (ZFI106) | Upload faktur pajak, update `BKPF-XBLNR` & `BKPF-AEDAT`, change document FM `CHANGE_DOCUMENT` | upload faktur, zfic_upload_faktur, zfi106, aedat, xblnr, faktur pajak, bapi_transaction_commit |
| `subproject/GL_ACCOUNTING/` | General Ledger (FI-GL) | Chart of Accounts, G/L master (`FS00`), journal entry (`FB50`/`F-02`), foreign currency valuation (`FAGL_FCV`), Financial Statement Version (`OB58`) | gl accounting, fs00, fb50, f-02, fagl_fcv, ob58, journal, general ledger, balance sheet, p&l |
| `subproject/AP_PAYMENT/` | Accounts Payable (FI-AP) | Vendor master (`FK01`/`XK01`), invoice verification (`FB60`/`MIRO`), Automatic Payment Program / APP (`F110`), down payment (`F-48`), clearing (`F-44`) | ap, accounts payable, f110, app, fb60, f-44, vendor clearing, payment run, down payment |
| `subproject/AR_CREDIT/` | Accounts Receivable (FI-AR) | Customer master (`FD01`/`XD01`), invoice (`FB70`), incoming payment (`F-28`), dunning (`F150`), credit management (`FD32`) | ar, accounts receivable, fb70, f-28, f150, dunning, fd32, credit limit, customer invoice |
| `subproject/ASSET_ACCOUNTING/` | Asset Accounting (FI-AA) | Master asset (`AS01`), perolehan asset (`F-90`), depreciation run (`AFAB`), retirement (`ABAON`), settlement AuC (`AIAB`/`AIBU`) | asset accounting, as01, afab, f-90, abaon, aiab, aibu, asset depreciation, auc |
| `subproject/COST_CONTROLLING/` | Controlling (CO-OM, CO-PC, CO-PA) | Cost center (`KS01`), internal order (`KO01`/`KO88`), standard cost estimate (`CK11N`/`CK24`), variance (`KKS2`), CO-PA valuation | co, controlling, cost center, ks01, ko01, ko88, ck11n, ck24, kks2, co-pa, product costing |

## Folder Non-Sub-Project

- `_SHARED/` — helper generik lintas sub-project: template dokumentasi, konfigurasi bersama, legacy rules backup.

## Aturan Kerja Dengan Sub-Project

1. Baca permintaan user, cocokkan ke kolom **kata kunci** di tabel untuk memilih sub-project.
2. Jika ambigu antara dua sub-project, tanyakan ke user sebelum lanjut.
3. Baca konteks dari `docs/` sub-project itu dulu (analisis `.md`, FS/TS) sebelum memberikan rekomendasi atau perubahan.
4. Simpan seluruh artefak kerja di subfolder yang sesuai (`src/`, `scripts/`, `docs/`, `outputs/`) di dalam subproject terkait — **dilarang menaruh file baru di root atau di `subproject/` langsung**.
5. Wajib membuat dan memelihara file pelacak `.md` (seperti `CHECKPOINT.md` atau `README.md`) di dalam folder sub-project terkait untuk mencatat status transaksi, akun terkait, dan hasil verifikasi.

## AUTO-MAPPING — Menambah Sub-Project Baru (WAJIB)

Ketika muncul kasus/program baru yang **tidak cocok** dengan sub-project mana pun di tabel:

1. Buat folder baru di dalam `subproject/` dengan nama singkat huruf besar, mis. `subproject/NAMA_BARU/`.
2. Buat subfolder standar di dalamnya: `src/ scripts/ docs/ tests/ outputs/`.
3. Buat file `CHECKPOINT.md` di root folder subproject baru tersebut yang memuat identitas, status, latar belakang akuntansi/controlling, dan daftar dokumen/task.
4. **Tambahkan satu baris ke tabel "Peta Sub-Project" di atas**: folder, topik utama, cakupan, dan kata kunci routing.
5. Taruh semua file terkait ke subfolder yang sesuai berdasarkan jenisnya.

Ringkas: **setiap sub-project baru = 1 folder di `subproject/` + subfolder standar + `CHECKPOINT.md` + 1 baris di tabel peta ini.**

