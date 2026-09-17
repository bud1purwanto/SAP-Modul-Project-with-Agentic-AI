# CHECKPOINT PROJECT — AUTO TECO (`ZPPI_COHVPI`)

Tanggal: 17 September 2026  
Status: Aktif  
Lokasi: `SAP PP Consultant/subproject/AUTO_TECO/`

---

## 1. Identitas & Ruang Lingkup
- **Program / Objek:** `ZPPI_COHVPI` (Auto TECO Process Order via BAPI `BAPI_PROCORD_COMPLETE_TECH`)
- **Modul:** SAP PP (Production Planning & Execution)
- **Target Landscape:** SAP ECC 6.0 EHP6 (NetWeaver 7.31) / Plant 2000
- **Fokus Kerja:**
  - Analisis dan code review program Auto TECO closing Process Order TRIAS.
  - Penanganan bug deteksi error TECO dan pencegahan commit prematur tanpa rollback.
  - Penyusunan dan sinkronisasi Functional Specification v4/v5 bersama tim ABAP.

---

## 2. Struktur Sub-Project
```
AUTO_TECO/
├── CHECKPOINT.md       <- Dokumen status & pelacak ini
├── docs/
│   └── FS_Auto_TECO_ZPPI_COHVPI.docx
├── src/
│   └── ZPPI_COHVPI_FIXED.abap
├── scripts/
├── tests/
└── outputs/
```

---

## 3. Dokumen & Deliverable
- `docs/FS_Auto_TECO_ZPPI_COHVPI.docx`: Functional Specification otomasi transaksi TECO order.
- `src/ZPPI_COHVPI_FIXED.abap`: Source code hasil review & perbaikan logic commit/rollback.

---

## 4. Pending Tasks / Next Steps
- [x] Code review temuan kritis return code & rollback.
- [x] Migrasi source code dan FS ke struktur subproject.
- [ ] Koordinasi pengujian di server Sandbox New Company (TRS) bersama ABAP developer.

