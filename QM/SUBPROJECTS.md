# SUBPROJECTS — Peta Sub-Project SAP QM Consultant

Baca file ini **pertama kali** setiap mulai kerja di project "SAP QM Consultant".
Fungsinya: menentukan sub-project mana yang relevan dengan permintaan user, lalu bekerja
hanya di dalam folder sub-project tersebut.

Semua sub-project berada di dalam folder induk `subproject/`.

```
SAP QM Consultant/
├── AGENTS.md                   <- Konteks otomatis agent saat New Chat & routing langsung
├── CLAUDE.md                   <- Aturan kerja & environment SAP QM
├── SUBPROJECTS.md              <- File ini (peta routing sub-project)
├── subproject/
│   ├── COA_AUTOMATION/         <- Review & requirement program COA (ZMAP_COA, ZQMR_COA, ZQMI_COA)
│   ├── INSPECTION_LOT/         <- QA01, QA05, QE51N results recording, QA11 UD, lot stuck
│   ├── QUALITY_CERTIFICATES/   <- QC01-03 certificate profile, QC15, QC21/22 release
│   ├── QUALITY_NOTIFICATIONS/  <- QN01-03 defect recording, notification processing
│   └── BARRIER_INSPECTION/     <- Inspeksi barrier WVTR/OTR, dynamic sampling, judgement
├── _SHARED/                    <- Helper / script / config generik lintas sub-project
```

## Struktur Umum Tiap Sub-Project

Setiap sub-project memakai subfolder standar:

- `src/` — script / code ABAP sample / validasi inspeksi
- `scripts/` — script otomasi testing / query live data QM
- `docs/` — dokumen spesifikasi teknis, MoM, matriks MIC, SOP inspeksi (`.md`, `.docx`, `.xlsx`)
- `tests/` — skenario sampling dan data uji lot inspeksi
- `outputs/` — snapshot lot `QALS`/`QASE`/`QAMV`, hasil cetak smartform COA, dump log

## Peta Sub-Project

| Sub-Project (folder) | Topik / Objek Utama | Cakupan | Kata Kunci untuk Routing |
|---|---|---|---|
| `subproject/COA_AUTOMATION/` | COA Automation & Review | Program COA (`ZMAP_COA`, `ZQMR_COA`, `ZQMI_COA`, `ZQMR_PENDING_BARRIER`), Smartform `ZQMF_COA`, mapping MIC film making/converting | coa, zmap_coa, zqmr_coa, zqmi_coa, certificate of analysis, zqmf_coa, mic mapping |
| `subproject/INSPECTION_LOT/` | Quality Inspection & Gates | Inspection lot creation (`QA01`/`QA05`), Results Recording (`QE51N`/`QE11`), Usage Decision (`QA11`/`QA12`), stock posting, lot stuck | qa01, qa05, qe51n, qa11, usage decision, ud, inspection lot, results recording, qals, qase |
| `subproject/QUALITY_CERTIFICATES/` | Quality Certificates Standard | Certificate Profile (`QC01`-`QC03`), Certificate Assignment (`QC15`), Certificate Output/Release (`QC21`/`QC22`) | certificate profile, qc01, qc02, qc03, qc15, qc21, qc22, standard coa |
| `subproject/QUALITY_NOTIFICATIONS/` | Quality Notifications | Defect Recording, Notification Processing (`QN01`-`QN03`), Action Box, Tasks & Activities | notification, qn01, qn02, qn03, defect, keluhan kualitas, nonconformance |
| `subproject/BARRIER_INSPECTION/` | Barrier Properties & Testing | Pengujian karakteristik barrier (WVTR/MVTR, OTR/O2TR), multiple cycles, judgement tanpa cancel UD | barrier, wvtr, otr, mvtr, o2tr, barrier judgement, inspection barrier |

## Folder Non-Sub-Project

- `_SHARED/` — helper generik lintas sub-project: template dokumen, helper query, config bersama.

## Aturan Kerja Dengan Sub-Project

1. Baca permintaan user, cocokkan ke kolom **kata kunci** di tabel untuk memilih sub-project.
2. Jika ambigu antara dua sub-project, tanyakan ke user sebelum lanjut.
3. Baca konteks dari `docs/` sub-project itu dulu sebelum analisa atau rekomendasi.
4. Simpan seluruh artefak kerja di subfolder yang sesuai (`src/`, `scripts/`, `docs/`, `outputs/`) di dalam subproject terkait — **dilarang menaruh file baru di root atau di `subproject/` langsung**.
5. Wajib membuat dan memelihara file pelacak `.md` (seperti `CHECKPOINT.md` atau `README.md`) di dalam folder sub-project terkait.

## AUTO-MAPPING — Menambah Sub-Project Baru (WAJIB)

Ketika muncul kasus/objek baru yang **tidak cocok** dengan sub-project mana pun di tabel:

1. Buat folder baru di dalam `subproject/` dengan nama singkat huruf besar, mis. `subproject/NAMA_BARU/`.
2. Buat subfolder standar di dalamnya: `src/ scripts/ docs/ tests/ outputs/`.
3. Buat file `CHECKPOINT.md` di root folder subproject baru tersebut yang memuat identitas, status, latar belakang mutu, dan daftar dokumen/task.
4. **Tambahkan satu baris ke tabel "Peta Sub-Project" di atas**: folder, topik utama, cakupan, dan kata kunci routing.
5. Taruh semua file terkait ke subfolder yang sesuai berdasarkan jenisnya.

Ringkas: **setiap sub-project baru = 1 folder di `subproject/` + subfolder standar + `CHECKPOINT.md` + 1 baris di tabel peta ini.**

