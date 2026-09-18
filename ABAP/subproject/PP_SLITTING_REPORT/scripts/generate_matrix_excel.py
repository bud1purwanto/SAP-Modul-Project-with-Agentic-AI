#!/usr/bin/env python3

import os
import shutil
import subprocess
import tempfile
import time

import uno
from com.sun.star.beans import PropertyValue


HORI_CENTER = 2
VERT_CENTER = 2


BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOCS_DIR = os.path.join(BASE_DIR, "docs")
OUTPUT_FILE = os.path.join(DOCS_DIR, "Matrix_Perbedaan_ZPP016_vs_ZPP016N.xlsx")


def prop(name, value):
    item = PropertyValue()
    item.Name = name
    item.Value = value
    return item


def rgb(hex_value):
    return int(hex_value.replace("#", ""), 16)


def set_cell(sheet, col, row, value):
    cell = sheet.getCellByPosition(col, row)
    cell.String = str(value)
    return cell


def style_range(sheet, cell_range, **styles):
    target = sheet.getCellRangeByName(cell_range)
    for key, value in styles.items():
        setattr(target, key, value)


def add_border(target, color):
    border = target.TopBorder
    border.Color = color
    border.InnerLineWidth = 0
    border.OuterLineWidth = 18
    border.LineDistance = 0
    target.TopBorder = border
    target.BottomBorder = border
    target.LeftBorder = border
    target.RightBorder = border


def create_workbook(desktop):
    document = desktop.loadComponentFromURL("private:factory/scalc", "_blank", 0, ())
    sheets = document.Sheets
    sheets.getByIndex(0).Name = "Ringkasan"
    sheets.insertNewByName("Matriks Perbedaan", 1)
    sheets.insertNewByName("Referensi", 2)
    return document


def build_summary(sheet):
    sheet.getCellRangeByName("A1:D1").merge(True)
    set_cell(sheet, 0, 0, "MATRIX PERBEDAAN REPORT SLITTING HARIAN")
    style_range(
        sheet,
        "A1:D1",
        CellBackColor=rgb("17365D"),
        CharColor=rgb("FFFFFF"),
        CharWeight=150,
        CharHeight=18,
        HoriJustify=HORI_CENTER,
        VertJustify=VERT_CENTER,
    )
    sheet.Rows.getByIndex(0).Height = 950

    sheet.getCellRangeByName("A3:D3").merge(True)
    set_cell(sheet, 0, 2, "Klarifikasi objek")
    style_range(sheet, "A3:D3", CellBackColor=rgb("D9EAF7"), CharWeight=150, CharColor=rgb("17365D"))

    sheet.getCellRangeByName("A4:D5").merge(True)
    set_cell(
        sheet,
        0,
        3,
        "Objek bernama persis ZPP106 tidak ditemukan di RAG maupun repository SAP lintas DEV, QA, Sandbox, dan Production. "
        "Pasangan yang terverifikasi adalah ZPP016 dan ZPP016N; keduanya berjudul Rekap Slitting Harian. "
        "Workbook ini membandingkan pasangan aktual tersebut.",
    )
    style_range(sheet, "A4:D5", IsTextWrapped=True, VertJustify=VERT_CENTER, CellBackColor=rgb("FFF2CC"))

    headers = ["Aspek", "ZPP016", "ZPP016N", "Inti Perbedaan"]
    for col, header in enumerate(headers):
        set_cell(sheet, col, 7, header)
    style_range(
        sheet,
        "A8:D8",
        CellBackColor=rgb("1F4E78"),
        CharColor=rgb("FFFFFF"),
        CharWeight=150,
        HoriJustify=HORI_CENTER,
    )

    summary_rows = [
        ("Program", "ZPPR_SLITTING_REKAP_DAILY", "ZPPR_SLITTING_REKAP_PC_V2", "Dua codebase terpisah"),
        ("Orientasi", "Eksekusi order dan performa proses", "Output roll/batch dan traceability", "Process-centric vs batch-centric"),
        ("Kekuatan utama", "Combined order, CX, MS/SS, waktu proses, speed", "Filter batch, final batch, final stock, Toyobo", "Kebutuhan analisis berbeda"),
        ("Output OLAP", "TRIASDB05 / XZPP016 / SP_MERGE_ZPP016", "TRIASDB04 / XSR_MPAGI", "Target staging berbeda"),
        ("Rujukan blueprint", "Tidak ditemukan rujukan aktif yang kuat", "Dipakai Staff PPIC sebagai Report Slitting Harian", "RAG lebih konsisten menunjuk ZPP016N"),
    ]
    for row_index, row_data in enumerate(summary_rows, start=8):
        for col, value in enumerate(row_data):
            set_cell(sheet, col, row_index, value)
        shade = "F3F6F9" if row_index % 2 == 0 else "FFFFFF"
        style_range(sheet, "A{}:D{}".format(row_index + 1, row_index + 1), CellBackColor=rgb(shade), IsTextWrapped=True)

    sheet.getCellRangeByName("A15:B15").merge(True)
    sheet.getCellRangeByName("C15:D15").merge(True)
    set_cell(sheet, 0, 14, "Gunakan ZPP016 bila fokusnya")
    set_cell(sheet, 2, 14, "Gunakan ZPP016N bila fokusnya")
    style_range(sheet, "A15:B15", CellBackColor=rgb("F4B183"), CharWeight=150, HoriJustify=HORI_CENTER)
    style_range(sheet, "C15:D15", CellBackColor=rgb("76D7C4"), CharWeight=150, HoriJustify=HORI_CENTER)

    sheet.getCellRangeByName("A16:B18").merge(True)
    sheet.getCellRangeByName("C16:D18").merge(True)
    set_cell(
        sheet,
        0,
        15,
        "Detail eksekusi produksi: combined/original order, Condux/CX, turunan dan posisi MS/SS, start-finish, process time, dan speed.",
    )
    set_cell(
        sheet,
        2,
        15,
        "Traceability hasil produksi: batch tertentu, last/final batch, final grade/criteria/quantity, stok aktual, data Toyobo, serta rekap grade/shift/sales.",
    )
    style_range(sheet, "A16:D18", IsTextWrapped=True, VertJustify=VERT_CENTER)

    sheet.getCellRangeByName("A20:D21").merge(True)
    set_cell(
        sheet,
        0,
        19,
        "PERHATIAN: radio mode OLAP pada kedua program bukan operasi read-only. Program menghapus isi tabel staging eksternal sebelum melakukan insert ulang.",
    )
    style_range(sheet, "A20:D21", CellBackColor=rgb("F4CCCC"), CharColor=rgb("9C0006"), CharWeight=150, IsTextWrapped=True, VertJustify=VERT_CENTER)

    widths = [5200, 8000, 8000, 7200]
    for col, width in enumerate(widths):
        sheet.Columns.getByIndex(col).Width = width
    for row in range(7, 21):
        sheet.Rows.getByIndex(row).OptimalHeight = True
    add_border(sheet.getCellRangeByName("A8:D12"), rgb("B4C7E7"))


def build_matrix(sheet):
    rows = [
        ("Judul transaksi", "Rekap Slitting Harian", "Rekap Slitting Harian", "Judul sama; report di belakangnya berbeda."),
        ("Program utama", "ZPPR_SLITTING_REKAP_DAILY", "ZPPR_SLITTING_REKAP_PC_V2", "Dua codebase terpisah, bukan transaction variant."),
        ("Fokus bisnis", "Detail eksekusi produksi dan performa proses", "Detail hasil roll/batch dan traceability final batch", "Execution-oriented vs batch/output-oriented."),
        ("Input umum", "Material, Plant, Material Group, Posting Date, Production Line", "Material, Plant, Material Group, Posting Date, Production Line", "Hampir sama."),
        ("Input tambahan", "Tidak ada filter batch", "Batch (ZCHARG) dan checkbox V_SCON default aktif", "ZPP016N dapat membatasi langsung ke batch."),
        ("Material scope", "MTART ZFGS; MATKL default 300001-300024", "MTART ZFGS; MATKL default 300001-300024", "Sama."),
        ("Movement utama", "101, 261 Condux/CX, 531 transfer FG-to-FG", "101, 531; reversal 102/532; 411/412/413/414 untuk SO", "ZPP016 menangkap CX; ZPP016N memperkuat transfer/reversal/SO."),
        ("Reversal", "Menghapus dokumen yang direferensikan melalui SMBLN", "Eksplisit 101↔102 dan 531↔532", "ZPP016N lebih eksplisit per pasangan movement."),
        ("Data order", "Combined Order, Original Order, Original Order Type", "Order Number dan atribut output roll", "Struktur order lebih lengkap di ZPP016."),
        ("Data mesin", "Resource, start/finish, process time, speed, entered-at", "Resource, entry time, rekap per shift", "KPI langsung vs agregasi shift."),
        ("Data film/batch", "Film, batch, roll, criteria, grade, treatment, packing, width, length, extra length, core type", "Field umum sama plus description grade dan last values", "ZPP016N lebih kaya pada histori batch."),
        ("Data MS/SS", "MS/SS, turunan dan posisi MS/SS", "Tidak ada", "Khusus ZPP016."),
        ("Final batch/history", "Tidak memakai ZBATCHISTORY", "Final batch/no. roll/grade/criteria/qty dari ZBATCHISTORY", "Traceability final batch adalah kekuatan ZPP016N."),
        ("Current/final stock", "Terutama Last Quantity", "Last Qty dan Final Qty Actual dari MCHB/MSKA/MSLB/MSKU", "ZPP016N lebih lengkap lintas kategori stok."),
        ("Toyobo/label", "Tidak ada", "Category, Type Label, Grade Toyobo, No. Roll/Lot Toyobo, Type Alias", "Khusus ZPP016N."),
        ("Sales/customer", "SO, item, sales type, sold-to, customer name", "SO, item, customer/description dan rekap sales", "ZPP016 simpan sales type; ZPP016N lebih traceability-oriented."),
        ("Tampilan utama", "Classic ALV", "Classic ALV", "Sama-sama ALV."),
        ("Fitur layar", "ALV detail", "Rekap Grade, Shift, Sales; drilldown MSC3N", "ZPP016N lebih interaktif."),
        ("Download lokal", "Bukan fitur utama", "GUI_DOWNLOAD untuk grade/shift/sales, format DBF", "Keunggulan ZPP016N."),
        ("Mode OLAP", "TRIASDB05 → XZPP016 → SP_MERGE_ZPP016", "TRIASDB04 → XSR_MPAGI", "Database dan staging berbeda."),
        ("Dampak OLAP", "DELETE seluruh staging, INSERT ulang, lalu stored procedure", "DELETE seluruh staging lalu INSERT ulang", "Keduanya bukan read-only."),
        ("Otorisasi", "Z_WERKS, Z_OLAP; source mengecek ZTCODE ZPP016N", "Z_WERKS, Z_OLAP, ZTCODE ZPP016N", "Check ZPP016N di source lama perlu dicatat."),
        ("Use case RAG", "Tidak ada referensi aktif yang kuat", "Staff PPIC; monitoring setelah Slitting Execution", "Blueprint operasional menunjuk ZPP016N."),
    ]

    sheet.getCellRangeByName("A1:D1").merge(True)
    set_cell(sheet, 0, 0, "MATRIKS DETAIL — ZPP016 VS ZPP016N")
    style_range(sheet, "A1:D1", CellBackColor=rgb("17365D"), CharColor=rgb("FFFFFF"), CharWeight=150, CharHeight=16, HoriJustify=HORI_CENTER)
    sheet.Rows.getByIndex(0).Height = 850

    headers = ["Aspek", "ZPP016", "ZPP016N", "Perbedaan Utama"]
    for col, header in enumerate(headers):
        set_cell(sheet, col, 2, header)
    style_range(sheet, "A3:D3", CellBackColor=rgb("1F4E78"), CharColor=rgb("FFFFFF"), CharWeight=150, HoriJustify=HORI_CENTER)

    for row_index, row_data in enumerate(rows, start=3):
        for col, value in enumerate(row_data):
            set_cell(sheet, col, row_index, value)
        style_range(
            sheet,
            "A{}:D{}".format(row_index + 1, row_index + 1),
            CellBackColor=rgb("F3F6F9" if row_index % 2 else "FFFFFF"),
            IsTextWrapped=True,
            VertJustify=VERT_CENTER,
        )
        sheet.getCellByPosition(0, row_index).CharWeight = 150

    last_row = 3 + len(rows)
    style_range(sheet, "B4:B{}".format(last_row), CellBackColor=rgb("FCE4D6"))
    style_range(sheet, "C4:C{}".format(last_row), CellBackColor=rgb("DDEBF7"))
    add_border(sheet.getCellRangeByName("A3:D{}".format(last_row)), rgb("B4C7E7"))

    widths = [5200, 9300, 9300, 8300]
    for col, width in enumerate(widths):
        sheet.Columns.getByIndex(col).Width = width
    for row in range(2, last_row):
        sheet.Rows.getByIndex(row).OptimalHeight = True

def build_references(sheet):
    sheet.getCellRangeByName("A1:D1").merge(True)
    set_cell(sheet, 0, 0, "REFERENSI DAN JEJAK VERIFIKASI")
    style_range(sheet, "A1:D1", CellBackColor=rgb("17365D"), CharColor=rgb("FFFFFF"), CharWeight=150, CharHeight=16, HoriJustify=HORI_CENTER)

    headers = ["Jenis", "Objek/Dokumen", "Lokasi", "Temuan"]
    for col, header in enumerate(headers):
        set_cell(sheet, col, 2, header)
    style_range(sheet, "A3:D3", CellBackColor=rgb("1F4E78"), CharColor=rgb("FFFFFF"), CharWeight=150, HoriJustify=HORI_CENTER)

    references = [
        ("SAP", "TSTC/TSTCT", "DEV/QA/TRS/PRT/TRP", "ZPP016 dan ZPP016N tersedia; ZPP106 tidak ditemukan."),
        ("SAP Source", "ZPPR_SLITTING_REKAP_DAILY", "TRD", "Program utama ZPP016 beserta include TOP/F01."),
        ("SAP Source", "ZPPR_SLITTING_REKAP_PC_V2", "TRD", "Program utama ZPP016N beserta include TOP/F01/O01/I01."),
        ("RAG Blueprint", "PPPE02 Production Process of Slit Roll BOPP v2", "Halaman 8", "ZPP016N = Report Slitting Harian."),
        ("RAG Blueprint", "PPPE06 Production Process of Slit Roll Metalizing", "Halaman 8-9", "Staff PPIC memakai ZPP016N untuk melacak kegiatan produksi."),
        ("RAG Blueprint", "PPPE26 Production Process of Slit Roll CPP v2", "Halaman 8", "ZPP016N tercantum sebagai Report Slitting Harian."),
        ("RAG Blueprint", "PPPE08 Production Process of Slit Roll Coating v2", "Halaman 9", "ZPP016N tercantum pada RICEF process."),
    ]
    for row_index, row_data in enumerate(references, start=3):
        for col, value in enumerate(row_data):
            set_cell(sheet, col, row_index, value)
        style_range(sheet, "A{}:D{}".format(row_index + 1, row_index + 1), CellBackColor=rgb("F3F6F9" if row_index % 2 else "FFFFFF"), IsTextWrapped=True)

    note_row = 5 + len(references)
    sheet.getCellRangeByName("A{}:D{}".format(note_row, note_row + 1)).merge(True)
    set_cell(sheet, 0, note_row - 1, "Analisis dilakukan pada 10 September 2026. Tidak ada source program SAP yang diubah.")
    style_range(sheet, "A{}:D{}".format(note_row, note_row + 1), CellBackColor=rgb("E2F0D9"), CharWeight=150, IsTextWrapped=True, VertJustify=VERT_CENTER)

    widths = [4200, 10500, 5000, 10800]
    for col, width in enumerate(widths):
        sheet.Columns.getByIndex(col).Width = width
    for row in range(2, note_row + 1):
        sheet.Rows.getByIndex(row).OptimalHeight = True
    add_border(sheet.getCellRangeByName("A3:D{}".format(3 + len(references))), rgb("B4C7E7"))


def main():
    profile_dir = tempfile.mkdtemp(prefix="lo_matrix_")
    port = 20883
    process = subprocess.Popen(
        [
            "libreoffice",
            "--headless",
            "--nologo",
            "--nodefault",
            "--nofirststartwizard",
            "-env:UserInstallation=file://{}".format(profile_dir),
            "--accept=socket,host=localhost,port={};urp;StarOffice.ComponentContext".format(port),
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    try:
        local_context = uno.getComponentContext()
        resolver = local_context.ServiceManager.createInstanceWithContext("com.sun.star.bridge.UnoUrlResolver", local_context)
        context = None
        for _ in range(50):
            try:
                context = resolver.resolve(
                    "uno:socket,host=localhost,port={};urp;StarOffice.ComponentContext".format(port)
                )
                break
            except Exception:
                time.sleep(0.2)
        if context is None:
            raise RuntimeError("LibreOffice headless tidak dapat dihubungi")

        service_manager = context.ServiceManager
        desktop = service_manager.createInstanceWithContext("com.sun.star.frame.Desktop", context)
        document = create_workbook(desktop)

        build_summary(document.Sheets.getByName("Ringkasan"))
        build_matrix(document.Sheets.getByName("Matriks Perbedaan"))
        build_references(document.Sheets.getByName("Referensi"))

        document.CurrentController.setActiveSheet(document.Sheets.getByName("Ringkasan"))
        document.CurrentController.freezeAtPosition(1, 3)

        output_url = uno.systemPathToFileUrl(OUTPUT_FILE)
        document.storeAsURL(output_url, (prop("FilterName", "Calc MS Excel 2007 XML"), prop("Overwrite", True)))
        document.close(True)
    finally:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
        shutil.rmtree(profile_dir, ignore_errors=True)

    print(OUTPUT_FILE)


if __name__ == "__main__":
    main()
