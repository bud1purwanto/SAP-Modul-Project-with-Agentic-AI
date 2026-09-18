## Konteks Inti Otomatis - Wajib Dipahami Saat New Chat

- Ini adalah proyek **SAP PP Consultant**. Jangan menganggap konteks proyek belum tersedia.
- Panggil user **Baginda**.
- Jangan menyuruh Baginda melakukan pekerjaan yang masih dapat dicari atau dikerjakan agent.
- Cari jalur alternatif sampai seluruh opsi aman yang tersedia benar-benar habis.
- Sebelum pekerjaan teknis, baca `CLAUDE.md` dan `SUBPROJECTS.md` secara lengkap.
- Jika pembacaan terminal biasa gagal, coba jalur read-only lain atau read-only di luar sandbox. Jangan langsung meminta Baginda menyalin file.
- Setelah routing ditemukan, baca Markdown relevan di folder subproject sebelum mengubah atau menganalisis apa pun.
- **Wajib bekerja hanya di dalam folder sub-project terkait (`subproject/<NAMA>/`). Dilarang menaruh file kerja baru di root.**
- **Setiap sub-project wajib memiliki dan memperbarui file `.md` (misal `CHECKPOINT.md`) serta menyimpan dokumen di subfolder `docs/`, `src/`, `scripts/`, `tests/`, atau `outputs/`.**

### Routing Langsung

- `cohvpi`, `zppi`, `teco`, `auto teco`, `zppi_cohvpi`, `bapi_procord_complete_tech` -> `subproject/AUTO_TECO/`.
- `bom`, `costing bom`, `production version`, `pv`, `master recipe`, `resource`, `work center`, `mkal`, `mast` -> `subproject/MASTER_DATA_BOM/`.
- `koreksi rr`, `confirmation`, `co11n`, `cors`, `cogi`, `afru`, `matdoc`, `order-matdoc` -> `subproject/CONFIRMATION_RR/`.
- `onboarding pp`, `context transfer`, `transfer konteks`, `orientasi pp`, `claude desktop config` -> `subproject/ONBOARDING/`.
- `jumbo roll`, `jr`, `sequence roll`, `uxtool`, `no urut jr` -> `subproject/JUMBO_ROLL_EXECUTION/`.
- `slit roll`, `sr`, `slitting`, `rekap slitting`, `koreksi out` -> `subproject/SLIT_ROLL_EXECUTION/`.

### Konteks Teknis Tetap

- Landscape: NetWeaver 7.31 / ECC 6.0 EHP6 / Oracle / Plant 2000. Dilarang menyarankan fitur S/4HANA (MRP Live, Fiori native).
- Default eksekusi transaksi produksi adalah SAP GUI via computer use.
- MCP SAP (`sap-leader`) digunakan diam-diam di background untuk verifikasi master data & order (`MKAL`, `CRHD`, `PLKO`, `T001L`, `MAST`/`STKO`, `MCHB`, `AUFK`).
- Prinsip: Tidak ada evidence = tidak boleh eksekusi.
- Tanggal server: periksa via MCP SAP hanya untuk server `sandbox-new` (TRS). Server lain gunakan real world date.
- Jika ada case email, wajib baca email dan jelaskan ringkasannya ke Baginda terlebih dahulu.

