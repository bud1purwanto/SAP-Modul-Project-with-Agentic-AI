## Konteks Inti Otomatis - Wajib Dipahami Saat New Chat

- Ini adalah proyek **SAP SD Consultant**. Jangan menganggap konteks proyek belum tersedia.
- Panggil user **Baginda**.
- Jangan menyuruh Baginda melakukan pekerjaan yang masih dapat dicari atau dikerjakan agent.
- Cari jalur alternatif sampai seluruh opsi aman yang tersedia benar-benar habis.
- Sebelum pekerjaan teknis, baca `CLAUDE.md` dan `SUBPROJECTS.md` secara lengkap.
- Jika pembacaan terminal biasa gagal, coba jalur read-only lain atau read-only di luar sandbox. Jangan langsung meminta Baginda menyalin file.
- Setelah routing ditemukan, baca Markdown relevan di folder subproject sebelum mengubah atau menganalisis apa pun.
- **Wajib bekerja hanya di dalam folder sub-project terkait (`subproject/<NAMA>/`). Dilarang menaruh file kerja baru di root.**
- **Setiap sub-project wajib memiliki dan memperbarui file `.md` (misal `CHECKPOINT.md`) serta menyimpan dokumen di subfolder `docs/`, `src/`, `scripts/`, `tests/`, atau `outputs/`.**

### Routing Langsung

- `general sd`, `inquiry sd`, `bantuan sd` -> `subproject/GENERAL_SD/`.
- `so`, `sales order`, `va01`, `va02`, `va03`, `quotation`, `contract`, `xd01` -> `subproject/SALES_ORDER/`.
- `delivery`, `outbound delivery`, `vl01n`, `vl02n`, `picking`, `packing`, `pgi` -> `subproject/SHIPPING_DELIVERY/`.
- `billing`, `invoice sd`, `vf01`, `vf02`, `vf03`, `vkoa`, `revenue account determination` -> `subproject/BILLING_REVENUE/`.
- `consignment`, `konsinyasi`, `third party`, `tas`, `intercompany sales`, `rush order` -> `subproject/SPECIAL_SALES/`.
- `pricing`, `condition type`, `vk11`, `pricing procedure`, `vofm`, `mv45afzz` -> `subproject/PRICING_VOFM/`.

### Konteks Teknis Tetap

- Landscape: NetWeaver 7.31 / ECC 6.0 EHP6 / Oracle / Plant 2000. Dilarang menyarankan fitur S/4HANA (Fiori BP, simplifikasi PRCD_ELEMENTS, advanced ATP).
- Default eksekusi transaksi penjualan & pengiriman adalah SAP GUI via computer use.
- MCP SAP (`sap-leader`) digunakan diam-diam di background untuk verifikasi master data & dokumen (`KNA1`/`KNB1`, `VBAK`/`VBAP`, `LIKP`/`LIPS`, `VBRK`/`VBRP`, `KONV`/`KONP`).
- Prinsip: Tidak ada evidence = tidak boleh eksekusi.
- Tanggal server: periksa via MCP SAP hanya untuk server `sandbox-new` (TRS). Server lain gunakan real world date.
- Jika ada case email, wajib baca email dan jelaskan ringkasannya ke Baginda terlebih dahulu.
