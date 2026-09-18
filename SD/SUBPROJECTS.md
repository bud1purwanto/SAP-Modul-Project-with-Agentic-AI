# SUBPROJECTS — Peta Sub-Project SAP SD Consultant

Baca file ini **pertama kali** setiap mulai kerja di project "SAP SD Consultant".
Fungsinya: menentukan sub-project mana yang relevan dengan permintaan user, lalu bekerja
hanya di dalam folder sub-project tersebut.

Semua sub-project berada di dalam folder induk `subproject/`.

```
SAP SD Consultant/
├── AGENTS.md                   <- Konteks otomatis agent saat New Chat & routing langsung
├── CLAUDE.md                   <- Aturan kerja & environment SAP SD
├── SUBPROJECTS.md              <- File ini (peta routing sub-project)
├── subproject/
│   ├── GENERAL_SD/             <- Subproject awal tracking & inisiatif umum SD
│   ├── SALES_ORDER/            <- VA01-03, customer master XD01, contract, scheduling agrmt
│   ├── SHIPPING_DELIVERY/      <- Outbound delivery VL01N/02N, picking, packing, PGI
│   ├── BILLING_REVENUE/        <- Billing VF01-03, VKOA revenue account determination, memo
│   ├── SPECIAL_SALES/          <- Konsinyasi, third-party TAS, intercompany, STO
│   └── PRICING_VOFM/           <- Pricing procedure VK11, VOFM formulas, user exits MV45AFZZ
├── _SHARED/                    <- Helper / script / config generik lintas sub-project
```

## Struktur Umum Tiap Sub-Project

Setiap sub-project memakai subfolder standar:

- `src/` — script / code include / formula pricing ABAP
- `scripts/` — script otomasi query live data SD
- `docs/` — dokumen FS/TS, skema kalkulasi harga, SOP sales, flow intercompany (`.md`, `.docx`, `.xlsx`)
- `tests/` — skenario uji sales flow dan testing simulasi pricing
- `outputs/` — snapshot order `VBAK`/`VBAP`, delivery `LIKP`/`LIPS`, invoice `VBRK`/`VBRP`, log VKOA

## Peta Sub-Project

| Sub-Project (folder) | Topik / Objek Utama | Cakupan | Kata Kunci untuk Routing |
|---|---|---|---|
| `subproject/GENERAL_SD/` | Inisiatif Umum SD | General inquiry modul SD, integrasi cross-module, tiket umum | general sd, info sd, inquiry sd, bantuan sd |
| `subproject/SALES_ORDER/` | Sales Orders (SD-SLS) | Quotation (`VA21`), Sales Order (`VA01`-`VA03`), Contract (`VA41`), Scheduling Agreement (`VA31`), Customer Master (`XD01`-`XD03`), Partner Determination | so, sales order, va01, va02, va03, quotation, contract, scheduling agreement, xd01, customer master |
| `subproject/SHIPPING_DELIVERY/` | Shipping & Delivery (SD-SHP) | Outbound Delivery (`VL01N`/`VL02N`), Picking, Packing, Post Goods Issue (`PGI`), Route & Shipping Point Determination | delivery, outbound delivery, vl01n, vl02n, vl03n, picking, packing, pgi, shipping point, route |
| `subproject/BILLING_REVENUE/` | Billing & Invoicing (SD-BIL) | Billing Document (`VF01`-`VF03`), Credit/Debit Memo, Cancel Billing (`VF11`), Penentuan Akun Pendapatan (`VKOA`), integrasi FI | billing, invoice sd, vf01, vf02, vf03, vf11, vkoa, revenue account determination, credit memo |
| `subproject/SPECIAL_SALES/` | Special Sales Processes | Konsinyasi (Fill-up, Issue, Return), Third-party (TAS), Intercompany Sales, Rush Order, Cash Sales, STO Delivery | consignment, konsinyasi, third party, tas, intercompany sales, rush order, cash sales, sto delivery |
| `subproject/PRICING_VOFM/` | Pricing & VOFM Customizing | Condition Record/Technique (`VK11`-`VK13`), Pricing Procedure, Access Sequence, VOFM formulas, User Exit Sales (`MV45AFZZ`) | pricing, condition type, vk11, pricing procedure, vofm, mv45afzz, userexit_save_document_prepare |

## Folder Non-Sub-Project

- `_SHARED/` — helper generik lintas sub-project: template dokumen, mapping server, config bersama.

## Aturan Kerja Dengan Sub-Project

1. Baca permintaan user, cocokkan ke kolom **kata kunci** di tabel untuk memilih sub-project.
2. Jika ambigu antara dua sub-project, tanyakan ke user sebelum lanjut.
3. Baca konteks dari `docs/` sub-project itu dulu sebelum analisa atau usulan solusi.
4. Simpan seluruh artefak kerja di subfolder yang sesuai (`src/`, `scripts/`, `docs/`, `outputs/`) di dalam subproject terkait — **dilarang menaruh file baru di root atau di `subproject/` langsung**.
5. Wajib membuat dan memelihara file pelacak `.md` (seperti `CHECKPOINT.md` atau `README.md`) di dalam folder sub-project terkait.

## AUTO-MAPPING — Menambah Sub-Project Baru (WAJIB)

Ketika muncul kasus/program baru yang **tidak cocok** dengan sub-project mana pun di tabel:

1. Buat folder baru di dalam `subproject/` dengan nama singkat huruf besar, mis. `subproject/NAMA_BARU/`.
2. Buat subfolder standar di dalamnya: `src/ scripts/ docs/ tests/ outputs/`.
3. Buat file `CHECKPOINT.md` di root folder subproject baru tersebut yang memuat identitas, status, latar belakang bisnis, dan daftar dokumen/task.
4. **Tambahkan satu baris ke tabel "Peta Sub-Project" di atas**: folder, topik utama, cakupan, dan kata kunci routing.
5. Taruh semua file terkait ke subfolder yang sesuai berdasarkan jenisnya.

Ringkas: **setiap sub-project baru = 1 folder di `subproject/` + subfolder standar + `CHECKPOINT.md` + 1 baris di tabel peta ini.**

