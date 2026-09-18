## Konteks Inti Otomatis - Wajib Dipahami Saat New Chat

- Ini adalah proyek **SAP FICO Consultant**. Jangan menganggap konteks proyek belum tersedia.
- Panggil user **Baginda**.
- Jangan menyuruh Baginda melakukan pekerjaan yang masih dapat dicari atau dikerjakan agent.
- Cari jalur alternatif sampai seluruh opsi aman yang tersedia benar-benar habis.
- Sebelum pekerjaan teknis, baca `CLAUDE.md` dan `SUBPROJECTS.md` secara lengkap.
- Jika pembacaan terminal biasa gagal, coba jalur read-only lain atau read-only di luar sandbox. Jangan langsung meminta Baginda menyalin file.
- Setelah routing ditemukan, baca Markdown relevan di folder subproject sebelum mengubah atau menganalisis apa pun.
- **Wajib bekerja hanya di dalam folder sub-project terkait (`subproject/<NAMA>/`). Dilarang menaruh file kerja baru di root.**
- **Setiap sub-project wajib memiliki dan memperbarui file `.md` (misal `CHECKPOINT.md`) serta menyimpan dokumen di subfolder `docs/`, `src/`, `scripts/`, `tests/`, atau `outputs/`.**

### Routing Langsung

- `upload faktur`, `zfic_upload_faktur`, `zfi106`, `aedat`, `xblnr`, `faktur pajak` -> `subproject/UPLOAD_FAKTUR/`.
- `gl accounting`, `fs00`, `fb50`, `f-02`, `fagl_fcv`, `ob58`, `journal`, `general ledger`, `balance sheet` -> `subproject/GL_ACCOUNTING/`.
- `ap`, `accounts payable`, `f110`, `app`, `fb60`, `f-44`, `vendor clearing`, `payment run` -> `subproject/AP_PAYMENT/`.
- `ar`, `accounts receivable`, `fb70`, `f-28`, `f150`, `dunning`, `fd32`, `customer invoice` -> `subproject/AR_CREDIT/`.
- `asset accounting`, `as01`, `afab`, `f-90`, `abaon`, `aiab`, `aibu`, `depreciation` -> `subproject/ASSET_ACCOUNTING/`.
- `co`, `controlling`, `cost center`, `ks01`, `ko01`, `ko88`, `ck11n`, `ck24`, `kks2`, `co-pa` -> `subproject/COST_CONTROLLING/`.

### Konteks Teknis Tetap

- Landscape: NetWeaver 7.31 / ECC 6.0 EHP6 / Oracle / Plant 2000. Dilarang menyarankan fitur S/4HANA (ACDOCA, Central Finance, New Asset Accounting engine).
- Default eksekusi transaksi akuntansi adalah SAP GUI via computer use.
- MCP SAP (`sap-leader`) digunakan diam-diam di background untuk verifikasi master data & dokumen (`SKA1`/`SKB1`, `BKPF`/`BSEG`, `CSKS`, `LFB1`, `KNB1`).
- Prinsip: Tidak ada evidence = tidak boleh eksekusi.
- Tanggal server: periksa via MCP SAP hanya untuk server `sandbox-new` (TRS). Server lain gunakan real world date.
- Jika ada case email, wajib baca email dan jelaskan ringkasannya ke Baginda terlebih dahulu.
