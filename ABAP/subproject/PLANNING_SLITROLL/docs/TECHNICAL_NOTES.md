# ZPPR_PLANNING_SLITROLL

## Dasar proses

- RAG `PPP02 Planning of Slit Roll`: PPIC menyusun jadwal produksi Slit Roll dari kebutuhan sales order dan membuat kombinasi order dengan spesifikasi yang sama.
- Transaction `ZPP003P` mengarah ke program `ZPPC_UPLOAD_SLITROLL`.
- Pada proses tersebut, vendor batch (`MCH1-LICHA`) diisi original order.
- Combine order ditelusuri dari original order melalui `AFPO-MILL_OC_AUFNR_U`.
- Storage location (`LGORT`) is taken from the original-order `AFPO` item.
- Field planning mengikuti sumber utama `AUFK`, `AFKO`, `AFPO`, dan `MCH1` seperti program `ZTPPI_PLANNINGDATA_AGS` yang dipanggil oleh proses upload.

## Mapping

Program membaca `ZMAP_TYPE` dengan:

- `PROG = 'ZPPR_PLANNING_SLITROLL'`
- `TYPE = 'ORDER TYPE'`
- `OPT = 'SR ORIGINAL'` atau `OPT = 'SR COMBINE'`
- `VALUE = AUART`

Mapping awal disalin dari mapping aktif milik `ZPPI_COHVPI` untuk kedua grup SR tersebut.

## Batch characteristics

The report resolves characteristic internal numbers from `CABN` once, then reads
the required `AUSP` values in bulk for the selected batch objects. It displays all
characteristics populated by `ZPPC_UPLOAD_SLITROLL`, including the material-class
dependent length characteristic (`ZZLENGTH` or `ZZLENGTHSHT`).

Numeric `ATFLV` values are converted through a packed-decimal field and formatted
with the characteristic decimal places from `CABN-ANZDZ`. This prevents scientific
notation in the generic character columns of the ALV.

## ALV layout

The layout parameter follows `ZMMI_PO_EMAIL`: it loads the user's default layout
during initialization, falls back to an available user/global layout, provides F4
selection, and validates a manually entered layout before report execution.

## Index alignment

- `ZMAP_TYPE`: primary-key prefix `TCODE, PROG, TYPE`.
- `AUFK`, `AFPO`, and `AFKO`: order joins use `AUFNR` keys.
- Original-to-combine lookup: `AFPO-Z01/Z04` on `MILL_OC_AUFNR_U`.
- Batch lookup: `MCH1-Z01` on `MATNR, LICHA`; the batch selection can also
  use the `CHARG` indexes.
- Characteristic lookup: `AUSP-N3` on `OBJEK, KLART, ATINN`.

The order-created-date filter has no dedicated AUFK index in TRS. The mapped
order type (`AUFK-C`) is therefore the indexed driver when an explicit order
number is not supplied.
