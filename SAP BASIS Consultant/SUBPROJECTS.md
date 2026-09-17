# SUBPROJECTS — Peta Sub-Project SAP BASIS Consultant

Baca file ini **pertama kali** setiap mulai kerja di project "SAP BASIS Consultant".
Fungsinya: menentukan sub-project mana yang relevan dengan permintaan user, lalu bekerja
hanya di dalam folder sub-project tersebut.

Semua sub-project berada di dalam folder induk `subproject/`.

```
SAP BASIS Consultant/
├── AGENTS.md               <- Konteks otomatis agent saat New Chat & routing langsung
├── CLAUDE.md               <- Aturan kerja & environment SAP Basis
├── SUBPROJECTS.md          <- File ini (peta routing sub-project)
├── subproject/
│   ├── USER_LICENSE/       <- Klasifikasi dan rekomendasi lisensi user SAP
│   ├── SYSTEM_MONITORING/  <- Monitoring WP, parameter, ST22 dump, SM21 syslog
│   ├── TRANSPORT_TMS/      <- STMS, import queue, troubleshooting transport
│   ├── USER_SECURITY/      <- Otorisasi, role PFCG, SU24, audit log SM19/20
│   └── BACKUP_DATABASE/    <- Database Oracle, BR*Tools, DB02/13, tablespace
├── _SHARED/                <- Helper / script / config generik lintas sub-project
```

## Struktur Umum Tiap Sub-Project

Setiap sub-project memakai subfolder standar:

- `src/` — script OS / SQL query / parameter config / profile template
- `scripts/` — script otomasi (`.sh`, `.py`, `.mjs`, `.ps1`) untuk monitoring/audit
- `docs/` — dokumen SOP, rekomendasi, arsitektur, checklist, spreadsheet analisis (`.xlsx`, `.docx`, `.md`)
- `tests/` — skrip simulasi / testing connection / authorization test
- `outputs/` — hasil dump log, snapshot `trans.log`, snapshot buffer `ST02`, log transport

## Peta Sub-Project

| Sub-Project (folder) | Topik / Objek Utama | Cakupan | Kata Kunci untuk Routing |
|---|---|---|---|
| `subproject/USER_LICENSE/` | Klasifikasi Lisensi User | Audit user aktif/inaktif (`USR02`, `USMM`), rekomendasi tipe lisensi SAP, optimasi biaya lisensi | user license, lisensi user, usmm, license classification, audit lisensi, user type |
| `subproject/SYSTEM_MONITORING/` | System Health & Performance | Monitoring work process (`SM50`/`SM51`), profile parameter (`RZ10`/`RZ11`), short dump (`ST22`), system log (`SM21`), workload (`ST03N`), buffer (`ST02`) | sm50, sm51, rz10, rz11, st22, dump, sm21, syslog, workload, st03n, st02, lock sm12 |
| `subproject/TRANSPORT_TMS/` | TMS & Transport Execution | Konfigurasi TMS, import queue (`STMS`), return code error (RC=4, RC=8, RC=12), transport tools OS (`tp`, `R3trans`) | tms, stms, transport, import queue, return code, tp, r3trans, e070, e071 |
| `subproject/USER_SECURITY/` | Otorisasi & User Security | Pemeliharaan user (`SU01`/`SU10`), role maintenance (`PFCG`), SU24 matrix, SU53 auth trace, security audit log (`SM19`/`SM20`) | su01, su10, pfcg, role, authorization, su53, su24, security audit, sm19, sm20 |
| `subproject/BACKUP_DATABASE/` | Oracle Database & Storage | Monitoring tablespace (`DB02`), job DBA (`DB13`), eksekusi `BR*Tools` (`BRBACKUP`, `BRCONNECT`, `BRSPACE`), archive log | oracle, database, tablespace, db02, db13, brtools, brbackup, brspace, archive log |

## Folder Non-Sub-Project

- `_SHARED/` — helper generik lintas sub-project: skrip koneksi, mapping server, log global. Boleh dipakai sub-project mana pun.

## Aturan Kerja Dengan Sub-Project

1. Baca permintaan user, cocokkan ke kolom **kata kunci** di tabel untuk memilih sub-project.
2. Jika ambigu antara dua sub-project, tanyakan ke user sebelum lanjut.
3. Baca konteks dari `docs/` sub-project itu dulu (SOP / checklist / `.md`) sebelum melakukan analisa atau eksekusi.
4. Simpan seluruh artefak kerja di subfolder yang sesuai (`src/`, `scripts/`, `docs/`, `outputs/`) di dalam subproject terkait — **dilarang menaruh file baru di root atau di `subproject/` langsung**.
5. Wajib membuat dan memelihara file pelacak `.md` (seperti `CHECKPOINT.md` atau `README.md`) di dalam folder sub-project terkait untuk mencatat status, temuan, dan langkah berikutnya.

## AUTO-MAPPING — Menambah Sub-Project Baru (WAJIB)

Ketika muncul kasus/topik baru yang **tidak cocok** dengan sub-project mana pun di tabel:

1. Buat folder baru di dalam `subproject/` dengan nama singkat huruf besar, mis. `subproject/NAMA_BARU/`.
2. Buat subfolder standar di dalamnya: `src/ scripts/ docs/ tests/ outputs/`.
3. Buat file `CHECKPOINT.md` di root folder subproject baru tersebut yang berisi identitas, status, latar belakang masalah, dan daftar dokumen/task.
4. **Tambahkan satu baris ke tabel "Peta Sub-Project" di atas**: folder, topik utama, cakupan, dan kata kunci routing. Tanpa langkah ini sub-project baru tidak akan ter-route otomatis.
5. Taruh semua file terkait ke subfolder yang sesuai berdasarkan jenisnya.

Ringkas: **setiap sub-project baru = 1 folder di `subproject/` + subfolder standar + `CHECKPOINT.md` + 1 baris di tabel peta ini.**

