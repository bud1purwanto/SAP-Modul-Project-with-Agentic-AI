# Code Review: Program COA Automation (ZMAP_COA, ZQMR_COA, ZQMI_COA, ZQMR_PENDING_BARRIER)

**Tanggal review:** 8 Juli 2026
**Server sumber:** Sandbox New Company (TRS) — satu-satunya server tempat 3 dari 4 program ditemukan
**Referensi requirement:** COA Project.md (MoM Otomatisasi COA)

---

## 0. Catatan Penting Sebelum Membaca Hasil Review

`ZQMR_PENDING_BARRIER` **tidak ditemukan** di semua server yang saya cek: Development AIX, Development Windows, QA, Sandbox Build Competence, maupun Sandbox New Company. Saya belum cek ke Production karena itu perlu konfirmasi terpisah dari Anda dan berisiko terhadap data live — dan program ini sifatnya "pending/baru", jadi kecil kemungkinan sudah ditransport ke Production.

Ini penting karena `ZQMR_PENDING_BARRIER` kemungkinan besar adalah program yang dimaksud MoM sebagai **"Modul Baru"** untuk merekam hasil inspeksi *Slitt Roll Barrier* tanpa Cancel UD (poin Goal Proyek #2). Tanpa program ini, saya tidak bisa memverifikasi apakah goal utama proyek (menghilangkan Cancel UD untuk input barrier) benar-benar sudah tercapai. Mohon konfirmasi nama program yang benar atau lokasinya.

Review di bawah ini murni berdasarkan 3 program yang berhasil dibaca: `ZMAP_COA`, `ZQMR_COA`, `ZQMI_COA` (`ZQMI_CERTIFICATE` + include `_TOP`, `_F01`, `_F02`).

---

## 1. Ringkasan Fungsi Tiap Program

| Program | Fungsi | Tcode/akses |
|---|---|---|
| `ZMAP_COA` | Maintain tabel mapping `ZMAP_COA` (Material + MIC + Customer → Method + Mapping Source). Support Create/Edit/Delete/Undelete + upload dari file text. | SE38 custom report |
| `ZQMR_COA` | Laporan ALV read-only: menampilkan hasil inspeksi per DO/batch berdasarkan mapping, dengan logic penelusuran lot (JR/SR, Base Film/Converting). | SE38 custom report |
| `ZQMI_COA` (`ZQMI_CERTIFICATE`) | Transaksi utama pembuatan & cetak COA: ambil data, agregasi/average, override nilai manual (dengan log), cetak via smartform `ZQMF_COA`. | SE38 custom report, dipakai QA |
| `ZQMR_PENDING_BARRIER` | **Tidak ditemukan** — kemungkinan modul barrier baru sesuai MoM | — |

---

## 2. Kesesuaian dengan Source Mapping Matrix (MoM Bag. 2)

MoM mensyaratkan 4 sumber data: Mechanical/Optical (After Jumbo Roll), Slitt Roll (After Slitting), Barrier Properties Converting (modul baru).

Di `GET_MIC` (ada di `ZQMR_COA` dan `ZQMI_COA_F01`), mapping benar-benar dicek berdasarkan teks `IT_ZMAP-MAPPING`: `'SR Base Film'`, `'JR Base Film'`, `'SR Converting'`, `'JR Converting'` — ini **sudah sesuai** dengan instruksi MoM ("programmer perlu membuat pemetaan formula... untuk material film making dan converting").

Namun **Barrier Properties belum punya kategori mapping sendiri**. Yang ada hanyalah pengecualian berbasis nama MIC (`MIC CS 'MVTR'` atau `'OTR'`), yang mencari nilai langsung dari lot SR Converting/JR Converting yang sudah ada — bukan dari "Modul Baru" terpisah yang disebut MoM. Ini konsisten dengan tidak ditemukannya `ZQMR_PENDING_BARRIER`: sepertinya modul barrier khusus ini **belum terintegrasi** ke alur `ZQMI_COA`/`ZQMR_COA`, program masih mengandalkan lot inspeksi yang sudah ada (artinya masih tergantung skema lama yang menurut MoM justru bermasalah karena butuh Cancel UD).

**Gap:** Belum ada bukti bahwa proses "tanpa Cancel UD" untuk input barrier sudah terhubung ke pipeline COA.

---

## 3. Validasi 8 Skenario

### 1. Barrier multiple cycles
Ditemukan logic eksplisit: untuk MIC `MVTR`/`OTR`, program `SELECT ... FROM QASE WHERE PRUEFLOS/MERKNR`, lalu `SORT BY PROBENR DESCENDING` dan ambil baris pertama (`READ TABLE INDEX 1`) — ini mengambil **cycle dengan PROBENR tertinggi** sebagai representasi "cycle terakhir", sesuai requirement MoM (nilai cycle terakhir yang dipakai).

**Catatan risiko:** logic ini berasumsi PROBENR selalu naik sesuai urutan cycle input. Ini asumsi yang wajar untuk QASE (Single Result), tapi belum saya verifikasi terhadap data live apakah PROBENR benar-benar merepresentasikan urutan cycle 1-2-3 secara konsisten (misal jika ada cycle yang diinput ulang/dibatalkan). Sarankan uji dengan 1 lot yang punya 3 cycle riil sebelum go-live.

### 2. Change grade SR BF (Base Film)
Ditelusuri lewat `GET_ORIGINAL_BATCH`/`GET_NEWEST_BATCH` yang membaca tabel `ZBATCHISTORY` (mapping CHARG lama↔baru). Ini selaras dengan proses `PP_PE-UM42 Adjustment Extra Length` yang mengubah grade & kemungkinan me-rename batch. **Tampak ditangani**, dengan asumsi `ZBATCHISTORY` konsisten terisi setiap kali ada perubahan grade.

### 3. Change grade SR Converting
Pola sama seperti SR BF, diterapkan pada `LOT_SR_CONV` sebelum fallback ke `ZQM_GET_BATCH_JR_BY_SR`. **Tampak ditangani** dengan mekanisme yang sama.

### 4. Secondary Slitting
Tidak ada logic khusus bernama "secondary slitting". Yang ada adalah `GET_JR_SIBLING_LOT` — mekanisme heuristik yang menebak nomor roll "sibling" dengan pola **±10 dari sequence number** pada nomor roll (parsing string, bukan link database langsung by production order/BOM). Ini dipakai sebagai fallback ketika lot resmi JR/SR tidak ditemukan langsung.

**Risiko (Important):** pendekatan menebak sibling roll dari pola penomoran string cukup rapuh — bisa salah kalau: (a) penomoran roll tidak strictly sequential, (b) rentang antar roll re-slitting lebih dari 10, atau (c) ada perubahan konvensi penomoran roll di masa depan. Ini bukan `INSPECTION_LOT_UPDATE` BADI, jadi bukan modifikasi core, tapi logic custom ini sendiri berisiko salah tebak lot untuk skenario secondary slitting yang kompleks. Sarankan divalidasi dengan kasus riil secondary slitting.

### 5. Material Aksen dan Non-Aksen
Tidak ditemukan logic pembeda eksplisit "aksen vs non-aksen" di ketiga program. `ZZTYPE` (dari characteristic `ZZCODE`) dipakai sebagai filter umum "Film Type", tapi tidak ada percabangan logic khusus aksen. Karena `ZMAP_COA` di-key oleh Material (bukan Film Type generik), asumsinya material aksen dan non-aksen otomatis punya baris mapping berbeda di `ZMAP_COA` — ini **kemungkinan cukup**, asalkan tim QA memang mengisi mapping terpisah per kode material aksen. Tidak ada validasi otomatis di program untuk memastikan hal ini — murni tergantung kelengkapan data master `ZMAP_COA`.

### 6. Banyak DO sekali cetak
**Konflik langsung dengan kode existing.** Di `ZQMI_COA_F02`, form `EXEC`:
```abap
CSTAT = LINES( T_DETAIL ).  " T_DETAIL = unique VBELN dari baris terpilih
...
IF CSTAT NE 1.
  MESSAGE 'Pilih 1 ODO!' TYPE 'I'.
```
Kode ini **secara eksplisit menolak** proses jika lebih dari 1 nomor ODO/DO (VBELN) terpilih. Artinya skenario "banyak DO sekali cetak" **belum didukung** — sebaliknya, program saat ini didesain untuk memaksa 1 DO per proses cetak.

**Ini butuh keputusan desain**: apakah requirement baru "banyak DO sekali cetak" berarti perlu perubahan besar di `EXEC`/`F_PRINT` (loop per DO, generate multiple COA sekaligus), atau cukup batch-print terpisah per DO tapi dipicu sekali? Perlu klarifikasi ke user/business sebelum development, karena ini legitimately butuh redesign form `EXEC`.

### 7. 1 DO banyak material (average)
Ada **dua logic yang saling bertentangan**:
- Di `GET_DATA` (`ZQMI_COA_F01`), ada blok "Enhancement: Aggregate/Average MIC results for identical Material" yang meng-average `MICMIT` untuk baris dengan `VBELN` + `MATNR` + `MIC` yang **sama** (multi-batch, 1 material). Ini bekerja untuk kasus banyak *batch* dari material yang **sama**.
- Tapi di form `EXEC` (`ZQMI_COA_F02`):
```abap
MSTAT = LINES( T_DETAIL1 ).  " T_DETAIL1 = unique MATNR
...
ELSEIF MSTAT NE 1.
  MESSAGE 'Tipe film tidak boleh berbeda!' TYPE 'I'.
```
Baris ini **memblokir proses** jika ada lebih dari 1 `MATNR` (material) berbeda dalam pilihan. Artinya rata-rata lintas-**material berbeda** (bukan lintas-batch material sama) justru **tidak diizinkan** untuk dicetak sekaligus.

**Perlu klarifikasi terminologi ke Anda:** apakah skenario #7 yang dimaksud adalah "1 DO, banyak *batch* dari material yang sama, di-average" (sudah didukung), atau "1 DO, benar-benar banyak *kode material* berbeda, di-average" (saat ini diblokir oleh validasi `MSTAT`)? Kalau yang dimaksud kasus kedua, ini juga butuh perubahan logic di `EXEC`.

### 8. Ketika ubah value di Print Certificate
**Sudah diimplementasikan dengan baik.** Alurnya:
1. User edit nilai `CMICMIT` di ALV preview.
2. Klik `SAVE` → form `SAVE_ADD_INFO` membandingkan nilai baru vs `ZLOG_COA` (atau nilai asli QM jika belum ada override), lalu **menampilkan popup konfirmasi** ("Ada perubahan nilai MIC. Apakah Anda yakin ingin menyimpan perubahan ini ke log?").
3. Jika Ya → insert record baru ke `ZLOG_COA` (dengan `SEQ` naik, jadi ada histori), tandai record lama `DELETION = 'X'`.
4. Ada validasi pengaman di `EXEC`: kalau ada baris yang sudah diubah tapi belum di-Save, sistem menolak lanjut cetak ("Harap Save perubahan nilai (Preview) terlebih dahulu!").

Ini pola audit-trail yang solid — perubahan manual tercatat, bukan overwrite langsung ke tabel QM asli. **Sesuai kaidah "no direct modification ke data inspeksi asli"**, dan cukup selaras dengan semangat MoM soal traceability data (menghindari masalah "data hasil copy tidak bisa dibedakan dari inspeksi aktual").

---

## 4. Temuan Tambahan (di luar 8 skenario)

**Penting — Validasi konflik multi-sampel Barrier (MoM Bag. 3) belum ditemukan implementasinya.** MoM secara spesifik meminta:
- Deteksi otomatis ketika 1 Jumbo Roll punya >1 hasil inspeksi barrier dari sampel SR berbeda.
- Popup warning dengan teks spesifik yang disebutkan di MoM.
- QA memilih nilai (rule: ambil nilai terendah).
- Auto-overwrite ke **semua** Slitt Roll dalam Jumbo Roll yang sama.

Mekanisme `ZLOG_COA` yang ada saat ini sifatnya **override manual per PRUEFLOS + MIC + KUNNR** (1 lot spesifik), bukan deteksi otomatis konflik antar-sampel maupun propagasi otomatis ke seluruh SR sibling dalam 1 JR. Popup konfirmasi yang ada ("Ada perubahan nilai MIC...") adalah konfirmasi simpan generik, bukan popup validasi konflik spesifik yang diminta MoM. **Ini kemungkinan besar memang bagian dari `ZQMR_PENDING_BARRIER` yang belum saya temukan** — jadi belum bisa dipastikan gap atau sudah ada di tempat lain.

**Minor — Form `CANCEL_UD` (BDC ke tcode QA12) masih ada di `ZQMI_COA_F02`.** Ini kontradiktif dengan salah satu goal MoM ("mengotomatiskan proses inspeksi barrier... tanpa perlu melakukan Cancel UD"). Perlu dicek apakah form ini masih dipanggil di alur aktif manapun, atau sisa kode lama yang belum dibersihkan (dead code). Kalau masih aktif dipanggil untuk kebutuhan lain (bukan barrier), itu tidak masalah — tapi kalau ini bagian dari alur barrier lama yang seharusnya sudah digantikan modul baru, berarti proses lama belum benar-benar dihilangkan.

**Minor — Tidak ada uji dampak modul lain (MM/PP/SD/FI).** Karena `ZQMI_COA`/`ZQMR_COA` sifatnya read-only report + cetak sertifikat (tidak melakukan posting UD, stock movement, dsb.), risiko ke modul lain relatif rendah. Satu-satunya titik yang menyentuh transaksi adalah `CANCEL_UD` (poin di atas) yang menyentuh QA12/UD — ini **berdampak ke MM** (status stok bisa berubah kalau UD dibatalkan). Perlu dipastikan form ini tidak dipanggil sembarangan dari alur COA biasa.

---

## 5. Ringkasan Status per Skenario

| # | Skenario | Status |
|---|---|---|
| 1 | Barrier multiple cycles | Sudah ada, cek ulang asumsi urutan PROBENR |
| 2 | Change grade SR BF | Sudah ada (via ZBATCHISTORY) |
| 3 | Change grade SR Converting | Sudah ada (pola sama) |
| 4 | Secondary Slitting | Ada, tapi heuristik rapuh (sibling ±10) — perlu uji kasus riil |
| 5 | Material aksen vs non-aksen | Tidak ada logic eksplisit — bergantung kelengkapan ZMAP_COA |
| 6 | Banyak DO sekali cetak | **Belum didukung** — kode aktif menolak >1 DO |
| 7 | 1 DO banyak material (average) | **Ambigu/berpotensi konflik** — average jalan untuk multi-batch material sama, tapi diblokir untuk multi-material berbeda |
| 8 | Ubah value di Print Certificate | Sudah diimplementasikan dengan baik (audit trail ZLOG_COA) |

---

## 6. Rekomendasi Langkah Berikutnya

1. Konfirmasi lokasi/nama program `ZQMR_PENDING_BARRIER` yang benar — ini krusial karena menentukan apakah goal utama proyek (barrier tanpa Cancel UD + validasi konflik multi-sampel) sudah tercapai atau memang belum dibangun.
2. Klarifikasi requirement skenario #6 dan #7 ke business/QA — apakah desain saat ini (1 DO per cetak, tolak multi-material berbeda) memang sudah tidak relevan dan perlu diubah, atau istilah yang dipakai user berbeda maksud dengan yang sudah diimplementasikan.
3. Uji fungsional skenario #1 dan #4 dengan data riil sebelum dianggap selesai, karena keduanya bergantung pada asumsi pola data (urutan PROBENR, penomoran roll sequential).
4. Klarifikasi status form `CANCEL_UD` — dead code atau masih dipakai aktif.
