## Konteks Inti Otomatis - Wajib Dipahami Saat New Chat

- Ini adalah proyek **SQL OLAP Consultant**. Jangan menganggap konteks proyek belum tersedia.
- Panggil user **Baginda**.
- Jangan menyuruh Baginda melakukan pekerjaan yang masih dapat dicari atau dikerjakan agent.
- Cari jalur alternatif sampai seluruh opsi aman yang tersedia benar-benar habis.
- Sebelum pekerjaan teknis, baca `CLAUDE.md` dan `SUBPROJECTS.md` secara lengkap.
- Jika pembacaan terminal biasa gagal, coba jalur read-only lain atau read-only di luar sandbox. Jangan langsung meminta Baginda menyalin file.
- Setelah routing ditemukan, baca Markdown relevan di folder subproject sebelum mengubah atau menganalisis apa pun.
- **Wajib bekerja hanya di dalam folder sub-project terkait (`subproject/<NAMA>/`). Dilarang menaruh file kerja baru di root.**
- **Setiap sub-project wajib memiliki dan memperbarui file `.md` (misal `CHECKPOINT.md`) serta menyimpan dokumen di subfolder `docs/`, `src/`, `scripts/`, `tests/`, atau `outputs/`.**

### Routing Langsung

- `general olap`, `general sql`, `info database`, `status sql` -> `subproject/GENERAL_OLAP/`.
- `execution plan`, `slow query`, `deadlock`, `blocking`, `query tuning`, `dmv` -> `subproject/QUERY_OPTIMIZATION/`.
- `data warehouse`, `star schema`, `snowflake`, `dimension`, `fact table`, `ssis`, `etl` -> `subproject/DATA_WAREHOUSE_ETL/`.
- `stored procedure`, `sp`, `procedure`, `udf`, `function`, `trigger`, `t-sql` -> `subproject/STORED_PROCEDURES/`.
- `index`, `columnstore`, `missing index`, `index fragmentation`, `update statistics` -> `subproject/INDEX_MAINTENANCE/`.

### Konteks Teknis Tetap

- Environment: SQL Server 2016 RTM (Compatibility Level 130) / Host `TRIASBA` / Collation `SQL_Latin1_General_CP1_CI_AS`. Dilarang menyarankan fitur SQL Server 2017+ (seperti `STRING_AGG`, `TRANSLATE`).
- MCP SQL (`mcp-sql`) bersifat **read-only secara arsitektur** (hanya SELECT/DMV, dilarang modifikasi data via tool ini).
- Query/DDL/DML yang memerlukan perubahan data harus disiapkan rapi agar user dapat mengeksekusinya secara manual melalui SSMS.
- Jika ada case email, wajib baca email dan jelaskan ringkasannya ke Baginda terlebih dahulu.
