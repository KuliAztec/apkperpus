import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../viewmodels/library_viewmodel.dart';
import '../theme/app_theme.dart';

class PrintBarcodeView extends StatefulWidget {
  const PrintBarcodeView({super.key});

  @override
  State<PrintBarcodeView> createState() => _PrintBarcodeViewState();
}

class _PrintBarcodeViewState extends State<PrintBarcodeView> {
  String selectedClassification = 'Semua';
  double qrSize = 55.0; // Ukuran QR disesuaikan agar proporsi kotaknya pas

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

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            // HEADER HALAMAN (Di luar area stiker cetak)
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'Katalog Cetak Label Buku - Klasifikasi: $selectedClassification',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(thickness: 1, color: PdfColors.grey500),
                  pw.SizedBox(height: 20),
                ],
              ),
            ),

            // GRID STIKER LABEL BUKU (Sesuai dengan Sketsa Wireframe)
            pw.Wrap(
              spacing: 15, // Jarak antar stiker
              runSpacing: 15,
              children: books.map((book) {
                // Ekstraksi 3 huruf pertama nama pengarang
                String authorRaw = book.author.trim().toUpperCase();
                String authorCode = authorRaw.length >= 3
                    ? authorRaw.substring(0, 3)
                    : authorRaw;

                // Ekstraksi 1 huruf pertama judul buku
                String titleRaw = book.title.trim().toUpperCase();
                String titleCode = titleRaw.isNotEmpty
                    ? titleRaw.substring(0, 1)
                    : '';

                return pw.Container(
                  width: qrSize * 3.5, // Lebar keseluruhan stiker
                  padding: const pw.EdgeInsets.all(
                    6,
                  ), // Spasi antara garis luar dan kotak dalam
                  decoration: pw.BoxDecoration(
                    // GARIS LUAR TEBAL (Outer Border)
                    border: pw.Border.all(color: PdfColors.black, width: 2.5),
                  ),
                  child: pw.Column(
                    mainAxisSize: pw.MainAxisSize.min,
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      // KOTAK ATAS (Nama Perpustakaan)
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.black,
                            width: 1.5,
                          ), // Garis dalam
                        ),
                        child: pw.Text(
                          'Perpustakaan Widyaloka Nusawungu',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),

                      pw.SizedBox(
                        height: 6,
                      ), // Jarak antara kotak atas dan baris bawah
                      // BARIS BAWAH (Kotak Kiri & Kotak Kanan)
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // KOTAK KIRI (QR Code)
                          pw.Container(
                            width: qrSize + 12, // Lebar kotak menyesuaikan QR
                            height: qrSize + 12, // Tinggi disamakan
                            padding: const pw.EdgeInsets.all(4),
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(
                                color: PdfColors.black,
                                width: 1.5,
                              ),
                            ),
                            child: pw.Center(
                              child: pw.BarcodeWidget(
                                barcode: pw.Barcode.qrCode(),
                                data: book.bookCode,
                                width: qrSize,
                                height: qrSize,
                              ),
                            ),
                          ),

                          pw.SizedBox(
                            width: 6,
                          ), // Jarak antara kotak kiri dan kanan
                          // KOTAK KANAN (Call Number / Subjek - Penulis - Judul)
                          pw.Expanded(
                            child: pw.Container(
                              height:
                                  qrSize +
                                  12, // Tingginya dibuat sama persis dengan kotak QR
                              padding: const pw.EdgeInsets.all(4),
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(
                                  color: PdfColors.black,
                                  width: 1.5,
                                ),
                              ),
                              child: pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.center,
                                children: [
                                  // Nomor Subjek
                                  pw.Text(
                                    book.subject.toUpperCase(),
                                    style: pw.TextStyle(
                                      fontSize: 11,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                    textAlign: pw.TextAlign.center,
                                    maxLines: 1,
                                  ),
                                  pw.SizedBox(height: 4),
                                  // 3 Huruf Pengarang
                                  pw.Text(
                                    authorCode,
                                    style: pw.TextStyle(
                                      fontSize: 11,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                  pw.SizedBox(height: 4),
                                  // 1 Huruf Judul
                                  pw.Text(
                                    titleCode,
                                    style: pw.TextStyle(
                                      fontSize: 11,
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
              }).toList(),
            ),
          ];
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
