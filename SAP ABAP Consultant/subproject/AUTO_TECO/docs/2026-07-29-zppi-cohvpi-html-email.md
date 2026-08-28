# ZPPI_COHVPI HTML Email Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Render the Auto TECO email as the approved centered Reference Table while preserving current ZMAP_TYPE wording and grouped attachments.

**Architecture:** Keep HTML structure and dynamic summary generation in `ZPPI_COHVPI`. Continue loading business wording from `ZMAP_TYPE` under `TYPE = 'EMAIL TEXT'`; combine consecutive mapped records into paragraphs and treat blank records as paragraph separators. Do not update ZMAP_TYPE data or attachment generation.

**Tech Stack:** SAP ECC 6.0, ABAP 7.31, CL_BCS, classic Open SQL, ZMAP_TYPE.

## Global Constraints

- Target write system is only `sandbox-new` / TRS.
- Fetch and back up the latest SAP source before editing.
- Use ABAP 7.31 syntax only; no inline declarations, constructors, string templates, or `@` host variables.
- Preserve `ADD_LINKED_ORDERS`, `ADD_XLS_ATTACH`, `BUILD_XLS`, and TECO transaction logic.
- Push with `Z_RFC_PROGRAM_UPDATE`, then run remote syntax-check and read-back verification.

---

### Task 1: Establish HTML Email Contract

**Files:**
- Create: `tests/test_zppi_email_html.ps1`
- Read: `outputs/ZPPI_COHVPI_current_TRS.txt`

**Interfaces:**
- Consumes: Latest 1,557-line TRS source and current EMAIL TEXT mapping.
- Produces: A static regression contract for HTM document type, mapped sections, summary renderer, and unchanged grouped attachment form.

- [x] Write the failing contract test.
- [x] Run it against the baseline and verify it fails because HTML rendering is absent.

### Task 2: Implement Mapping-Aware HTML Body

**Files:**
- Modify: `outputs/ZPPI_COHVPI_current_TRS.txt`

**Interfaces:**
- Consumes: `GT_ETX`, `ITAB`, `SUBST_TEXT`, and existing CL_BCS objects.
- Produces: `BUILD_HTML_EMAIL`, `APPEND_ETX_HTML`, `APPEND_SUMMARY_HTML`, `APPEND_HTML`, `HTML_ESC`, and `GET_EMAIL_LABEL` forms.

- [ ] Change CL_BCS document type from `RAW` to `HTM`.
- [ ] Render SUBJECT as the HTML title.
- [ ] Render HEADER, BODY, and FOOTER from current ZMAP_TYPE records.
- [ ] Combine consecutive mapped records into paragraphs; blank records create spacing.
- [ ] Render centered Group/Order/Status/Result summary rows from ITAB.
- [ ] Use optional `OPT = 'LABEL'` records with safe fallback labels.
- [ ] Preserve existing grouped attachments and transaction logic byte-for-byte.

### Task 3: Verify and Deploy

**Files:**
- Test: `tests/test_zppi_email_html.ps1`
- Deploy: SAP program `ZPPI_COHVPI` on TRS.

**Interfaces:**
- Consumes: Patched source.
- Produces: Active, syntax-valid TRS program and read-back evidence.

- [ ] Run the contract test and verify PASS.
- [ ] Inspect diff against timestamped baseline for email-only changes.
- [ ] Check line count and maximum source line length of 255 characters.
- [ ] Set active server to `sandbox-new` and push with `Z_RFC_PROGRAM_UPDATE`.
- [ ] Run remote `SYNTAX-CHECK` and require `SYNTAX OK`.
- [ ] Read back the program and confirm deployed source matches the patch.
