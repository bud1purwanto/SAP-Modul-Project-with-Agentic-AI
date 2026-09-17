# CHECKPOINT PROJECT — CONFIRMATION & KOREKSI RR

Tanggal: 17 September 2026  
Status: Aktif  
Lokasi: `SAP PP Consultant/subproject/CONFIRMATION_RR/`

---

## 1. Identitas & Ruang Lingkup
- **Topik / Objek:** Koreksi Result Recording (RR), Order Confirmation vs Material Document
- **Modul:** SAP PP / QM Integration
- **Target Landscape:** SAP ECC 6.0 EHP6 / Plant 2000
- **Tcode Terkait:** `CO11N`, `CORS`, `COGI`, `MB51`, `MIGO`
- **Fokus Kerja:**
  - Koreksi ketidaksesuaian pencatatan hasil produksi (Order-Matdoc).
  - Penanganan issue GI out material tanpa scrap dan pembersihan open posting.

---

## 2. Struktur Sub-Project
```
CONFIRMATION_RR/
├── CHECKPOINT.md       <- Dokumen status & pelacak ini
├── docs/
│   └── Koreksi RR 15-07 (Order-Matdoc).xlsx
├── src/
├── scripts/
├── tests/
└── outputs/
```

---

## 3. Dokumen & Deliverable
- `docs/Koreksi RR 15-07 (Order-Matdoc).xlsx`: Data rekapitulasi analisis kasus koreksi pergerakan material order vs confirmation log.

---

## 4. Pending Tasks / Next Steps
- [x] Migrasi file koreksi order-matdoc ke folder `docs/`.
- [ ] Verifikasi closing pergerakan barang terkait di tabel `AFRU`/`MSEG`.

