# CHECKPOINT PROJECT — UPLOAD FAKTUR PAJAK (`ZFIC_UPLOAD_FAKTUR`)

Tanggal: 17 September 2026  
Status: Aktif  
Lokasi: `SAP FICO Consultant/subproject/UPLOAD_FAKTUR/`

---

## 1. Identitas & Ruang Lingkup
- **Program / Objek:** `ZFIC_UPLOAD_FAKTUR` (Include FORM `EXECUTION`)
- **Tcode:** `ZFI106`
- **Modul:** SAP FICO / FI-AP / Tax Integration
- **Target Landscape:** SAP ECC 6.0 EHP6 (NetWeaver 7.31) / Development AIX (TRD) & Sandbox New (TRS)
- **Isu Utama:**
  - Update nomor faktur pajak (`BKPF-XBLNR`) melalui FM `CHANGE_DOCUMENT` tidak otomatis mengupdate tanggal perubahan terakhir dokumen (`BKPF-AEDAT`).
  - Rekomendasi perbaikan eksplisit: set `BKPF-AEDAT = SY-DATUM` sebelum pemanggilan FM `CHANGE_DOCUMENT`, serta sinkronisasi perubahan user stamp (`USNAM`).

---

## 2. Struktur Sub-Project
```
UPLOAD_FAKTUR/
├── CHECKPOINT.md       <- Dokumen status & pelacak ini
├── docs/
│   └── ZFIC_UPLOAD_FAKTUR_BKPF_AEDAT_Analysis.md
├── src/
├── scripts/
├── tests/
└── outputs/
```

---

## 3. Dokumen & Deliverable
- `docs/ZFIC_UPLOAD_FAKTUR_BKPF_AEDAT_Analysis.md`: Analisis komprehensif root cause ketiadaan pembaruan `BKPF-AEDAT`, perbandingan terhadap perilaku FB02 standar (`SAPMF05A`), dan usulan perbaikan kode ABAP.

---

## 4. Pending Tasks / Next Steps
- [x] Dokumentasi analisis teknis root cause `BKPF-AEDAT`.
- [ ] Koordinasi dengan ABAP developer untuk penambahan baris `IT_BKPF-AEDAT = SY-DATUM.` di FORM `EXECUTION`.
- [ ] Testing posting update faktur pajak di server `sandbox-new` / TRS dan verifikasi isi tabel `BKPF` via SE16.

