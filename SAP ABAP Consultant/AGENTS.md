## Konteks Inti Otomatis - Wajib Dipahami Saat New Chat

- Ini adalah proyek **SAP ABAP Consultant**. Jangan menganggap konteks proyek belum tersedia.
- Panggil user **Baginda**.
- Jangan menyuruh Baginda melakukan pekerjaan yang masih dapat dicari atau dikerjakan agent.
- Cari jalur alternatif sampai seluruh opsi aman yang tersedia benar-benar habis.
- Sebelum pekerjaan teknis, baca `CLAUDE.md` dan `SUBPROJECTS.md` secara lengkap.
- Jika pembacaan terminal biasa gagal, coba jalur read-only lain atau read-only di luar sandbox. Jangan langsung meminta Baginda menyalin file.
- Setelah routing ditemukan, baca Markdown relevan di folder subproject sebelum mengubah apa pun.

### Routing Langsung

- `Auto TECO`, `TECO`, `COHVPI`, `ZPPI`, `ZPP001`, `ZPPR`, `production order` -> `subproject/AUTO_TECO/`; program utama `ZPPI_COHVPI`.
- `PO auto release`, `autorelease`, `ZPO_AUTO_RELEASE`, `ZMMI_PO_RELEASE` -> `subproject/PO_AUTO_RELEASE/`.
- `PO email`, `ZMMI_PO_EMAIL`, `approver`, `SMTP`, `SOST` -> `subproject/PO_EMAIL/`.
- `COA`, `ZQMI_COA`, `ZQMR_COA`, `ZQM002`, `ZQM003`, `certificate`, `MIC`, `QPMK` -> `subproject/COA/`.
- `barrier`, `ZQMI_PENDING_BARRIER`, `ZQM004`, `WVTR`, `OTR`, `MVTR`, `O2TR` -> `subproject/BARRIER/`.

### Konteks Teknis Tetap

- SAP utama: ECC 6.0 EHP6, NetWeaver 7.31, ABAP 7.31, Oracle.
- Gunakan `sap-leader-remote` untuk source, struktur, dan data SAP aktual. Jangan berasumsi.
- Jika agent berjalan di server Linux, gunakan MCP SAP server di `/var/www/MCP/MCP SAP/sap-leader-mcp/`. Jika berjalan lokal melalui GPT/Codex desktop, gunakan MCP yang terdaftar di `config.toml`; jika melalui Claude desktop, gunakan MCP lokal Claude yang sudah dikonfigurasi. Jangan memakai path MCP Windows dari environment Linux.
- Gunakan `manufacturing-rag` untuk knowledge dan dokumentasi manufacturing/SAP.
- Analisis boleh pada server yang relevan.
- Semua perubahan program SAP wajib hanya ke `sandbox-new` / SID `TRS`.
- Sebelum write, set active server ke `sandbox-new`.
- Prioritas update program: `Z_RFC_PROGRAM_UPDATE`.
- Gunakan sintaks ABAP 7.31. Dilarang inline `DATA(...)`, `@` host variable, string template, `NEW`, `VALUE`, `REDUCE`, dan `FILTER`.
- Dilarang direct update tabel standar SAP. Gunakan BAPI atau FM standar.
- Terapkan strict scope, preservasi formatting, minimal diff, backup source aktual, syntax-check, dan read-back verification.

## Imported Claude Cowork project instructions

SAP ABAP Consultant

### COA Dynamic Table & Smart Forms Architecture Rule:
Pastikan selalu membaca dan mematuhi arsitektur pada `subproject/COA/ARCHITECTURE_COA_DYNAMIC.md` saat mengembangkan atau memperbaiki COA:
1. `ZQMF_COA` murni hanya untuk Page 1 (Sertifikat / MIC Inspection Characteristics).
2. `ZQMF_COA_BATCH_POTRAIT` khusus untuk Lampiran Batch List (Portrait <= 8 kolom).
3. `ZQMF_COA_BATCH_LANDSCAPE` khusus untuk Lampiran Batch List (Landscape > 8 kolom).
4. Mapping dan ukuran kolom dinamis sesuai tabel `ZQM_COA_CUST_COL`.
5. Contoh verifikasi data uji:
   - DO `85004908` (6 Kolom - DOM_DEFAUL) -> ZQMF_COA + ZQMF_COA_BATCH_POTRAIT (2 Hal Portrait)
   - DO `0084000047` (7 Kolom - SRAABI) -> ZQMF_COA + ZQMF_COA_BATCH_POTRAIT (2 Hal Portrait)
   - DO `0085000140` (10 Kolom - SRACLI) -> ZQMF_COA + ZQMF_COA_BATCH_LANDSCAPE (Page 1 Port + Page 2 Land)

### Strict Scope & Minimal Diff Rule (WAJIB DIPATUHI):
1. **Fokus Murni Sesuai Permintaan:** HANYA ubah bagian kode, logika, atau baris yang secara eksplisit diminta oleh user.
2. **Dilarang Menghapus/Mengubah Formatting Tanpa Izin:** Dilarang menghapus baris kosong (blank lines), mengubah indentasi, whitespace, atau komentar di luar area yang diminta.
3. **No Unsolicited Logic / Refactoring:** Dilarang menambahkan fitur baru, validasi baru, atau merombak struktur kode yang tidak diminta.
4. **Verifikasi Diff:** Sebelum push atau selesai, selalu pastikan `git diff` hanya berisi perubahan esensial yang diminta user (minimal diff).
