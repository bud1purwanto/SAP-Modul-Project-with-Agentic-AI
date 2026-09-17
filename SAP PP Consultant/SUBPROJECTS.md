# SUBPROJECTS — Peta Sub-Project SAP PP Consultant

Baca file ini **pertama kali** setiap mulai kerja di project "SAP PP Consultant".
Fungsinya: menentukan sub-project mana yang relevan dengan permintaan user, lalu bekerja
hanya di dalam folder sub-project tersebut.

Semua sub-project berada di dalam folder induk `subproject/`.

```
SAP PP Consultant/
├── AGENTS.md                   <- Konteks otomatis agent saat New Chat & routing langsung
├── CLAUDE.md                   <- Aturan kerja & environment SAP PP
├── SUBPROJECTS.md              <- File ini (peta routing sub-project)
├── SAP PP Knowledge/           <- Knowledge base referensi dokumen (INDEX.md)
├── subproject/
│   ├── AUTO_TECO/              <- Program ZPPI_COHVPI, Auto TECO BAPI, FS/code review
│   ├── MASTER_DATA_BOM/        <- BOM costing vs production, PV JR/SR, master data
│   ├── CONFIRMATION_RR/        <- Koreksi Result Recording, order-matdoc, AFRU
│   ├── ONBOARDING/             <- Dokumen orientasi pabrik, context transfer, MCP config
│   ├── JUMBO_ROLL_EXECUTION/   <- Eksekusi JR, reset sequence roll, UXTOOL
│   └── SLIT_ROLL_EXECUTION/    <- Eksekusi SR, slitting report, koreksi GI out
├── _SHARED/                    <- Helper / script / config generik lintas sub-project
```

## Struktur Umum Tiap Sub-Project

Setiap sub-project memakai subfolder standar:

- `src/` — source code / program ABAP pendukung (`.abap`) / formula
- `scripts/` — script otomasi (`.py`, `.mjs`, `.ps1`, `.json` config)
- `docs/` — dokumen FS/TS, dokumen kajian, SOP, spreadsheet analisis (`.docx`, `.xlsx`, `.md`)
- `tests/` — skrip simulasi / data testing order
- `outputs/` — hasil dump/snapshot tabel `AFKO`/`AFRU`/`AUFK`, log eksekusi BAPI

## Peta Sub-Project

| Sub-Project (folder) | Topik / Objek Utama | Cakupan | Kata Kunci untuk Routing |
|---|---|---|---|
| `subproject/AUTO_TECO/` | `ZPPI_COHVPI` (Auto TECO) | Otomasi closing TECO Production Order, validasi return code BAPI, pencegahan commit tanpa rollback, sinkronisasi FS Auto TECO | cohvpi, zppi, teco, auto teco, zppi_cohvpi, bapi_procord_complete_tech, mass close pro |
| `subproject/MASTER_DATA_BOM/` | Master Data & BOM Costing | Arsitektur BOM Costing vs BOM Production (`CS01`/`CS02`), Production Version / PV (`C223`), Work Center (`CR01`), Recipe (`CA01`), Scrap JR/SR | bom, costing bom, production version, pv, master recipe, resource, work center, scrap setup, mkal, mast |
| `subproject/CONFIRMATION_RR/` | Confirmation & Koreksi RR | Koreksi Result Recording / konfirmasi order (`CO11N`/`CORS`), selisih pergerakan barang vs matdoc, AFRU/COGI troubleshooting | koreksi rr, confirmation, co11n, cors, cogi, afru, matdoc, order-matdoc |
| `subproject/ONBOARDING/` | Onboarding & Knowledge Transfer | Orientasi proses manufaktur Trias, transfer konteks antar sesi AI, setup konfigurasi MCP desktop | onboarding pp, context transfer, transfer konteks, orientasi pp, claude desktop config |
| `subproject/JUMBO_ROLL_EXECUTION/` | Jumbo Roll Execution | Eksekusi produksi Jumbo Roll, penomoran urut sequence roll, issue order tidak muncul di UXTOOL | jumbo roll, jr, sequence roll, uxtool, no urut jr, ppcl01, pppe01 |
| `subproject/SLIT_ROLL_EXECUTION/` | Slit Roll Execution | Eksekusi produksi Slit Roll, rekap slitting harian, koreksi GI out material tanpa scrap | slit roll, sr, slitting, rekap slitting, koreksi out, pppe02, pppe04 |

## Folder Non-Sub-Project

- `_SHARED/` — helper generik lintas sub-project.
- `SAP PP Knowledge/` — folder referensi lokal berisi `INDEX.md` dan arsip knowledge base proses manufaktur.

## Aturan Kerja Dengan Sub-Project

1. Baca permintaan user, cocokkan ke kolom **kata kunci** di tabel untuk memilih sub-project.
2. Jika ambigu antara dua sub-project, tanyakan ke user sebelum lanjut.
3. Baca konteks dari `docs/` sub-project itu dulu (FS/TS, `.md`) sebelum memberikan rekomendasi atau tindakan teknis.
4. Simpan seluruh artefak kerja di subfolder yang sesuai (`src/`, `scripts/`, `docs/`, `outputs/`) di dalam subproject terkait — **dilarang menaruh file baru di root atau di `subproject/` langsung**.
5. Wajib membuat dan memelihara file pelacak `.md` (seperti `CHECKPOINT.md` atau `README.md`) di dalam folder sub-project terkait.

## AUTO-MAPPING — Menambah Sub-Project Baru (WAJIB)

Ketika muncul kasus/program baru yang **tidak cocok** dengan sub-project mana pun di tabel:

1. Buat folder baru di dalam `subproject/` dengan nama singkat huruf besar, mis. `subproject/NAMA_BARU/`.
2. Buat subfolder standar di dalamnya: `src/ scripts/ docs/ tests/ outputs/`.
3. Buat file `CHECKPOINT.md` di root folder subproject baru tersebut yang memuat identitas, status, latar belakang manufaktur/teknis, dan daftar dokumen/task.
4. **Tambahkan satu baris ke tabel "Peta Sub-Project" di atas**: folder, topik utama, cakupan, dan kata kunci routing.
5. Taruh semua file terkait ke subfolder yang sesuai berdasarkan jenisnya.

Ringkas: **setiap sub-project baru = 1 folder di `subproject/` + subfolder standar + `CHECKPOINT.md` + 1 baris di tabel peta ini.**

