# PO Email Excel Attachment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mengganti lampiran CSV pada `ZMMI_PO_EMAIL` menjadi file Excel SpreadsheetML `.xls` yang rapi dan menampilkan tanggal Indonesia pada subject, nama lampiran, serta header worksheet.

**Architecture:** Memakai pola `FORM BUILD_XLS` dari `ZPPI_COHVPI`: membangun SpreadsheetML 2003 dalam `STRING`, mengonversinya menjadi `SOLIX_TAB`, lalu melampirkannya lewat `CL_DOCUMENT_BCS->ADD_ATTACHMENT`. Data per kelompok approver tetap dikumpulkan seperti sekarang; satu grup menerima satu email dan satu file Excel hanya untuk PO grup tersebut.

**Tech Stack:** SAP ECC 6.0 EHP6, ABAP 7.31, `CL_BCS`, `CL_DOCUMENT_BCS`, `HR_KR_STRING_TO_XSTRING`, `SCMS_XSTRING_TO_BINARY`, SpreadsheetML 2003.

## Global Constraints

- ABAP Release 7.31: tanpa inline `DATA(...)`, `VALUE`, string template, dan Open SQL dengan `@`.
- Perubahan source program hanya disimpan di `sandbox-new` (TRS) dengan `Z_RFC_PROGRAM_UPDATE`.
- Tidak ada direct update tabel standar SAP.
- `P_TEST = 'X'` tidak boleh mengirim email atau membuat perubahan bisnis.
- Lampiran memakai SpreadsheetML `.xls`, bukan CSV dan bukan library baru.

---

### Task 1: Tambah format tanggal Indonesia dan metadata attachment

**Files:**
- Modify: `C:\Users\Lenovo\Claude\Projects\SAP ABAP Consultant\ZMMI_PO_EMAIL.abap:155-169, 730-820, 938-948`
- Test: syntax check `ZMMI_PO_EMAIL` di TRS melalui `RFC_ABAP_INSTALL_AND_RUN`

**Interfaces:**
- Produces: `FORM F_FORMAT_DATE_ID USING P_DATE TYPE SY-DATUM CHANGING P_TEXT TYPE STRING.`
- Consumes: `SY-DATUM` pada `FORM F_MAIL_SEND`.

- [ ] **Step 1: Tambah deklarasi buffer SpreadsheetML**

```abap
DATA: GV_XLS_XML TYPE STRING,
      GV_DATE_ID TYPE STRING.
```

- [ ] **Step 2: Tambah form tanggal Indonesia**

```abap
FORM F_FORMAT_DATE_ID USING P_DATE TYPE SY-DATUM
                      CHANGING P_TEXT TYPE STRING.
  DATA: LV_DAY   TYPE C LENGTH 2,
        LV_MONTH TYPE C LENGTH 2,
        LV_YEAR  TYPE C LENGTH 4,
        LV_NAME  TYPE STRING.

  LV_DAY   = P_DATE+6(2).
  LV_MONTH = P_DATE+4(2).
  LV_YEAR  = P_DATE(4).
  CASE LV_MONTH.
    WHEN '01'. LV_NAME = 'Januari'.
    WHEN '02'. LV_NAME = 'Februari'.
    WHEN '03'. LV_NAME = 'Maret'.
    WHEN '04'. LV_NAME = 'April'.
    WHEN '05'. LV_NAME = 'Mei'.
    WHEN '06'. LV_NAME = 'Juni'.
    WHEN '07'. LV_NAME = 'Juli'.
    WHEN '08'. LV_NAME = 'Agustus'.
    WHEN '09'. LV_NAME = 'September'.
    WHEN '10'. LV_NAME = 'Oktober'.
    WHEN '11'. LV_NAME = 'November'.
    WHEN '12'. LV_NAME = 'Desember'.
  ENDCASE.
  CONCATENATE LV_DAY LV_NAME LV_YEAR INTO P_TEXT SEPARATED BY SPACE.
ENDFORM.
```

- [ ] **Step 3: Pakai tanggal yang sama di subject dan attachment**

```abap
PERFORM F_FORMAT_DATE_ID USING SY-DATUM CHANGING GV_DATE_ID.
CONCATENATE 'PO Menunggu Persetujuan -' GV_DATE_ID
            INTO LV_SUBJ SEPARATED BY SPACE.
CONCATENATE 'Detail PO -' GV_DATE_ID INTO LV_ATTS
            SEPARATED BY SPACE.
```

- [ ] **Step 4: Syntax check**

Run `SYNTAX-CHECK FOR` source `ZMMI_PO_EMAIL` on sandbox-new.

Expected: `SYNTAX_OK`.

### Task 2: Buat worksheet Excel bergaya ZPPI_COHVPI

**Files:**
- Modify: `C:\Users\Lenovo\Claude\Projects\SAP ABAP Consultant\ZMMI_PO_EMAIL.abap:670-725, 730-820`
- Test: `P_TEST = 'X'` dan syntax check di TRS.

**Interfaces:**
- Produces: `FORM F_BUILD_XLS USING P_OPT TYPE ZMAP_TYPE-OPT P_DATE TYPE STRING CHANGING P_XML TYPE STRING.`
- Consumes: `LT_MAIL`, exception flag/reason, dan date text hasil `F_FORMAT_DATE_ID`.

- [ ] **Step 1: Buat SpreadsheetML dengan style dan kolom tetap**

```abap
APPEND '<Style ss:ID="h"><Font ss:Bold="1" ss:Color="#FFFFFF"/>' TO LT_X.
APPEND '<Interior ss:Color="#1F4E78" ss:Pattern="Solid"/>' TO LT_X.
APPEND '<Alignment ss:Horizontal="Center" ss:Vertical="Center"/>' TO LT_X.
APPEND '</Style>' TO LT_X.
APPEND '<Style ss:ID="warn"><Interior ss:Color="#FCE4D6" ss:Pattern="Solid"/></Style>' TO LT_X.
APPEND '<Style ss:ID="num"><NumberFormat ss:Format="#,##0.00"/></Style>' TO LT_X.
APPEND '<Column ss:Width="100"/><Column ss:Width="125"/>' TO LT_X.
APPEND '<Column ss:Width="95"/><Column ss:Width="55"/>' TO LT_X.
APPEND '<Column ss:Width="95"/><Column ss:Width="260"/>' TO LT_X.
```

- [ ] **Step 2: Tambah title, tanggal, header dan data per grup**

```abap
APPEND '<Row><Cell ss:MergeAcross="5"><Data ss:Type="String">Detail PO Menunggu Persetujuan</Data></Cell></Row>' TO LT_X.
CONCATENATE '<Row><Cell ss:MergeAcross="5"><Data ss:Type="String">Tanggal Pengiriman: ' P_DATE '</Data></Cell></Row>' INTO LV_ROW.
APPEND LV_ROW TO LT_X.
APPEND '<Row><Cell ss:StyleID="h"><Data ss:Type="String">No. PO</Data></Cell>' TO LT_X.
APPEND '<Cell ss:StyleID="h"><Data ss:Type="String">Vendor</Data></Cell>' TO LT_X.
APPEND '<Cell ss:StyleID="h"><Data ss:Type="String">Nilai (USD)</Data></Cell>' TO LT_X.
APPEND '<Cell ss:StyleID="h"><Data ss:Type="String">Tier</Data></Cell>' TO LT_X.
APPEND '<Cell ss:StyleID="h"><Data ss:Type="String">Flag</Data></Cell>' TO LT_X.
APPEND '<Cell ss:StyleID="h"><Data ss:Type="String">Alasan Exception</Data></Cell></Row>' TO LT_X.
```

- [ ] **Step 3: Beri baris exception style `warn` dan nilai USD numeric**

```abap
IF LS_MAIL-EXC_FLAG EQ 'X'.
  LV_STYLE = 'warn'.
  LV_FLAG  = 'PERHATIAN'.
ELSE.
  LV_STYLE = 'normal'.
  LV_FLAG  = 'OK'.
ENDIF.
CONCATENATE '<Row ss:StyleID="' LV_STYLE '"><Cell ss:StyleID="text"><Data ss:Type="String">' LV_EBELN '</Data></Cell>' INTO LV_ROW.
```

- [ ] **Step 4: Tambah AutoFilter dan freeze header**

```abap
APPEND '<AutoFilter x:Range="R3C1:R999C6" xmlns="urn:schemas-microsoft-com:office:excel"/>' TO LT_X.
APPEND '<WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel"><FreezePanes/><FrozenNoSplit/><SplitHorizontal>3</SplitHorizontal><TopRowBottomPane>3</TopRowBottomPane></WorksheetOptions>' TO LT_X.
```

- [ ] **Step 5: Ubah attachment dari CSV menjadi XLS**

```abap
PERFORM F_BUILD_XLS USING P_OPT GV_DATE_ID CHANGING GV_XLS_XML.
CALL FUNCTION 'HR_KR_STRING_TO_XSTRING'
  EXPORTING
    CODEPAGE_TO    = '4110'
    UNICODE_STRING = GV_XLS_XML
  IMPORTING
    XSTRING_STREAM = GV_XSTR.
LO_DOC->ADD_ATTACHMENT(
  I_ATTACHMENT_TYPE    = 'XLS'
  I_ATTACHMENT_SUBJECT = LV_ATTS
  I_ATT_CONTENT_HEX    = GT_BIN ).
```

- [ ] **Step 6: Jalankan test mode dan cek output**

Run `ZMMI_PO_EMAIL` with `P_TEST = 'X'` against selected T1/T2 PO.

Expected: no email is sent; list output identifies intended recipient groups; no dump.

### Task 3: Push, syntax check, dan verifikasi attachment pada sandbox

**Files:**
- Modify: source live `ZMMI_PO_EMAIL` on sandbox-new/TRS only.
- Test: source readback and `SYNTAX-CHECK FOR`.

**Interfaces:**
- Consumes: completed `F_FORMAT_DATE_ID` and `F_BUILD_XLS` forms.
- Produces: `ZMMI_PO_EMAIL` with formatted `.xls` attachment.

- [ ] **Step 1: Set active server ke `sandbox-new`**

Confirm SID `TRS` and host `192.168.6.243` before source update.

- [ ] **Step 2: Push full source melalui `Z_RFC_PROGRAM_UPDATE`**

Use:

```text
IV_PROGRAM_NAME = ZMMI_PO_EMAIL
IV_PACKAGE      = $TMP
IV_CORRNUMBER   = <space>
IT_SOURCE       = full source, each line <= 255 characters
```

- [ ] **Step 3: Read back and syntax check**

Expected: source contains `FORM F_BUILD_XLS`, attachment type `XLS`, no residual CSV attachment call, and `SYNTAX_OK`.

- [ ] **Step 4: Preserve local deliverable**

Copy final source to `C:\Users\Lenovo\Claude\Projects\SAP ABAP Consultant\ZMMI_PO_EMAIL.abap`.

## Self-Review

- Coverage: replaces CSV, applies visual styling, fixes column widths and scientific-number issue, highlights exception rows, preserves HTML email, and introduces Indonesian date in all requested locations.
- No placeholders: form names, inputs, output types, and expected checks are specified.
- Scope: only attachment construction and date presentation; recipient routing and exception rules are unchanged.
