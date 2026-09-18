# CHECKPOINT PROJECT — MM AUTOMATION BACKLOG

Tanggal: 17 September 2026  
Status: Aktif  
Lokasi: `SAP MM Consultant/subproject/AUTOMATION_BACKLOG/`

---

## 1. Identitas & Ruang Lingkup
- **Topik / Inisiatif:** Backlog Inisiatif Otomasi SAP MM (Procurement & Inventory)
- **Modul:** SAP MM (Materials Management)
- **Target Landscape:** SAP ECC 6.0 EHP6 (NetWeaver 7.31) / TRS & TRD
- **Objek Terkait:** Purchase Requisition (PR), Purchase Order (PO), Release Strategy (`ME28`/`ME29N`), Goods Movement (`MIGO`), Inventory Management, Invoice Verification (`MIRO`)
- **Fokus Kerja:**
  - Pemetaan bottleneck proses operasional purchasing dan inventory.
  - Penyusunan backlog otomasi (seperti PO Auto Release, auto email PO, exception flagging).
  - Evaluasi kelayakan RICEF untuk implementasi tim ABAP.

---

## 2. Struktur Sub-Project
```
AUTOMATION_BACKLOG/
├── CHECKPOINT.md       <- Dokumen status & pelacak ini
├── docs/
│   └── SAP_MM_Automation_Backlog.xlsx
├── src/
├── scripts/
├── tests/
└── outputs/
```

---

## 3. Dokumen & Deliverable
- `docs/SAP_MM_Automation_Backlog.xlsx`: Daftar inisiatif otomasi proses MM, tingkat prioritas, status pengajuan, dan estimasi dampak efisiensi bisnis.

---

## 4. Pending Tasks / Next Steps
- [x] Migrasi backlog inisiatif otomasi MM ke struktur subproject.
- [ ] Review backlog bersama lead konsultan MM dan user bisnis.
- [ ] Penyelarasan kandidat otomasi dengan subproject ABAP (seperti `PO_AUTO_RELEASE` dan `PO_EMAIL`).

