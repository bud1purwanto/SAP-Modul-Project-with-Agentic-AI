# Business Process — COA (Certificate of Analysis)

Dokumen ini berisi pengetahuan proses bisnis perusahaan terkait program COA (`ZQMI_COA`, `ZQMR_COA`, dan sejenisnya) yang WAJIB dijadikan acuan saat menganalisis atau memperbaiki logic terkait Inspection Lot, MIC (Master Inspection Characteristic), dan tracing batch/roll.

---

## 1. Mapping MIC → Sumber Inspection Lot

Field `MAPPING` di `ZMAP_COA` menentukan Inspection Lot (QALS) mana yang menjadi sumber value untuk suatu MIC:

| MAPPING | Sumber Inspection Lot |
|---|---|
| `JR Base Film` | Inspection Lot dari **Jumbo Roll (JR) Base Film** |
| `SR Base Film` | Inspection Lot dari **Slit Roll (SR) Base Film** |
| `JR Converting` | Inspection Lot dari **Jumbo Roll (JR) Converting** |
| `SR Converting` | Inspection Lot dari **Slit Roll (SR) Converting** |

Di kode (`FORM GET_MIC` pada `ZQMI_COA_F01`), keempat mapping ini masing-masing di-resolve ke variable lot: `LOT_JR_BASE`, `LOT_SR_BASE`, `LOT_JR_CONV`, `LOT_SR_CONV` (di-set oleh `FORM GET_TRACED_LOTS`).

---

## 2. Flow Produksi Normal (tanpa Change Grade)

```
Raw Material → JR Base Film → SR Base Film → JR Converting → SR Converting → Packing → Jual
```

Artinya: satu batch mengalir linear dari Raw Material hingga Slit Roll Converting tanpa ganti nomor batch tambahan di tengah proses. Tracing batch (`GET_TRACED_LOTS` dan form-form pendukungnya seperti `GET_VALID_ORDER_FROM_MSEG`, `GET_VALID_COMPONENT_FROM_MSEG`) mengikuti hierarki produksi ini melalui pergerakan barang (`MSEG`, movement type 101/102 untuk goods receipt production order, 261/262 untuk goods issue/reversal komponen).

---

## 3. Flow dengan Change Grade

Change Grade = proses re-batching (biasanya karena reklasifikasi kualitas/grade material) yang **memutus** rantai batch original dan menghasilkan **batch baru**. Titik Change Grade bisa terjadi di dua tempat dalam flow:

```
Raw Material → JR Base Film → SR Base Film → [Batch baru jika di-Change Grade] → JR Converting → SR Converting → [Batch baru jika di-Change Grade] → Packing → Jual
```

Implikasi teknis:
- Saat tracing mundur dari suatu batch ke batch induknya (mother batch), rantai `MSEG`/`ZBATCHISTORY` bisa **terputus** di titik Change Grade karena batch baru tidak selalu terhubung langsung via movement 101/102/261/262 standar ke batch produksi sebelumnya.
- Inilah alasan kenapa `ZQMI_COA_F01` punya mekanisme **FALLBACK WRAPPER** (di `GET_TRACED_LOTS`, menggunakan `GET_VALID_ORDER_FROM_MSEG` + `GET_VALID_COMPONENT_FROM_MSEG` sebagai jalur alternatif) untuk "melompati" (bypass) titik Change Grade dan tetap menemukan Inspection Lot dari batch Base Film/Converting yang benar di baliknya.
- Tabel `ZBATCHISTORY` (field `CHARG`/`NCHARG`) menyimpan histori relasi batch lama → batch baru akibat Change Grade maupun proses re-batching lain, dan digunakan oleh `FORM GET_ORIGINAL_BATCH` (mundur ke batch tertua) dan `FORM GET_NEWEST_BATCH` (maju ke batch terbaru/sibling terkini).

---

## 4. Catatan untuk Analisis/Debugging

- Saat sebuah MIC menunjukkan value kosong/'-' padahal seharusnya ada, periksa dulu apakah root cause-nya **tracing lot yang salah/terputus** (kemungkinan besar karena Change Grade), bukan otomatis diasumsikan bug logic value-determination.
- Saat sebuah MIC menunjukkan value yang salah/tertukar dengan MIC lain, itu kemungkinan besar **bug di resolusi MERKNR/value-determination** (lihat kasus MERKNR bleed yang sudah diperbaiki di `ZQMI_COA_F01`), bukan masalah tracing lot.
- `SAABSTTR` dan MIC level SR Base Film lainnya butuh Inspection Lot dari batch SR Base Film ITU SENDIRI — kalau batch tsb tidak pernah punya Inspection Lot sendiri (SR-level QC lot tidak pernah dibuat), value akan blank secara sah (bukan bug), sementara MIC level JR Base Film tetap bisa terisi karena diwariskan lewat `LOT_JR_BASE`.
