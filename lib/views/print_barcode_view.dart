import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../viewmodels/library_viewmodel.dart';
import '../theme/app_theme.dart';
import '../models/library_models.dart';

class PrintBarcodeView extends StatefulWidget {
  const PrintBarcodeView({super.key});

  @override
  State<PrintBarcodeView> createState() => _PrintBarcodeViewState();
}

class _PrintBarcodeViewState extends State<PrintBarcodeView> {
  String selectedClassification = 'Semua';

  // KOMPONEN LABEL FIX UKURAN FISIK
  pw.Widget _buildLabelCard(Book book) {
    String authorRaw = book.author.trim().toUpperCase();
    String authorCode = authorRaw.length >= 3
        ? authorRaw.substring(0, 3)
        : authorRaw;
    String titleRaw = book.title.trim().toUpperCase();
    String titleCode = titleRaw.isNotEmpty ? titleRaw.substring(0, 1) : '';

    // MENGUNCI UKURAN DALAM SENTIMETER ASLI (4cm x 3cm)
    final double cardWidth = 4.0 * PdfPageFormat.cm;
    final double cardHeight = 3.0 * PdfPageFormat.cm;

    return pw.Container(
      width: cardWidth,
      height: cardHeight,
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1.0),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 0.5),
            ),
            child: pw.Text(
              // Disingkat agar muat sempurna di dalam lebar fisik 4 cm
              'Perpustakaan Widya Loka',
              style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 3),

          pw.Expanded(
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // KOTAK QR CODE
                pw.Container(
                  width: 1.65 * PdfPageFormat.cm, // Lebar QR Code 1.65 cm
                  height: 1.65 * PdfPageFormat.cm,
                  padding: const pw.EdgeInsets.all(2),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 0.5),
                  ),
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: book.bookCode,
                  ),
                ),
                pw.SizedBox(width: 4),

                // KOTAK TEKS (SUBJEK, PENGARANG, JUDUL)
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(2),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.black, width: 0.5),
                    ),
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          book.subject.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                          maxLines: 1,
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          authorCode,
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          titleCode,
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List> _generatePdf(
    PdfPageFormat format,
    LibraryViewModel vm,
  ) async {
    final pdf = pw.Document();

    final books = selectedClassification == 'Semua'
        ? vm.books
        : vm.books
              .where((b) => b.classification == selectedClassification)
              .toList();

    // RUMUS PERHITUNGAN BARIS OTOMATIS BERDASARKAN UKURAN KERTAS
    final double spacing =
        0.3 * PdfPageFormat.cm; // Spasi antar stiker 3 milimeter
    final double cardWidthWithSpacing = (4.0 * PdfPageFormat.cm) + spacing;
    final double margins = 24.0 * 2;
    final double usableWidth = format.width - margins;

    int columnsCount = (usableWidth / cardWidthWithSpacing).floor();
    if (columnsCount < 1) columnsCount = 1;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(24),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Katalog Cetak Label - Klasifikasi: $selectedClassification',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    'Halaman ${context.pageNumber} dari ${context.pagesCount}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 14),
            ],
          );
        },
        build: (context) {
          List<pw.Widget> rows = [];

          for (int i = 0; i < books.length; i += columnsCount) {
            List<pw.Widget> rowChildren = [];

            for (int j = 0; j < columnsCount; j++) {
              if (i + j < books.length) {
                rowChildren.add(_buildLabelCard(books[i + j]));
              } else {
                // Beri ruang kosong jika stiker terakhir di baris ganjil
                rowChildren.add(pw.SizedBox(width: 4.0 * PdfPageFormat.cm));
              }
            }

            rows.add(
              pw.Padding(
                padding: pw.EdgeInsets.only(bottom: spacing),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: rowChildren
                      .map(
                        (w) => pw.Padding(
                          padding: pw.EdgeInsets.only(right: spacing),
                          child: w,
                        ),
                      )
                      .toList(),
                ),
              ),
            );
          }

          if (rows.isEmpty) {
            rows.add(pw.Center(child: pw.Text('Tidak ada data buku.')));
          }

          return rows;
        },
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<LibraryViewModel>(context);
    final classifications = ['Semua', ...vm.availableClassifications];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cetak Label Buku (3x4 cm)',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedClassification,
                    decoration: const InputDecoration(
                      labelText: 'Filter Klasifikasi Buku',
                    ),
                    items: classifications
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => selectedClassification = val!),
                  ),
                ),
                const SizedBox(width: 24),
                // Tampilan informasi ukuran yang terkunci
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ukuran Label Fisik:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '4.0 cm x 3.0 cm',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PdfPreview(
              build: (format) => _generatePdf(format, vm),
              canChangeOrientation: false,
              canChangePageFormat: true,
              allowSharing: true,
              allowPrinting: true,
            ),
          ),
        ],
      ),
    );
  }
}
