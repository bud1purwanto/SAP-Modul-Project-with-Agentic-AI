# CHECKPOINT PROJECT — MASTER DATA & BOM COSTING

Tanggal: 17 September 2026  
Status: Aktif  
Lokasi: `SAP PP Consultant/subproject/MASTER_DATA_BOM/`

---

## 1. Identitas & Ruang Lingkup
- **Topik / Objek:** BOM Costing vs BOM Production, Production Version (PV), Jumbo Roll & Slit Roll Scrap Setup
- **Modul:** SAP PP (Master Data & Integration with CO-PC)
- **Target Landscape:** SAP ECC 6.0 EHP6 / Plant 2000
- **Tcode Terkait:** `CS01`/`CS02` (BOM), `C223` (Production Version), `CR01`/`CR02` (Work Center), `CA01`/`CA02` (Master Recipe), `CK11N`/`CK24` (Costing)
- **Fokus Kerja:**
  - Standarisasi struktur BOM antara kalkulasi biaya standar (costing) vs operasional pabrik.
  - Aturan penggunaan Production Version untuk lini film (BOPP, BOPET, Converting).
  - Dokumentasi best practice master data PP Trias Sentosa.

---

## 2. Struktur Sub-Project
```
MASTER_DATA_BOM/
├── CHECKPOINT.md       <- Dokumen status & pelacak ini
├── docs/
│   ├── BOM_Costing_vs_Production_dan_PV_JR_SR_Scrap.docx
│   ├── Master_Data_Kapan_Digunakan_PP_Trias.docx
│   └── Ringkasan_Master_Data_PP_Trias.docx
├── src/
├── scripts/
├── tests/
└── outputs/
```

---

## 3. Dokumen & Deliverable
- `docs/BOM_Costing_vs_Production_dan_PV_JR_SR_Scrap.docx`: Kajian perbedaan arsitektur BOM costing vs production dan penanganan scrap.
- `docs/Master_Data_Kapan_Digunakan_PP_Trias.docx`: Panduan operasional kapan master data PP digunakan.
- `docs/Ringkasan_Master_Data_PP_Trias.docx`: Ringkasan konfigurasi master data PP Trias Sentosa.

---

## 4. Pending Tasks / Next Steps
- [x] Sentralisasi dokumen arsitektur master data ke subproject `MASTER_DATA_BOM`.
- [ ] Validasi konsistensi Production Version (`MKAL`) pada lini slitting baru.

