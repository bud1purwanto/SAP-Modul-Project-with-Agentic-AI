# SUBPROJECTS — Peta Sub-Project

Baca file ini **pertama kali** setiap mulai kerja di project "SAP ABAP Consultant".
Fungsinya: menentukan sub-project mana yang relevan dengan permintaan user, lalu bekerja
hanya di dalam folder sub-project tersebut.

Semua sub-project berada di dalam folder induk `subproject/`.

```
SAP ABAP Consultant/
├── CLAUDE.md
├── SUBPROJECTS.md          <- file ini (peta routing)
├── subproject/
│   ├── PO_AUTO_RELEASE/
│   ├── PO_EMAIL/
│   ├── AUTO_TECO/
│   ├── COA/
│   ├── BARRIER/
│   └── GI_JR_CLOSING/
├── _SHARED/                <- helper generik lintas program
└── _REVIEW_IMAGES/         <- screenshot lama belum teridentifikasi
```

## Struktur Umum Tiap Sub-Project

Setiap sub-project memakai subfolder standar:

- `src/` — source code ABAP (`.abap`)
- `scripts/` — script otomasi (`.mjs`, `.js`, `.py`, `.ps1`) untuk push/fetch/patch/audit via MCP SAP
- `docs/` — dokumen FS/TS, spesifikasi, diagram, deck, xlsx timeframe/test-scenario, gambar
- `tests/` — script test (`.ps1`, `test_*`)
- `outputs/` — hasil dump/backup JSON & TXT (snapshot source sebelum perubahan, backup tabel ZMAP)

## Peta Sub-Project

| Sub-Project (folder) | Program utama | Cakupan | Kata kunci untuk routing |
|---|---|---|---|
| `subproject/PO_AUTO_RELEASE/` | `ZPO_AUTO_RELEASE`, `ZMMI_PO_RELEASE_PHASE2` | Auto-release PO di bawah ambang (< USD 500), pilot org TPOL/9999, exception flagging, diagram proses As-Is/To-Be | po auto release, autorelease, zpo_auto_release, zmmi_po_release, release strategy, FRGRL/FRGKE, timeframe |
| `subproject/PO_EMAIL/` | `ZMMI_PO_EMAIL` | Routing approver berjenjang (Lisa/Melisa/Fenny/GM), notifikasi email PO, tabel mapping `ZMAP_TYPE` (EMAIL_TEXT, EXC_RULE, GM, PRICE_AXES, DEFAULT), dynamic exception rules | po email, zmmi_po_email, zmap_email, zmap_type, approver, gm, price_axes, exc_rule, SMTP/SOST |
| `subproject/AUTO_TECO/` | `ZPPI_COHVPI` | Auto TECO Production Order (interface MES), FS Auto TECO, validasi status order, email notif TECO | cohvpi, zppi, teco, auto teco, zpp001, zppr, production order |
| `subproject/COA/` | `ZQMI_COA` / `ZQMR_COA` (include `ZQMI_CERTIFICATE_F01`) | Certificate of Analysis — mode print (ZQM002) & ALV (ZQM003) via cabang `SY-TCODE`, perbaikan decimal MIC dari master QPMK, bootstrap patcher `ZTMP*` | coa, zqmi_coa, zqmr_coa, zqm002, zqm003, certificate, MIC, QPMK, decimal |
| `subproject/BARRIER/` | `ZQMI_PENDING_BARRIER` | Barrier Inspection List & Upload (ZQM004), Result Recording & Usage Decision untuk karakteristik barrier (WVTR/MVTR, OTR/O2TR) | barrier, pending barrier, zqmi_pending_barrier, zqm004, wvtr, otr, mvtr, o2tr, barrier judgement |
| `subproject/GI_JR_CLOSING/` | `ZPPR_GI_JR_CLOSING` | Observasi closing PP: exception GI Jumbo Roll vs GR (tanpa 261, selisih toleransi, GI < GR), ALV report & email notifikasi per line | gi jr closing, zppr_gi_jr_closing, jumbo roll, gi jr, closing pp, gi vs gr, zzprodline, zznomorroll |

## Folder Non-Sub-Project

- `_SHARED/` — helper generik lintas program: `list_sap_servers.mjs`, `sap-mcp-direct.mjs`, `generate_fs.py`, log, dsb. Boleh dipakai sub-project mana pun.
- `_REVIEW_IMAGES/` — screenshot lama tak teridentifikasi (`a-1.jpg`, `b-1.jpg`, dst). Perlu review manual Budi untuk dipindah ke sub-project yang benar atau dibuang.

## Aturan Kerja Dengan Sub-Project

1. Baca permintaan user, cocokkan ke kolom **kata kunci** di tabel untuk memilih sub-project.
2. Jika ambigu antara dua sub-project (mis. PO release vs PO email), tanyakan ke user sebelum lanjut.
3. Baca konteks dari `docs/` sub-project itu dulu (FS/TS) sebelum ubah kode.
4. Source hasil kerja simpan di `src/`, script di `scripts/`, backup/dump di `outputs/` sub-project yang sama — jangan taruh di root atau di dalam `subproject/` langsung.
5. Aturan push/update program tetap berlaku penuh dari CLAUDE.md: **write program hanya di server `sandbox-new`**, prioritas FM `Z_RFC_PROGRAM_UPDATE`.

## AUTO-MAPPING — Menambah Sub-Project Baru (WAJIB)

Ketika muncul program/permintaan yang **tidak cocok** dengan sub-project mana pun di tabel:

1. Buat folder baru di dalam `subproject/` dengan nama singkat huruf besar, mis. `subproject/NAMA_BARU/`.
2. Buat subfolder standar di dalamnya: `src/ scripts/ docs/ tests/ outputs/`.
3. **Tambahkan satu baris ke tabel "Peta Sub-Project" di atas**: folder, program utama, cakupan, dan kata kunci routing. Tanpa langkah ini sub-project baru tidak akan ter-route otomatis.
4. Taruh semua file terkait ke subfolder yang sesuai berdasarkan ekstensi:
   `.abap`→`src/`, `.mjs/.js/.py/.ps1`→`scripts/` (test→`tests/`), dokumen/gambar→`docs/`, `.json/.log/.txt` dump/backup→`outputs/`.
5. Jika satu file relevan ke >1 sub-project, taruh di sub-project utama dan sebut di kolom cakupan sub-project lain.

Ringkas: **setiap sub-project baru = 1 folder di `subproject/` + 1 baris di tabel peta ini.** Update tabel selalu, agar routing tetap otomatis.

## Catatan Housekeeping

- File `ZQMI_COA_Technical_Specification.docx` di root belum bisa dipindah (terbuka di Word). Tutup Word, lalu pindah manual ke `subproject/COA/docs/`.
- Folder lama kosong `docs/ scripts/ tests/ tools/ outputs/` di root sudah tidak dipakai. Hapus manual lewat File Explorer.
