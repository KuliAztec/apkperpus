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
  double qrSize = 55.0;

  // Komponen pembuat 1 kotak stiker
  pw.Widget _buildLabelCard(Book book, double currentQrSize) {
    String authorRaw = book.author.trim().toUpperCase();
    String authorCode = authorRaw.length >= 3
        ? authorRaw.substring(0, 3)
        : authorRaw;
    String titleRaw = book.title.trim().toUpperCase();
    String titleCode = titleRaw.isNotEmpty ? titleRaw.substring(0, 1) : '';

    return pw.Container(
      width: currentQrSize * 3.2,
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1.5),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 3),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
            ),
            child: pw.Text(
              'Perpustakaan Widyaloka Nusawungu',
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 5),

          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: currentQrSize + 8,
                height: currentQrSize + 8,
                padding: const pw.EdgeInsets.all(3),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 1),
                ),
                child: pw.Center(
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: book.bookCode,
                    width: currentQrSize,
                    height: currentQrSize,
                  ),
                ),
              ),
              pw.SizedBox(width: 5),

              pw.Expanded(
                child: pw.Container(
                  height: currentQrSize + 8,
                  padding: const pw.EdgeInsets.all(3),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 1),
                  ),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        book.subject.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                        maxLines: 1,
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        authorCode,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        titleCode,
                        style: pw.TextStyle(
                          fontSize: 12,
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

    // RUMUS CERDAS: Mencegah Kertas Kepenuhan (Anti-Crash)
    // Menghitung berapa kotak yang muat dalam 1 baris ke samping
    final double margins = 24.0 * 2;
    final double usableWidth = format.width - margins;
    final double cardWidth =
        (qrSize * 3.2) + 14.0; // 14 adalah jarak spasi antar kartu

    int columnsCount = (usableWidth / cardWidth).floor();
    if (columnsCount < 1) columnsCount = 1;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(24),
        // Header ini akan otomatis tercetak di setiap lembar baru
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

          // Memecah ratusan buku menjadi baris-baris.
          // Jika tinggi kertas A4 sudah habis, MultiPage akan otomatis membuat halaman baru.
          for (int i = 0; i < books.length; i += columnsCount) {
            List<pw.Widget> rowChildren = [];

            for (int j = 0; j < columnsCount; j++) {
              if (i + j < books.length) {
                rowChildren.add(_buildLabelCard(books[i + j], qrSize));
              } else {
                // Memberikan ruang kosong jika baris terakhir tidak genap
                rowChildren.add(pw.SizedBox(width: qrSize * 3.2));
              }
            }

            rows.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 14),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: rowChildren
                      .map(
                        (w) => pw.Padding(
                          padding: const pw.EdgeInsets.only(right: 14),
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
          'Cetak Label Buku (Standar)',
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ukuran Skala: ${qrSize.toInt()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Slider(
                        value: qrSize,
                        min: 40,
                        max: 90,
                        activeColor: AppTheme.primary,
                        onChanged: (val) => setState(() => qrSize = val),
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
