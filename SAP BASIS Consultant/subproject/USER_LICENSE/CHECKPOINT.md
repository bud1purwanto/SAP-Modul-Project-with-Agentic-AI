# CHECKPOINT PROJECT — USER LICENSE CLASSIFICATION

Tanggal: 17 September 2026  
Status: Aktif  
Lokasi: `SAP BASIS Consultant/subproject/USER_LICENSE/`

---

## 1. Identitas & Ruang Lingkup
- **Topik / Inisiatif:** Klasifikasi & Rekomendasi Lisensi User SAP
- **Modul:** SAP BASIS / System Administration & License Management
- **Target Landscape:** SAP ECC 6.0 EHP6 (NetWeaver 7.31) / TRS & TRD
- **Objek Terkait:** Tabel `USR02`, `USR06`, Tcode `USMM`, `LICENSE_ATTRIBUTES`, `SU01`, `SU10`
- **Fokus Kerja:**
  - Audit penggunaan akun SAP aktif vs inactive.
  - Klasifikasi tipe lisensi (Professional, Limited Professional, Employee Self-Service, dll).
  - Rekomendasi optimasi biaya lisensi SAP tahunan.

---

## 2. Struktur Sub-Project
```
USER_LICENSE/
├── CHECKPOINT.md       <- Dokumen status & pelacak ini
├── docs/
│   └── SAP_User_License_Classification_Recommendation.xlsx
├── src/
├── scripts/
├── tests/
└── outputs/
```

---

## 3. Dokumen & Deliverable
- `docs/SAP_User_License_Classification_Recommendation.xlsx`: Rangkuman pemetaan akun user ke rekomendasi tipe lisensi SAP yang optimal.

---

## 4. Pending Tasks / Next Steps
- [x] Migrasi dokumen rekomendasi lisensi ke `docs/`.
- [ ] Validasi audit log login terakhir user via tabel `USR02` / `SM20`.
- [ ] Konfirmasi penyesuaian tipe lisensi pada transaksi `SU10`/`USMM`.

