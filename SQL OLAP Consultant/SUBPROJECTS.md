# SUBPROJECTS — Peta Sub-Project SQL / OLAP Consultant

Baca file ini **pertama kali** setiap mulai kerja di project "SQL OLAP Consultant".
Fungsinya: menentukan sub-project mana yang relevan dengan permintaan user, lalu bekerja
hanya di dalam folder sub-project tersebut.

Semua sub-project berada di dalam folder induk `subproject/`.

```
SQL OLAP Consultant/
├── AGENTS.md                   <- Konteks otomatis agent saat New Chat & routing langsung
├── CLAUDE.md                   <- Aturan kerja & environment SQL Server 2016
├── SUBPROJECTS.md              <- File ini (peta routing sub-project)
├── subproject/
│   ├── GENERAL_OLAP/           <- Subproject awal tracking inisiatif umum database & query
│   ├── QUERY_OPTIMIZATION/     <- Execution plan, DMV sys.dm_*, refactoring query, deadlock
│   ├── DATA_WAREHOUSE_ETL/     <- Star/Snowflake schema, dimension/fact, SSIS catalog
│   ├── STORED_PROCEDURES/      <- T-SQL stored procedures, triggers, functions, CTE
│   └── INDEX_MAINTENANCE/      <- Clustered/Non-clustered/Columnstore index, defrag, stats
├── _SHARED/                    <- Helper / script / config generik lintas sub-project
```

## Struktur Umum Tiap Sub-Project

Setiap sub-project memakai subfolder standar:

- `src/` — script T-SQL (`.sql`), DDL/DML, Stored Procedure, Table Definition
- `scripts/` — script helper otomasi (`.sql`, `.ps1`, `.py`, `.sh`)
- `docs/` — dokumen arsitektur skema, ERD, analisis execution plan, SOP database (`.md`, `.docx`, `.xlsx`)
- `tests/` — script test benchmark query, simulasi beban kerja / concurrency
- `outputs/` — hasil query export, XML execution plan (`.sqlplan`), export DMV log

## Peta Sub-Project

| Sub-Project (folder) | Topik / Objek Utama | Cakupan | Kata Kunci untuk Routing |
|---|---|---|---|
| `subproject/GENERAL_OLAP/` | Inisiatif Umum Database | General database inquiry, health check awal, pemetaan kasus baru | general olap, general sql, info database, status sql |
| `subproject/QUERY_OPTIMIZATION/` | Query Tuning & Optimization | Execution Plan Analysis, DMV monitoring (`sys.dm_exec_requests`, `sys.dm_tran_locks`), Deadlock resolution, Query refactoring | execution plan, slow query, deadlock, blocking, query tuning, dmv, cost threshold, query refactor |
| `subproject/DATA_WAREHOUSE_ETL/` | DW Modeling & SSIS ETL | Star/Snowflake Schema, Fact & Dimension Tables, SCD Type 1/2/3, SSIS Packages, ETL Data Flow | data warehouse, star schema, snowflake, dimension, fact table, ssis, etl, data pipeline, staging |
| `subproject/STORED_PROCEDURES/` | T-SQL Development | Stored Procedures, User-Defined Functions (UDF), Triggers, Complex Joins, Window Functions, CTE, Dynamic SQL | stored procedure, sp, procedure, udf, function, trigger, t-sql, cte, dynamic sql |
| `subproject/INDEX_MAINTENANCE/` | Indexing & Statistics | Clustered/Non-Clustered Index, Columnstore Index, Index Defragmentation (`DBCC INDEXDEFRAG`), `UPDATE STATISTICS` | index, columnstore, missing index, index fragmentation, update statistics, index rebuild |

## Folder Non-Sub-Project

- `_SHARED/` — helper generik lintas sub-project: skrip koneksi helper, template dokumentasi, config bersama.

## Aturan Kerja Dengan Sub-Project

1. Baca permintaan user, cocokkan ke kolom **kata kunci** di tabel untuk memilih sub-project.
2. Jika ambigu antara dua sub-project, tanyakan ke user sebelum lanjut.
3. Baca konteks dari `docs/` sub-project itu dulu sebelum analisa atau membuat query.
4. Simpan seluruh artefak kerja di subfolder yang sesuai (`src/`, `scripts/`, `docs/`, `outputs/`) di dalam subproject terkait — **dilarang menaruh file baru di root atau di `subproject/` langsung**.
5. Wajib membuat dan memelihara file pelacak `.md` (seperti `CHECKPOINT.md` atau `README.md`) di dalam folder sub-project terkait.

## AUTO-MAPPING — Menambah Sub-Project Baru (WAJIB)

Ketika muncul kasus/objek baru yang **tidak cocok** dengan sub-project mana pun di tabel:

1. Buat folder baru di dalam `subproject/` dengan nama singkat huruf besar, mis. `subproject/NAMA_BARU/`.
2. Buat subfolder standar di dalamnya: `src/ scripts/ docs/ tests/ outputs/`.
3. Buat file `CHECKPOINT.md` di root folder subproject baru tersebut yang memuat identitas, status, latar belakang arsitektur database, dan daftar dokumen/task.
4. **Tambahkan satu baris ke tabel "Peta Sub-Project" di atas**: folder, topik utama, cakupan, dan kata kunci routing.
5. Taruh semua file terkait ke subfolder yang sesuai berdasarkan jenisnya.

Ringkas: **setiap sub-project baru = 1 folder di `subproject/` + subfolder standar + `CHECKPOINT.md` + 1 baris di tabel peta ini.**

