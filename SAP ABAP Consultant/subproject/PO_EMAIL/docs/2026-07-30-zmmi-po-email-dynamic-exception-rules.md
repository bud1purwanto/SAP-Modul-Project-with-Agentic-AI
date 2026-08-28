# ZMMI_PO_EMAIL Dynamic Exception Rules Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Memindahkan parameter exception `ZMMI_PO_EMAIL` dari konstanta ABAP ke baris konfigurasi `ZMAP_TYPE`, termasuk rule vendor/material, persentase harga, stale history, serta multirow `PSTYP` dan `KNTTP`.

**Architecture:** Program memuat satu kali seluruh baris aktif `TYPE = 'EXC_RULE'` untuk `PROG = SY-CPROG`. Keberadaan setiap baris mengaktifkan rule; `DELETION = 'X'` menonaktifkannya. Parameter numerik disimpan sebagai angka bisnis (`10` berarti 10%) dan divalidasi sebelum dipakai.

**Tech Stack:** SAP ECC 6.0 EHP6, ABAP 7.31, classic Open SQL, `ZMAP_TYPE`, `Z_RFC_PROGRAM_UPDATE`.

## Global Constraints

- Source program hanya boleh diubah pada Sandbox New Company (`TRS`, `192.168.6.243`).
- Source DEV AIX tidak boleh diubah.
- Mapping `ZMAP_TYPE` ditulis ke TRS dan TRD setelah existing rows serta key diverifikasi.
- Tidak menggunakan inline declaration, string template, constructor operator, atau host variable `@`.
- Baris mapping yang tidak ada berarti rule nonaktif; tidak ada fallback hardcoded tersembunyi.

---

### Task 1: Baseline and Regression Checks

**Files:**
- Create: `tests/test_zmmi_po_email_dynamic_rules.ps1`
- Inspect: `ZMMI_PO_EMAIL.abap`

- [ ] Buat pemeriksaan source yang mensyaratkan tidak adanya lima konstanta exception lama.
- [ ] Tambahkan pemeriksaan loader `TYPE = 'EXC_RULE'`, rule `NO_HISTORY`, `DAYS`, `PERCENT`, `STALE_DAYS`, serta multirow `PSTYP`/`KNTTP`.
- [ ] Jalankan terhadap source lama dan pastikan gagal karena fitur belum ada.

### Task 2: Dynamic Rule Loader and Evaluation

**Files:**
- Modify: `ZMMI_PO_EMAIL.abap`

- [ ] Tambahkan tipe/internal table konfigurasi dan loader satu kali dari `ZMAP_TYPE`.
- [ ] Parse serta validasi angka `DAYS`, `PERCENT`, dan `STALE_DAYS`.
- [ ] Ubah `VendorBaru` dan `MaterialBaru` menjadi OR dari rule aktif `NO_HISTORY` dan `DAYS`.
- [ ] Ubah toleransi harga menjadi faktor `1 + percentage / 100`.
- [ ] Ubah service/capex menjadi pencocokan seluruh baris aktif `PSTYP` dan `KNTTP`.
- [ ] Jalankan regression checks hingga lulus.

### Task 3: Sandbox Deployment and Verification

**Files:**
- Modify: `ZMMI_PO_EMAIL` pada TRS melalui `Z_RFC_PROGRAM_UPDATE`.

- [ ] Pilih `sandbox-new` dan verifikasi SID/host.
- [ ] Backup source live, push source lengkap, jalankan syntax-check SAP, lalu exact readback.
- [ ] Jika verifikasi gagal, rollback source live sebelumnya.

### Task 4: Configuration Data

**Systems:** TRS dan TRD.

- [ ] Verifikasi struktur/key `ZMAP_TYPE` dan existing `EXC_RULE` rows.
- [ ] Upsert baris aktif untuk `VENDOR_NEW/NO_HISTORY`, `VENDOR_NEW/DAYS`, `MATERIAL_NEW/NO_HISTORY`, `MATERIAL_NEW/DAYS`, `PRICE_INCREASE/PERCENT`, `PRICE_HISTORY/STALE_DAYS`, `PSTYP/9`, dan `KNTTP/A`.
- [ ] Commit hanya custom-table configuration rows yang diminta; jangan menyentuh mapping lain.
- [ ] Readback kedua sistem dan cocokkan nilai serta jumlah baris.

### Task 5: Final Verification

- [ ] Pastikan regression checks lokal lulus.
- [ ] Pastikan syntax-check dan exact source readback TRS lulus.
- [ ] Pastikan mapping TRS/TRD identik untuk delapan baseline rows.
- [ ] Laporkan TCODE (`SE38`, `SM30`, `SE16N`, `SE11`), performance, dan dampak landscape.

## Execution Evidence — 30 July 2026

- Source `ZMMI_PO_EMAIL` updated only on TRS; DEV source was not written.
- SAP remote syntax-check: `SYNTAX OK`.
- Exact source readback: 1,349/1,349 lines; SHA-256
  `adffacff22a3e81fd913adfa279eaf92ff30acc1d4e754f2f5cfc86972a2fad9`.
- Test-mode execution on TRS: `RUN_OK_NO_EMAIL`, with no configuration warning.
- `ZMAP_TYPE` baseline: eight active `EXC_RULE` rows on TRS and TRD.
- Final mapping comparison: `trsExact=true`, `trdExact=true`, `parity=true`.
- Evidence files:
  - `outputs/ZMMI_PO_EMAIL_readback_xls_TRS.abap`
  - `outputs/ZMMI_PO_EMAIL_dynamic_rules_test_TRS.json`
  - `outputs/ZMAP_TYPE_EXC_RULE_final_parity_TRS_TRD.json`
