# MES Control Tower - SAP ABAP Technical Documentation

## Subproject Info
- **Directory**: `SAP ABAP Consultant/subproject/MES_CONTROL_TOWER`
- **Scope**: Production Planning & Material Availability Master Data Download
- **Function Module**: `ZPP_MD_DL`
- **Function Pool**: `SAPLZPP_MD`
- **Include**: `LZPP_MDU01`
- **Target Server**: Sandbox New Company (`TRS` / `192.168.6.243`)

---

## 1. Requirement & Scope Matrix

Berdasarkan pembagian PIC di task MES Control Tower:
- **MAST** (Material to BOM Link) -> Mode: `MAST` / `STKO`
- **MKAL** (Production Versions) -> Mode: `MKAL`
- **STPO** (BOM Items / Components) -> Mode: `STPO` / `STKO`

---

## 2. Table Fields & Date Fields Analysis (DDIC DD03L)

Semua field bertipe `DATS` (Date) yang bernilai awal `00000000` / blank telah diformat otomatis menjadi `'19000101'` untuk mencegah error parsing JSON/REST/RFC client pada sistem MES/Downloader.

### A. Tabel `MAST`
- `ANDAT` (Date record created)
- `AEDAT` (Last changed date)

### B. Tabel `STKO` & `STPO` & `STAS`
- `DATUV` (Valid-from date)
- `ANDAT` (Date record created)
- `AEDAT` (Last changed date)
- `DVDAT` (Date of last check)

### C. Tabel `MKAL`
- `ADATU` (Valid-from date)
- `BDATU` (Valid-to date)
- `PRDAT` (Date of last check)

---

## 3. Function Module Interface `ZPP_MD_DL`

### Import Parameters
- `MODE` (TYPE `CHAR10`): Nilai yang diterima: `'MAST'`, `'MKAL'`, `'STPO'`, `'STKO'`.
- `MAT_GROUP` (TYPE `CHAR120`, OPTIONAL): Filter kode `MATKL` dipisahkan dengan koma (contoh: `'FG,SFG'`).

### Tables
- `MAST` (STRUCTURE `MAST` OPTIONAL)
- `STKO` (STRUCTURE `STKO` OPTIONAL)
- `STPO` (STRUCTURE `STPO` OPTIONAL)
- `STAS` (STRUCTURE `STAS` OPTIONAL)
- `MKAL` (STRUCTURE `MKAL` OPTIONAL)

### Exceptions
- `MODE_IS_NOT_AVAILABLE`
- `PAR_MAT_GROUP_IS_NULL`
- `DATA_NOT_FOUND`

---

## 4. Status Update di Sandbox
- Function Module `ZPP_MD_DL` (Include `LZPP_MDU01`) sudah berhasil diperbarui di server **Sandbox New Company (TRS)** via `Z_RFC_PROGRAM_UPDATE`.
