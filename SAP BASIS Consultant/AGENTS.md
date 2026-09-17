## Konteks Inti Otomatis - Wajib Dipahami Saat New Chat

- Ini adalah proyek **SAP BASIS Consultant**. Jangan menganggap konteks proyek belum tersedia.
- Panggil user **Baginda**.
- Jangan menyuruh Baginda melakukan pekerjaan yang masih dapat dicari atau dikerjakan agent.
- Cari jalur alternatif sampai seluruh opsi aman yang tersedia benar-benar habis.
- Sebelum pekerjaan teknis, baca `CLAUDE.md` dan `SUBPROJECTS.md` secara lengkap.
- Jika pembacaan terminal biasa gagal, coba jalur read-only lain atau read-only di luar sandbox. Jangan langsung meminta Baginda menyalin file.
- Setelah routing ditemukan, baca Markdown relevan di folder subproject sebelum mengubah apa pun.
- **Wajib bekerja hanya di dalam folder sub-project terkait (`subproject/<NAMA>/`). Dilarang menaruh file kerja baru di root.**
- **Setiap sub-project wajib memiliki dan memperbarui file `.md` (misal `CHECKPOINT.md`) serta menyimpan dokumen di subfolder `docs/`, `src/`, `scripts/`, `tests/`, atau `outputs/`.**

### Routing Langsung

- `user license`, `lisensi user`, `usmm`, `license classification`, `audit lisensi` -> `subproject/USER_LICENSE/`.
- `sm50`, `sm51`, `rz10`, `rz11`, `st22`, `dump`, `sm21`, `syslog`, `workload`, `st03n`, `st02`, `sm12` -> `subproject/SYSTEM_MONITORING/`.
- `tms`, `stms`, `transport`, `import queue`, `return code`, `tp`, `r3trans`, `e070`, `e071` -> `subproject/TRANSPORT_TMS/`.
- `su01`, `su10`, `pfcg`, `role`, `authorization`, `su53`, `su24`, `security audit`, `sm19`, `sm20` -> `subproject/USER_SECURITY/`.
- `oracle`, `database`, `tablespace`, `db02`, `db13`, `brtools`, `brbackup`, `brspace`, `archive log` -> `subproject/BACKUP_DATABASE/`.

### Konteks Teknis Tetap

- Landscape: NetWeaver 7.31 / ECC 6.0 EHP6 / Oracle pada RHEL/SLES & IBM AIX / Windows Server.
- Default eksekusi administratif adalah SAP GUI via computer use.
- MCP SAP (`sap-leader`) digunakan diam-diam di background untuk verifikasi data sistem (`USR02`, `T000`, `E070`, dll).
- Dilarang keras eksekusi destruktif di Production (PRT/TRP).
- Jika ada case email, wajib baca email dan jelaskan isinya ke Baginda terlebih dahulu sebelum analisis.

