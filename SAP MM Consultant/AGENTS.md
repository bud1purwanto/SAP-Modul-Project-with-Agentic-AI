## Konteks Inti Otomatis - Wajib Dipahami Saat New Chat

- Ini adalah proyek **SAP MM Consultant**. Jangan menganggap konteks proyek belum tersedia.
- Panggil user **Baginda**.
- Jangan menyuruh Baginda melakukan pekerjaan yang masih dapat dicari atau dikerjakan agent.
- Cari jalur alternatif sampai seluruh opsi aman yang tersedia benar-benar habis.
- Sebelum pekerjaan teknis, baca `CLAUDE.md` dan `SUBPROJECTS.md` secara lengkap.
- Jika pembacaan terminal biasa gagal, coba jalur read-only lain atau read-only di luar sandbox. Jangan langsung meminta Baginda menyalin file.
- Setelah routing ditemukan, baca Markdown relevan di folder subproject sebelum mengubah atau menganalisis apa pun.
- **Wajib bekerja hanya di dalam folder sub-project terkait (`subproject/<NAMA>/`). Dilarang menaruh file kerja baru di root.**
- **Setiap sub-project wajib memiliki dan memperbarui file `.md` (misal `CHECKPOINT.md`) serta menyimpan dokumen di subfolder `docs/`, `src/`, `scripts/`, `tests/`, atau `outputs/`.**

### Routing Langsung

- `backlog mm`, `otomasi mm`, `automation backlog`, `roadmap mm`, `improvement purchasing` -> `subproject/AUTOMATION_BACKLOG/`.
- `po`, `pr`, `purchasing`, `me21n`, `me22n`, `me23n`, `release strategy`, `outline agreement`, `me31k`, `me28`, `me29n` -> `subproject/PURCHASING_PROCUREMENT/`.
- `migo`, `gr`, `gi`, `transfer posting`, `movement type`, `101`, `261`, `311`, `reservation`, `mb21`, `mmbe`, `mb52`, `stock deficit` -> `subproject/INVENTORY_MANAGEMENT/`.
- `miro`, `mira`, `mrbr`, `mrrl`, `invoice verification`, `liv`, `variance block`, `invoice release` -> `subproject/INVOICE_VERIFICATION/`.
- `obyc`, `account determination`, `valuation class`, `gr/ir clearing`, `mr11`, `f.13`, `price control` -> `subproject/ACCOUNT_DETERMINATION/`.

### Konteks Teknis Tetap

- Landscape: NetWeaver 7.31 / ECC 6.0 EHP6 / Oracle / Plant 2000. Dilarang menyarankan fitur S/4HANA (Fiori BP conversion, embedded EWM).
- Default eksekusi transaksi logistik/procurement adalah SAP GUI via computer use.
- MCP SAP (`sap-leader`) digunakan diam-diam di background untuk verifikasi master data & status (`MARA`/`MARC`, `LFA1`/`LFB1`, `EKKO`/`EKPO`, `MCHB`, `T001L`).
- Prinsip: Tidak ada evidence = tidak boleh eksekusi.
- Tanggal server: periksa via MCP SAP hanya untuk server `sandbox-new` (TRS). Server lain gunakan real world date.
- Jika ada case email, wajib baca email dan jelaskan ringkasannya ke Baginda terlebih dahulu.
