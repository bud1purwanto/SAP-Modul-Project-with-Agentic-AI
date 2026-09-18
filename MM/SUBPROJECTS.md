# SUBPROJECTS — Peta Sub-Project SAP MM Consultant

Baca file ini **pertama kali** setiap mulai kerja di project "SAP MM Consultant".
Fungsinya: menentukan sub-project mana yang relevan dengan permintaan user, lalu bekerja
hanya di dalam folder sub-project tersebut.

Semua sub-project berada di dalam folder induk `subproject/`.

```
SAP MM Consultant/
├── AGENTS.md                   <- Konteks otomatis agent saat New Chat & routing langsung
├── CLAUDE.md                   <- Aturan kerja & environment SAP MM
├── SUBPROJECTS.md              <- File ini (peta routing sub-project)
├── subproject/
│   ├── AUTOMATION_BACKLOG/     <- Backlog inisiatif otomasi proses MM
│   ├── PURCHASING_PROCUREMENT/ <- PR, PO, Outline Agreement, Release Strategy
│   ├── INVENTORY_MANAGEMENT/   <- MIGO (101/261/311), Stock Overview MB52, Reservasi
│   ├── INVOICE_VERIFICATION/   <- MIRO, MIRA, MRBR, ERS MRRL
│   └── ACCOUNT_DETERMINATION/  <- OBYC, Valuation Class, Price Diff, GR/IR Clearing
├── _SHARED/                    <- Helper / script / config generik lintas sub-project
```

## Struktur Umum Tiap Sub-Project

Setiap sub-project memakai subfolder standar:

- `src/` — file konfigurasi / query / BAPI mapping sample
- `scripts/` — script otomasi data / extraction / audit
- `docs/` — dokumen FS/TS, SOP bisnis, spreadsheet backlog, flowchart proses (`.docx`, `.xlsx`, `.md`)
- `tests/` — skenario uji pergerakan barang / testing PO
- `outputs/` — hasil dump stock, snapshot saldo OBYC, export tabel `EKKO`/`EKPO`/`MSEG`

## Peta Sub-Project

| Sub-Project (folder) | Topik / Objek Utama | Cakupan | Kata Kunci untuk Routing |
|---|---|---|---|
| `subproject/AUTOMATION_BACKLOG/` | Backlog Otomasi MM | Inisiatif otomasi proses MM, prioritasi backlog, alignment kebutuhan bisnis ke teknis ABAP | backlog mm, otomasi mm, automation backlog, roadmap mm, improvement purchasing |
| `subproject/PURCHASING_PROCUREMENT/` | Purchasing (MM-PUR) | Purchase Requisition (`ME21N`), Purchase Order (`ME21N`/`ME22N`), Outline Agreement (`ME31K`/`ME31L`), Release Procedure/Strategy (`ME28`/`ME29N`) | po, pr, purchasing, me21n, me22n, me23n, release strategy, outline agreement, me31k, me28, me29n |
| `subproject/INVENTORY_MANAGEMENT/` | Inventory (MM-IM) | Goods Receipt (`101`), Goods Issue (`201`/`261`), Transfer Posting (`311`/`301`), Reservasi (`MB21`), Stock Overview (`MMBE`/`MB52`), Stock Opname (`MI01`) | migo, gr, gi, transfer posting, movement type, 101, 261, 311, reservation, mb21, mmbe, mb52, stock deficit |
| `subproject/INVOICE_VERIFICATION/` | Invoice Verification (MM-IV) | Logistics Invoice Verification (`MIRO`/`MIRA`), Invoice Release (`MRBR`), ERS (`MRRL`), selisih invoice (price variance/quantity variance) | miro, mira, mrbr, mrrl, invoice verification, liv, variance block, invoice release |
| `subproject/ACCOUNT_DETERMINATION/` | Account Determination & Integration | Konfigurasi OBYC, Valuation Class, Price Control V/S, GR/IR Clearing (`F.13`/`MR11`), integrasi MM-FI | obyc, account determination, valuation class, gr/ir clearing, mr11, f.13, moving average price, price control |

## Folder Non-Sub-Project

- `_SHARED/` — helper generik lintas sub-project: legacy rules, template dokumen, list server.

## Aturan Kerja Dengan Sub-Project

1. Baca permintaan user, cocokkan ke kolom **kata kunci** di tabel untuk memilih sub-project.
2. Jika ambigu antara dua sub-project, tanyakan ke user sebelum lanjut.
3. Baca konteks dari `docs/` sub-project itu dulu sebelum analisis masalah transaksi MM.
4. Simpan seluruh artefak kerja di subfolder yang sesuai (`src/`, `scripts/`, `docs/`, `outputs/`) di dalam subproject terkait — **dilarang menaruh file baru di root atau di `subproject/` langsung**.
5. Wajib membuat dan memelihara file pelacak `.md` (seperti `CHECKPOINT.md` atau `README.md`) di dalam folder sub-project terkait.

## AUTO-MAPPING — Menambah Sub-Project Baru (WAJIB)

Ketika muncul kasus/inisiatif baru yang **tidak cocok** dengan sub-project mana pun di tabel:

1. Buat folder baru di dalam `subproject/` dengan nama singkat huruf besar, mis. `subproject/NAMA_BARU/`.
2. Buat subfolder standar di dalamnya: `src/ scripts/ docs/ tests/ outputs/`.
3. Buat file `CHECKPOINT.md` di root folder subproject baru tersebut yang memuat identitas, status, latar belakang bisnis, dan daftar dokumen/task.
4. **Tambahkan satu baris ke tabel "Peta Sub-Project" di atas**: folder, topik utama, cakupan, dan kata kunci routing.
5. Taruh semua file terkait ke subfolder yang sesuai berdasarkan jenisnya.

Ringkas: **setiap sub-project baru = 1 folder di `subproject/` + subfolder standar + `CHECKPOINT.md` + 1 baris di tabel peta ini.**

