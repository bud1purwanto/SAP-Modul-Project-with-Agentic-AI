# Functional Specification: ZPPR_GI_JR_CLOSING
## Observasi Closing PP — Exception GI Jumbo Roll Terhadap GR

| Atribut | Keterangan |
|---|---|
| **Program Name** | `ZPPR_GI_JR_CLOSING` |
| **SAP Module** | Production Planning (PP) / Quality Management (QM) / Controlling (CO) |
| **Subproject** | `subproject/GI_JR_CLOSING/` |
| **Target System** | SAP ECC 6.0 EHP6 / NW 7.31 (TRS / TRD) |
| **Pola Referensi** | `ZPPI_COHVPI` (Job/Order logic), `ZMMI_PO_EMAIL` (ALV & Mail logic), `ZQMR_TRACEABILITY` (Trace logic & Combined Order), InfoSet SQ01 `/KYK/IS_UG/ORDER_MOVEMENT` |
| **Status Dokumen** | Approved Concept & Design Refinement |

---

## 1. Latar Belakang Bisnis & Ground Truth Sistem

### 1.1 Konteks Operasional Manufaktur Roll
Pada proses manufaktur film plastik / converting / slitting:
1. **Penerimaan Jumbo Roll (GR):** Dokumen GR dibentuk melalui pergerakan **Movement Type 101/102** untuk menghasilkan batch Jumbo Roll (JR).
2. **Pemakaian Bahan Baku (GI):** Bersamaan dengan itu, bahan baku (resin/feeder roll) dipotong melalui **Movement Type 261/262** atau custom movement `901/902`.
3. **By-Product & Waste:** Produk sampingan / waste dicatat melalui Movement `531/532` dengan karakteristik batch `ZZWEIGHTEL`.
4. **Extra Length PPIC:** Pada planning SR PPIC terdapat alokasi *Extra Length* (umumnya ~1%) yang menyebabkan selisih matematis antara GI dan GR adalah wajar secara operasional:
   $$\text{Waste Combine} = Qty_{GI\ JR} - Qty_{GR\ Slit\ Roll} - Qty_{Extra\ Length}$$
   *Contoh Riil:* GI JR = $1.771,45\text{ kg}$, GR Slit Roll = $1.693,50\text{ kg}$, Extra Length = $14,84\text{ kg}$ $\rightarrow$ Waste = $63,11\text{ kg}$.

Oleh karena itu, proses observasi closing tidak boleh membandingkan angka secara mentah tanpa mempertimbangkan pergerakan reversal, combined order, dan batas toleransi bisnis.

### 1.2 Penelusuran Transaksional & Pola Eksisting
- **InfoSet SQ01:** `ORDER_MOVEMENT` pada User Group `/KYK/IS_UG` (*Process Order Movement*).
- **Program `ZQMR_TRACEABILITY`:** Menggunakan tabel `MSEG`/`AUFM`, pencocokan dokumen via `MKPF-BKTXT`, dan resolusi hirarki order gabungan via `AFPO-MILL_OC_AUFNR_U`.
- **Karakteristik Batch:**
  - `ZZPRODLINE`: `CABN-ATINN = 0000000857`, Class Type `023`, tipe `CHAR 2`.
  - `ZZNOMORROLL`: Nomor fisik roll JR.

---

## 2. Definisi Kriteria Observasi Closing

Program dijalankan sebagai executable report tunggal dengan 3 pilihan mode radio button:

```text
Kriteria Observasi Closing
  (•) Semua Anomali Closing                   [ R_ALL  ]
  ( ) Tidak Ada GI Sama Sekali                [ R_NOGI ]
  ( ) GI Kurang dari JR                       [ R_LESS ]
```

### 2.1 Mode 1: Semua Anomali (`R_ALL`) - Default
- **Kriteria:** Menampilkan seluruh anomali closing yang relevan, baik batch yang belum ada GI sama sekali maupun yang kuantitas GI-nya kurang dari kuantitas JR.
- **Kalkulasi:** `cnt_261 = 0` ATAU `( cnt_261 > 0 AND qty_gi < qty_gr - p_tol )`.
- **Tujuan Bisnis:** Memberikan visibilitas menyeluruh bagi user closing dalam satu kali eksekusi tanpa perlu bolak-balik mengubah radio button.

### 2.2 Mode 2: Tidak Ada GI Sama Sekali (`R_NOGI`)
- **Kriteria:** Ada Goods Receipt (GR) Jumbo Roll efektif ($Net_{101-102} > 0$), namun **tidak ada Goods Issue (GI) 261 efektif** sampai batas tanggal posting cutoff (`cnt_261 = 0` / `qty_gi = 0`).
- **Penanganan Reversal:** Dokumen pembatalan `262` harus mengurangi record `261`. Jika hasil netto konsumsi $= 0$ atau nihil record 261, data dimasukkan ke laporan.
- **Output:** Daftar batch JR yang belum pernah dikonsumsi bahannya di sistem (unconsumed raw material).

### 2.3 Mode 3: GI Kurang dari JR (`R_LESS`)
- **Kriteria:** Terdapat konsumsi GI efektif ($Net_{261-262} > 0$), namun total kuantitas GI masih berada di bawah kuantitas JR di luar batas toleransi.
- **Kalkulasi:** `cnt_261 > 0 AND qty_gi < ( qty_gr - p_tol )`.
- **Tujuan Bisnis:** Memfokuskan verifikasi pada order dengan potensi under-consumption (kekurangan potong bahan baku).
*(Catatan: Mode arbitrer selisih mutlak GI vs GR dihapus karena kondisi $GI > GR$ merupakan hal wajar akibat waste/trim pada industri roll).*

---

## 3. Logika Penelusuran & Fallback Terkontrol

### 3.1 Multi-Key Matching
Pencocokan antara dokumen penerimaan (GR) dan konsumsi (GI) menghubungkan:
1. Material (`MATNR`)
2. Batch (`CHARG`)
3. Related Order (Order pembuat JR vs Order pemakai melalui `AFPO-MILL_OC_AUFNR_U`)
4. Header Text (`MKPF-BKTXT`)
5. Plant (`WERKS`)
6. Tanggal Posting Cutoff (`BUDAT`)
7. Referensi Dokumen Reversal (`MSEG-SMBLN`, `SJAHR`, `SMBLP`)

### 3.2 Penampung Relasi Order (`TY_ORDER_LINK`)
```abap
TYPES: BEGIN OF ty_order_link,
         source_aufnr TYPE aufnr,    " Producing Order
         target_aufnr TYPE aufnr,    " Consuming Order / Movement Order
         matnr        TYPE matnr,    " Material Number
         charg        TYPE charg_d,  " Batch Number
         bktxt        TYPE bktxt,    " Header Text Dokumen
       END OF ty_order_link.
```

### 3.3 Penanganan Fallback Terkontrol (`TRACE_FALLBACK`)
- Di lapangan, `MKPF-BKTXT` dapat kosong atau tidak konsisten.
- Jika pencocokan berbasis `BKTXT` gagal, sistem beralih ke **fallback terkontrol** menggunakan kombinasi:
  $$\text{MATNR} + \text{CHARG} + \text{Related Order}$$
- Indikator status trace (Human-Readable):
  - `'Cocok via BKTXT'`: Berhasil dicocokkan sempurna via `BKTXT`.
  - `'Cocok via Batch'`: Berhasil dicocokkan via fallback `MATNR + CHARG + Order`.
  - `'Belum Ada GI 261'`: Tidak ada pergerakan GI 261.
  - `'BKTXT Kosong (Belum GI)'`: `BKTXT` kosong dan tidak ada pergerakan 261.

---

## 4. Konfigurasi `ZMAP_TYPE` (TCODE `SM30`)

> **Catatan Desain:** Sesuai keputusan bisnis, konfigurasi `ZMAP_TYPE` difokuskan **murni untuk `EMAIL_RECIPIENT`**. Nilai Production Line diambil langsung dari karakteristik batch `ZZPRODLINE` (`AUSP-ATWRT`) tanpa memerlukan tabel mapping tambahan.

### 4.1 Pemetaan Penerima Email (`TYPE = EMAIL_RECIPIENT`)
Mendukung multi-penerima (`Multiple TO / CC / BCC`) per production line:

| PROG | TYPE | OPT (Line / DEFAULT) | VALUE | TEXT1 | TEXT2 | TEXT3 | TEXT4 | TEXT5 |
|---|---|---|---|---|---|---|---|---|
| `ZPPR_GI_JR_CLOSING` | `EMAIL_RECIPIENT` | `4` | `001` | `spv.line4` | `@trst.co.id` | `TO` | `SPV Line 4` | *(opsional)* |
| `ZPPR_GI_JR_CLOSING` | `EMAIL_RECIPIENT` | `4` | `002` | `sap.pp` | `@trst.co.id` | `CC` | `PP Dept` | *(opsional)* |
| `ZPPR_GI_JR_CLOSING` | `EMAIL_RECIPIENT` | `Z3` | `001` | `spv.z3` | `@trst.co.id` | `TO` | `SPV Line Z3` | *(opsional)* |
| `ZPPR_GI_JR_CLOSING` | `EMAIL_RECIPIENT` | `DEFAULT` | `001` | `sap.pp` | `@trst.co.id` | `TO` | `PP Dept` | *(opsional)* |
| `ZPPR_GI_JR_CLOSING` | `EMAIL_RECIPIENT` | `DEFAULT` | `002` | `pp.admin` | `@trst.co.id` | `CC` | `Admin PP` | *(opsional)* |

---

## 5. Selection Screen & Perilaku Eksekusi

### 5.1 Matriks Dinamis Screen (`AT SELECTION-SCREEN OUTPUT`)

| Mode | Varian ALV (`P_VARI`) | Blok Email | Test Recipient (`P_TADDR`) | Tindakan Dispatch `CL_BCS` |
|---|---|---|---|---|
| **Report (`P_RPT`)** | Tampil / Aktif | Sembunyi | Non-aktif | Tidak kirim email. Render ALV Grid. |
| **Send Email + Test Run** (`P_MAIL` + `P_TEST`) | Sembunyi | Tampil (`P_TEST = X`) | Non-aktif | Hitung data, grouping per line, buat body & attachment, siapkan recipient. **Tidak panggil `CL_BCS->SEND`.** Default aktif, aman untuk batch job baru. |
| **Send Email + Test Send** (`P_MAIL` + `P_TMAIL`) | Sembunyi | Tampil (`P_TMAIL = X`) | **Wajib Diisi** | Kirim aktual via `CL_BCS`. Abaikan recipient line; **kirim hanya ke `P_TADDR`** dengan prefix subject `[TEST]`. |
| **Send Email Normal** (`P_MAIL` live) | Sembunyi | Tampil (Checkbox kosong) | Non-aktif | Kirim aktual ke seluruh `TO`/`CC`/`BCC` dari `ZMAP_TYPE` per line produksi. |

---

## 6. Standar ALV Layout vs Lampiran Email

Sesuai pola `ZMMI_PO_EMAIL`:
- Varian ALV hanya mengendalikan tampilan GUI user.
- Lampiran email (`.CSV`) **wajib menggunakan susunan 19 kolom baku (fixed schema)**:

| No | Fieldname | Kolom Label | Tipe Data | Output Len | Sumber Data |
|---|---|---|---|---|---|
| 1 | `STATUS_OBS` | Status Observasi | CHAR 30 | 30 | `NO 261` / `DIFF TOLERANCE` / `GI < GR` |
| 2 | `WERKS` | Plant | WERKS_D | 4 | `MSEG-WERKS` |
| 3 | `PRODLINE` | Production Line | CHAR 20 | 20 | `AUSP-ATWRT` (`ZZPRODLINE`) |
| 4 | `JR_NUMBER` | JR Number | CHAR 30 | 20 | `AUSP` / `MCH1` |
| 5 | `MATNR` | Material | MATNR | 18 | `MSEG-MATNR` |
| 6 | `MAKTX` | Material Description | MAKTX | 40 | `MAKT-MAKTX` |
| 7 | `GR_DATE` | GR Date | DATS | 10 | `MKPF-BUDAT` |
| 8 | `AUFNR` | Producing Order | AUFNR | 12 | `MSEG-AUFNR` (Order Pembuat JR) |
| 9 | `MOV_ORDER` | Consuming Order | AUFNR | 12 | `AFPO` / `MSEG` (Order Pemakai) |
| 10 | `CHARG` | Batch | CHARG_D | 10 | `MSEG-CHARG` |
| 11 | `BKTXT` | BKTXT | BKTXT | 25 | `MKPF-BKTXT` |
| 12 | `QTY_GR` | Qty GR/JR | MENGE_D | 15 | `MSEG-MENGE` |
| 13 | `QTY_GI` | Qty GI | MENGE_D | 15 | `MSEG-MENGE` |
| 14 | `QTY_DIFF` | Difference | MENGE_D | 15 | $Qty_{GR} - Qty_{GI}$ |
| 15 | `MEINS` | UoM | MEINS | 5 | `MSEG-MEINS` |
| 16 | `AUART` | Order Type | AUART | 6 | `AUFK-AUART` |
| 17 | `VERID` | Production Version | VERID | 4 | `AFPO-VERID` |
| 18 | `TRACE_STAT` | Status Penelusuran | CHAR 30 | 25 | `Belum Ada GI 261`, `Cocok via BKTXT`, `Cocok via Batch`, `BKTXT Kosong (Belum GI)` |
| 19 | `MAIL_STATUS` | Email Status | CHAR 30 | 30 | `CL_BCS` Dispatch Status |
