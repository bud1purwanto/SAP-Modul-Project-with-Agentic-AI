# CONTEXT TRANSFER — SAP PP Consultant (PT. Trias Sentosa)

> File transfer konteks antar-sesi/LLM. Machine-readable & context-rich. Serahkan file ini ke AI berikutnya agar melanjutkan tanpa mengulang dari awal.

---

## 1. METADATA SESI

- **Nama Proyek:** SAP PP Consultant — PT. Trias Sentosa, Tbk.
- **Peran AI:** SAP PP Senior Consultant
- **Tanggal sesi:** 07–08 Juli 2026
- **Model AI asal:** claude-opus-4-8 (Cowork mode)
- **Status Sesi:** AKTIF — dua alur kerja selesai sebagian, ada tindak lanjut terbuka (lihat §6)
- **Sistem SAP fokus:**
  - Produksi: **TRD** — SAP ECC 6.0 EHP6 (SAP_APPL 606/SP03), NW 7.31, Oracle/Linux, **Plant 2000**
  - Sandbox New Company: **TRS** (`sandbox-new`, 192.168.6.243, client 130) — server tempat program review berada
- **Batasan versi:** ECC EHP6 only — JANGAN sarankan fitur S/4HANA (MRP Live, Fiori native) kecuali sebagai catatan "tidak tersedia".

---

## 2. RINGKASAN EKSEKUTIF

Sesi ini mengerjakan **dua hal**:
1. **Analisa otomasi case PP** dari 18 topik dokumen *PP Issue & Solution v2* + pola email support terbaru → menghasilkan 14 kandidat otomasi (backlog) untuk diserahkan ke tim ABAP. Deliverable: 1 Word + 1 Excel (sudah dibuat).
2. **Code review program ABAP `ZPPI_COHVPI` (Auto TECO)** di server Sandbox New Company atas permintaan user. Ditemukan **1 bug kritis** (deteksi error TECO tidak berfungsi), **1 kritis** (tidak ada rollback), plus gap penting terhadap kebutuhan closing PRO TRIAS. Temuan #1 & #2 sudah **diverifikasi ulang dan terkonfirmasi**.

---

## 3. STATUS & CAPAIAN SAAT INI

### 3A. Deliverable Analisa Otomasi (SELESAI)
Tersimpan di `C:\Users\Lenovo\Claude\Projects\SAP PP Consultant\`:
- `Usulan_Otomasi_Case_PP_untuk_ABAP.docx` — proposal naratif + spesifikasi RICEF awal (validated, docx OK).
- `Analisa_Otomasi_Case_PP_untuk_ABAP.xlsx` — 3 sheet: Ringkasan, Backlog Otomasi (14 item), Sumber Case.
- **14 kandidat otomasi** (PP-AUTO-01..14). Prioritas: **P1** = PP-AUTO-01 (Reset Sequence JR), PP-AUTO-02 (Mass Close PRO), PP-AUTO-04 (Pre-validasi Upload Planning JR). Detail di §5.

### 3B. Code Review ZPPI_COHVPI (SELESAI — menunggu tindak lanjut)
- Program dibaca penuh (713 baris) dari server `sandbox-new`.
- Interface `BAPI_PROCORD_COMPLETE_TECH` diverifikasi via read_function_module.
- Tabel `T399X` dicek: di server ini **tidak ada entry plant 2000** (hanya TTE, 0001, 1000).
- Temuan #1 & #2 (kritis) sudah diverifikasi ulang — VALID. Daftar lengkap di §5B.
- **Terbuka:** user kemungkinan minta cuplikan kode perbaikan `FORM TECO` (DETAIL_RETURN + commit/rollback bersyarat) untuk ABAP. Belum dibuat.

---

## 4. BATASAN & PREFERENSI PENGGUNA

- **Bahasa:** Indonesia; terminologi SAP tetap standar Inggris/SAP.
- **Gaya:** ringkas & langsung, minim verbositas dan formatting berlebihan.
- **Continuity Master AI:** saat konteks ~80–85% penuh atau diminta (`/checkpoint`, `/pindahAI`, "buat file transfer konteks"), buat file `.md` transfer konteks dengan 6 bagian baku (file ini mengikuti aturan itu).
- **Aturan wajib SAP (dari CLAUDE.md project):**
  1. Ada support request → **RAG SAP dulu** (`rag-sap`: `rag_answer` > `rag_search` > `rag_find_similar_issues`). Query 1 = Issue & Solution (wajib pertama), Query 2 = User Manual/Blueprint.
  2. Jika RAG kurang → INDEX.md → dokumen lokal `SAP PP Knowledge`.
  3. Butuh data live → **MCP SAP `sap-leader`** (background). Set active server dulu.
  4. **Verifikasi master data via MCP SAP sebelum eksekusi** — jangan mengasumsikan (VERID→MKAL, WC→CRHD, Routing→PLKO, SLoc→T001L, BOM→MAST/STKO, batch→MCHB, order→AUFK). Tidak ada evidence = tidak boleh eksekusi.
  5. Transaksi/eksekusi → **SAP GUI** (computer use). Data pendukung → **MCP SAP** background.
  6. Jika solusi tidak ada di RAG/INDEX dan pakai SAP Best Practice → **tawarkan dulu ke user**.
  7. Email case → cek email (`read_email`, `get_email_image`) sebelum analisa.
- **Tanggal server:** hanya Sandbox New Company (TRS) perlu cek via MCP (`GET_SYSTEM_TIME_REMOTE`, baca `L_DATE`). Server lain pakai tanggal real-world.
- **`rag_answer` endpoint sedang DOWN** sesi ini — pakai `rag_search` + baca dokumen lokal sebagai fallback.

---

## 5. REPOSITORI MEMORI UTAMA

### 5A. Backlog Otomasi (14 item) — ringkas

| ID | Pri | Case | RICEF | Modul |
|----|-----|------|-------|-------|
| PP-AUTO-01 | P1 | Reset No Urut Sequence Roll JR (saat ini edit tabel ZSEQNUM langsung via SE16N_INTERFACE — berisiko) | Report(E) | PP |
| PP-AUTO-02 | P1 | Mass Close/Settlement PRO + report pra-close (7.000+ PRO gagal close) | Report(E) | PP/CO/FI |
| PP-AUTO-04 | P1 | Pre-validasi Upload Planning JR (error tahun baru / mat Accent / calculating cost) | Interface/Enh | PP/CO |
| PP-AUTO-03 | P2 | Validasi & cleanup Order Type orphan (ZTR2 plant 2000 tak ada di T399X) | Config+Enh | PP |
| PP-AUTO-05 | P2 | Migrasi Calculator Excel .xlsm Norm JR ke report ABAP | Report/Conv | PP |
| PP-AUTO-06 | P2 | Guided Adjust Material Purchase O↔X (ZPP018) | Enhancement | PP/MM |
| PP-AUTO-07 | P2 | Cancel/Reverse Cockpit terpadu (Carpenter, PO JR beda PO, panjang inputan, ZPP041, Batal Start/Stop) | Report(E) | PP |
| PP-AUTO-08 | P2 | Rekonsiliasi Intercompany TTA-TRIAS + guided cancel O→X | Report/Enh | PP/SD/MM |
| PP-AUTO-13 | P2 | Error handling & logging eksekusi Slit Roll (ZPP001) | Enhancement | PP |
| PP-AUTO-09 | P3 | Guided transfer stock antar SLoc (timbang, mat-to-mat, recycle) | Report+Config | PP/MM |
| PP-AUTO-10 | P3 | Perbaikan Report Slitting Harian – single batch scrap (ZPP016N) | Report | PP |
| PP-AUTO-11 | P3 | Perbaikan UXTOOL / Report Harian JR (PRO tidak muncul) | Enhancement | PP |
| PP-AUTO-12 | P3 | Dummy Adhesive CKI via IT – batch runner | Report | PP |
| PP-AUTO-14 | P3 | Validasi OTR/QM saat reject-recreate (data hilang) | Enhancement | QM |

**Sumber email kunci:** "Request Check PRO Error Trias" (7.000+ PRO gagal close; ZTR2 plant 2000 tidak ada di T399X; runtime error COHVPI order lama), "Error transaksi Slitt Roll", "CALCULATOR ERROR // FORCE CLOSE", "Incorrect OTR data entry in SAP".

### 5B. Code Review `ZPPI_COHVPI` — Auto TECO

**Fakta terverifikasi:**
- Program: `REPORT ZPPI_COHVPI` (713 baris, dibuat J. Budi 06.08.2025, header salah tulis "Appl. Area: QM" padahal PP).
- Alur: `VALIDATION → GET_DATA → TECO → REFRESH → SEND_EMAIL`. `DISPLAY_ALV` dikomentari → jalan otomatis tanpa preview.
- Seleksi: dari `MKPF JOIN MSEG JOIN AUFK JOIN AFPO` WHERE `BUDAT IN S_BUDAT`, `AUART IN S_AUART`, `AUTYP IN S_AUTYP`. Handle collective/mill order via `AFPO-MILL_OC_AUFNR_U`.
- TECO via `BAPI_PROCORD_COMPLETE_TECH` untuk order berstatus `*REL*`.
- **Interface BAPI (verified):** `RETURN` = EXPORTING **struktur tunggal** BAPIRET2. Per-order hasil ada di **TABLES `DETAIL_RETURN`** (BAPI_ORDER_RETURN) + `APPLICATION_LOG`. Program **tidak** memanggil DETAIL_RETURN.
- **T399X server sandbox-new:** tidak ada entry plant 2000 (hanya TTE/0001/1000) — memvalidasi gap #3.

**Kode bermasalah (FORM TECO):**
```abap
DATA: IT_RETURN LIKE STANDARD TABLE OF BAPIRET2 WITH HEADER LINE.
...
CALL FUNCTION 'BAPI_PROCORD_COMPLETE_TECH'
  EXPORTING SCOPE_COMPL_TECH='1' WORK_PROCESS_GROUP='COWORK_BAPI' WORK_PROCESS_MAX=99
  IMPORTING RETURN = IT_RETURN            "RETURN struktur tunggal -> bind ke HEADER LINE
  TABLES    ORDERS = TECOORDER.
READ TABLE IT_RETURN WITH KEY TYPE = 'E'. "baca BODY (selalu kosong)
IF SY-SUBRC = 0. "error branch (dead code)" ELSE. PERFORM COMMIT. ENDIF.
```

**TEMUAN — KRITIS:**
- **#1 Deteksi error TECO mati.** `IMPORTING RETURN=IT_RETURN` mengikat ke header line; `READ TABLE IT_RETURN` mencari body yang tak pernah di-APPEND → SY-SUBRC selalu ≠0 → selalu ELSE → selalu COMMIT. Order gagal TECO tetap dianggap sukses; indikator error & isi email tidak akurat. Perbaikan wajib: pakai `TABLES DETAIL_RETURN`, evaluasi TYPE 'E'/'A' per AUFNR.
- **#2 Tidak ada rollback.** Tak ada `BAPI_TRANSACTION_ROLLBACK` di seluruh program. Commit per-order dalam satu LUW → `COMMIT WORK` order sukses berikutnya ikut mem-persist perubahan parsial order yang gagal.

**TEMUAN — PENTING (gap vs kebutuhan TRIAS):**
- **#3** Tidak ada pre-validasi `T399X` (order type+plant) → berpotensi runtime error/dump seperti kasus closing (ZTR2/2000).
- **#4** Seleksi berbasis movement → **backlog PRO lama tanpa movement baru tidak terjaring**. Cocok untuk TECO rutin, bukan pembersihan backlog. Untuk backlog perlu seleksi by status (AUFK/AFKO/JEST).
- **#5** Baru TECO, belum settlement/close (CLSD). Masalah email = CLSD. Perlu tambah KO88/CO88 + business complete atau nyatakan scope.
- **#6** Risiko timeout: `GET_ORDER_STATUS` (AIP9_STATUS_READ + SELECT SINGLE OBJNR) dipanggil berulang per order di 3 tempat → mahal untuk ribuan order. Baca status massal.
- **#7** Sender email hardcoded `'DDIC'` → ganti SY-UNAME/service user.
- **#8** Tidak ada AUTHORITY-CHECK order type/plant.
- **#9** Tidak ada application log persisten (hanya email CSV) → perlu BAL/tabel Z untuk audit.

**TEMUAN — MINOR:**
- `WORK_PROCESS_GROUP='COWORK_BAPI'` hardcoded (harus ada di RZ12) → jadikan opsional.
- Header komentar "QM" salah → PP.
- Subjek email hardcoded 'September 2025' lalu ditimpa → baris mati.
- Cek error hanya TYPE 'E', abaikan 'A'.
- Baris DELETE reversal (`SMBLN IS NOT INITIAL`) dikomentari → order dengan movement ter-cancel penuh tetap ter-TECO (verifikasi kebutuhan).
- FORM COMMIT redundan (DB_COMMIT+DEQUEUE_ALL+COMMIT WORK AND WAIT+BAPI_TRANSACTION_COMMIT).
- `S_WERKS` dikomentari → tak bisa batasi plant. Aktifkan.
- Tidak ada mode test/preview sebelum TECO massal.

---

## 6. LANGKAH SEGERA BERIKUTNYA

- [ ] **(Terbuka) Buat cuplikan kode perbaikan `FORM TECO`** untuk ABAP: tambah `TABLES DETAIL_RETURN`, loop evaluasi per AUFNR (TYPE 'E'/'A'), `COMMIT` hanya bila bersih, `BAPI_TRANSACTION_ROLLBACK` bila error sebelum lanjut. (Menjawab #1 & #2.)
- [ ] Opsi: rapikan hasil code review jadi dokumen handoff `.docx` untuk tim ABAP (temuan #1–#9 + cuplikan kode).
- [ ] Bila diminta lanjut analisa otomasi: pertimbangkan tambah kolom PIC/target sprint di Excel backlog, atau buat ringkasan 1 halaman untuk manajemen.
- [ ] Jika ABAP mengembangkan Auto TECO untuk backlog closing (PP-AUTO-02): pastikan mode seleksi by-status (bukan by-movement), pre-check T399X, dan tahap settlement+close — bukan sekadar TECO seperti ZPPI_COHVPI sekarang.
- [ ] Sebelum eksekusi apa pun di SAP: patuhi urutan wajib (RAG → INDEX → MCP SAP verifikasi master data → SAP GUI). Set active server sesuai target.

---
*Dibuat: 08 Juli 2026 | Untuk melanjutkan: baca §3 (status), §5 (detail teknis), §6 (to-do).*
