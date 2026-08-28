## Imported Claude Cowork project instructions

SAP ABAP Consultant

### COA Dynamic Table & Smart Forms Architecture Rule:
Pastikan selalu membaca dan mematuhi arsitektur pada `subproject/COA/ARCHITECTURE_COA_DYNAMIC.md` saat mengembangkan atau memperbaiki COA:
1. `ZQMF_COA` murni hanya untuk Page 1 (Sertifikat / MIC Inspection Characteristics).
2. `ZQMF_COA_BATCH_POTRAIT` khusus untuk Lampiran Batch List (Portrait <= 8 kolom).
3. `ZQMF_COA_BATCH_LANDSCAPE` khusus untuk Lampiran Batch List (Landscape > 8 kolom).
4. Mapping dan ukuran kolom dinamis sesuai tabel `ZQM_COA_CUST_COL`.
5. Contoh verifikasi data uji:
   - DO `85004908` (6 Kolom - DOM_DEFAUL) -> ZQMF_COA + ZQMF_COA_BATCH_POTRAIT (2 Hal Portrait)
   - DO `0084000047` (7 Kolom - SRAABI) -> ZQMF_COA + ZQMF_COA_BATCH_POTRAIT (2 Hal Portrait)
   - DO `0085000140` (10 Kolom - SRACLI) -> ZQMF_COA + ZQMF_COA_BATCH_LANDSCAPE (Page 1 Port + Page 2 Land)

