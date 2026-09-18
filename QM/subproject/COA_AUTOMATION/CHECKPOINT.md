# CHECKPOINT PROJECT — COA AUTOMATION REVIEW

Tanggal: 17 September 2026  
Status: Aktif  
Lokasi: `SAP QM Consultant/subproject/COA_AUTOMATION/`

---

## 1. Identitas & Ruang Lingkup
- **Program / Objek Terkait:** `ZMAP_COA`, `ZQMR_COA`, `ZQMI_COA` (`ZQMI_CERTIFICATE`), `ZQMR_PENDING_BARRIER` / Smartform `ZQMF_COA`
- **Modul:** SAP QM (Quality Management) / Certificate of Analysis
- **Target Landscape:** SAP ECC 6.0 EHP6 (NetWeaver 7.31) / TRS & TRD
- **Fokus Kerja:**
  - Evaluasi pemetaan formula MIC film making (JR/SR Base Film & Converting).
  - Validasi 8 skenario MoM (Barrier multiple cycles, change grade SR BF/Converting, secondary slitting, material aksen).
  - Identifikasi gap modul barrier tanpa Cancel UD (`ZQMR_PENDING_BARRIER`).

---

## 2. Struktur Sub-Project
```
COA_AUTOMATION/
├── CHECKPOINT.md       <- Dokumen status & pelacak ini
├── docs/
│   └── Review_ZMAP_COA_ZQMR_COA_ZQMI_COA_2026-07-08.md
├── src/
├── scripts/
├── tests/
└── outputs/
```

---

## 3. Dokumen & Deliverable
- `docs/Review_ZMAP_COA_ZQMR_COA_ZQMI_COA_2026-07-08.md`: Laporan komprehensif code review 4 program otomatisasi COA dan matriks validasi skenario MoM.

---

## 4. Pending Tasks / Next Steps
- [x] Dokumentasi dan klasifikasi gap fungsi program COA.
- [ ] Konfirmasi keberadaan objek `ZQMR_PENDING_BARRIER` / program pengganti ke tim ABAP.
- [ ] Validasi penarikan MIC barrier cycle terakhir pada pengujian data riil.

