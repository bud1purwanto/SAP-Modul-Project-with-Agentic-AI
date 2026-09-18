## Konteks Inti Otomatis - Wajib Dipahami Saat New Chat

- Ini adalah proyek **SAP QM Consultant**. Jangan menganggap konteks proyek belum tersedia.
- Panggil user **Baginda**.
- Jangan menyuruh Baginda melakukan pekerjaan yang masih dapat dicari atau dikerjakan agent.
- Cari jalur alternatif sampai seluruh opsi aman yang tersedia benar-benar habis.
- Sebelum pekerjaan teknis, baca `CLAUDE.md` dan `SUBPROJECTS.md` secara lengkap.
- Jika pembacaan terminal biasa gagal, coba jalur read-only lain atau read-only di luar sandbox. Jangan langsung meminta Baginda menyalin file.
- Setelah routing ditemukan, baca Markdown relevan di folder subproject sebelum mengubah atau menganalisis apa pun.
- **Wajib bekerja hanya di dalam folder sub-project terkait (`subproject/<NAMA>/`). Dilarang menaruh file kerja baru di root.**
- **Setiap sub-project wajib memiliki dan memperbarui file `.md` (misal `CHECKPOINT.md`) serta menyimpan dokumen di subfolder `docs/`, `src/`, `scripts/`, `tests/`, atau `outputs/`.**

### Routing Langsung

- `coa`, `zmap_coa`, `zqmr_coa`, `zqmi_coa`, `certificate of analysis`, `zqmf_coa` -> `subproject/COA_AUTOMATION/`.
- `qa01`, `qa05`, `qe51n`, `qa11`, `usage decision`, `ud`, `inspection lot`, `qals` -> `subproject/INSPECTION_LOT/`.
- `certificate profile`, `qc01`, `qc02`, `qc03`, `qc15`, `qc21`, `qc22` -> `subproject/QUALITY_CERTIFICATES/`.
- `notification`, `qn01`, `qn02`, `qn03`, `defect`, `nonconformance` -> `subproject/QUALITY_NOTIFICATIONS/`.
- `barrier`, `wvtr`, `otr`, `mvtr`, `o2tr`, `barrier judgement` -> `subproject/BARRIER_INSPECTION/`.

### Konteks Teknis Tetap

- Landscape: NetWeaver 7.31 / ECC 6.0 EHP6 / Oracle / Plant 2000. Dilarang menyarankan fitur S/4HANA (Fiori QM apps).
- Default eksekusi transaksi mutu adalah SAP GUI via computer use.
- MCP SAP (`sap-leader`) digunakan diam-diam di background untuk verifikasi master data & lot inspeksi (`QALS`, `QAMV`, `QASE`, `QPAM`, `QPMK`).
- Prinsip: Tidak ada evidence = tidak boleh eksekusi.
- Tanggal server: periksa via MCP SAP hanya untuk server `sandbox-new` (TRS). Server lain gunakan real world date.
- Jika ada case email, wajib baca email dan jelaskan ringkasannya ke Baginda terlebih dahulu.
