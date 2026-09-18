# ARSITEKTUR RESMI SMART FORMS COA DINAMIS (LEBAR KOLOM DISAMARATAKAN)

Dokumen ini adalah acuan arsitektur resmi untuk pencetakan Certificate of Analysis (COA) dinamis pada program driver `ZQMI_COA` / `ZQMI_COA_F01` dan Smart Forms terkait dengan sistem **Lebar Kolom Standar Rata (Equalized Width Distribution)**.

---

## 1. STRUKTUR & PEMBAGIAN SMART FORMS (SEPARATION OF CONCERNS)

Pencetakan COA dibagi secara modular menjadi 2 halaman cetak (1 berkas Spool):

### A. Halaman 1: `ZQMF_COA` (Sertifikat COA - Murni MIC Saja)
* **Orientasi:** PORTRAIT (Hanya 1 Halaman).
* **Fungsi:** Khusus mencetak Header Delivery/Customer, informasi produk, tabel karakteristik pengujian (*Inspection Lot MIC / Properties*), dan tanda tangan QA.
* **Aturan:** Bersih murni dari tabel Batch List.

### B. Halaman 2: Standarisasi Lebar Rata Kolom Dinamis (`P1..P8` & `L9..L14`)
Semua kolom pada setiap baris dibagi rata secara presisi memenuhi seluruh lebar kertas ($18.00\text{ cm}$ Portrait / $27.00\text{ cm}$ Landscape) sehingga **bebas menukar urutan sequence apa pun tanpa merusak simetri tabel**:

#### **Tier Portrait ($18.00\text{ cm}$ Total) — 1 s/d 8 Kolom:**
* **`ZQMF_COA_BATCH_P1` (1 Kolom):** Sel $18.00\text{ cm}$.
* **`ZQMF_COA_BATCH_P2` (2 Kolom):** Sel $9.00, 9.00\text{ cm}$.
* **`ZQMF_COA_BATCH_P3` (3 Kolom):** Sel $6.00, 6.00, 6.00\text{ cm}$.
* **`ZQMF_COA_BATCH_P4` (4 Kolom):** Sel $4.50, 4.50, 4.50, 4.50\text{ cm}$.
* **`ZQMF_COA_BATCH_P5` (5 Kolom):** Sel **$3.60, 3.60, 3.60, 3.60, 3.60\text{ cm}$** $\rightarrow$ **DO `85004908` (`DOM_DEFAUL`)**.
* **`ZQMF_COA_BATCH_P6` (6 Kolom):** Sel **$3.00, 3.00, 3.00, 3.00, 3.00, 3.00\text{ cm}$**.
* **`ZQMF_COA_BATCH_P7` (7 Kolom):** Sel **$2.57, 2.57, 2.57, 2.57, 2.57, 2.57, 2.58\text{ cm}$** $\rightarrow$ **DO `0084000047` (`SRAABI`)**.
* **`ZQMF_COA_BATCH_P8` (8 Kolom):** Sel **$2.25, 2.25, 2.25, 2.25, 2.25, 2.25, 2.25, 2.25\text{ cm}$**.

#### **Tier Landscape ($27.00\text{ cm}$ Total) — 9 s/d 14 Kolom:**
* **`ZQMF_COA_BATCH_L9` (9 Kolom):** Sel $3.00\text{ cm}$ per kolom.
* **`ZQMF_COA_BATCH_L10` (10 Kolom):** Sel **$2.70\text{ cm}$ per kolom** $\rightarrow$ **DO `0085000140` (`SRACLI`)**.
* **`ZQMF_COA_BATCH_L11` (11 Kolom):** Sel $2.45\text{ cm}$ per kolom.
* **`ZQMF_COA_BATCH_L12` (12 Kolom):** Sel $2.25\text{ cm}$ per kolom.
* **`ZQMF_COA_BATCH_L13` (13 Kolom):** Sel $2.08\text{ cm}$ per kolom.
* **`ZQMF_COA_BATCH_L14` (14 Kolom):** Sel $1.93\text{ cm}$ per kolom.

---

## 2. KEUNGGULAN SISTEM LEBAR RATA
1. **Bebas Tukar Sequence:** Karena semua kolom di layout tersebut lebarnya sama, urutan kolom dapat diubah sesuka hati di `ZQM001` tanpa khawatir ada kolom yang terpotong.
2. **0 Kotak Kosong:** Selalu memenuhi $18.00\text{ cm}$ di Portrait dan $27.00\text{ cm}$ di Landscape.
3. **Simetris & Estetis:** Layout tabel tampak rapi dan berstandar seragam.
