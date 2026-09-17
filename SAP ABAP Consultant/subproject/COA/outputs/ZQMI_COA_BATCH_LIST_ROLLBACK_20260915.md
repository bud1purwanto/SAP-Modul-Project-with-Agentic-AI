# Rollback ZQMI_COA Batch List — TRS

Baseline PF-STATUS aktif diambil melalui `RS_CUA_INTERNAL_FETCH` sebelum perubahan.

Untuk rollback perubahan toolbar secara minimal, hapus hanya entry berikut dari CUA
program `ZQMI_COA`, kemudian jalankan `RS_CUA_INTERNAL_WRITE` state `A` dan
`RS_CUA_INTERNAL_GENERATE`:

- `FUN`: `CODE = BATLIST`, `TEXTNO = 001`
- `PFK`: `CODE = 000002`, `PFNO = 21`, `FUNCODE = BATLIST`
- `BUT`: `PFK_CODE = 000002`, `CODE = 0001`, `NO = 04`, `PFNO = 21`
- `SET`: `STATUS = PF0200`, `FUNCTION = BATLIST`

Rollback source:

- Hapus cabang `WHEN 'BATLIST'` dari `ZQMI_COA_F02`.
- Hapus form `DOWNLOAD_BATCH_LIST` dan `XML_ESCAPE` dari `ZQMI_COA_F01`.

Source sebelum/ sesudah perubahan juga tercatat pada version management SAP oleh
mekanisme update repository TRS.
