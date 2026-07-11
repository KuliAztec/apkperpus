import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/library_viewmodel.dart';
import '../theme/app_theme.dart';
import 'scanner_view.dart'; // <--- Import file scanner baru

class BorrowView extends StatefulWidget {
  const BorrowView({super.key});

  @override
  State<BorrowView> createState() => _BorrowViewState();
}

class _BorrowViewState extends State<BorrowView> {
  final _memberCodeCtrl = TextEditingController();
  final _bookCodeCtrl = TextEditingController();
  final _returnBookCodeCtrl = TextEditingController();
  final _searchTitleCtrl = TextEditingController();
  String _searchResult = '';

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<LibraryViewModel>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PANEL PEMINJAMAN
          const Text(
            'Input Peminjaman',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _memberCodeCtrl,
            decoration: const InputDecoration(
              labelText: 'Kode Anggota (Cth: ANG-001)',
            ),
          ),
          const SizedBox(height: 12),

          // INPUT KODE BUKU + TOMBOL SCANNER
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _bookCodeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Kode Buku (Cth: TEK-001)',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.qr_code_scanner,
                    size: 28,
                    color: AppTheme.primary,
                  ),
                  tooltip: 'Scan QR Code Buku',
                  onPressed: () async {
                    // Buka halaman scanner
                    final scannedCode = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ScannerView(),
                      ),
                    );
                    // Jika berhasil scan, otomatis isi kolom kode buku
                    if (scannedCode != null) {
                      setState(
                        () => _bookCodeCtrl.text = scannedCode.toString(),
                      );
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                final msg = vm.processBorrow(
                  _memberCodeCtrl.text,
                  _bookCodeCtrl.text,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(msg),
                    backgroundColor: msg.contains('Berhasil')
                        ? AppTheme.primary
                        : Colors.red,
                  ),
                );
                if (msg == 'Berhasil dipinjam!') {
                  _memberCodeCtrl.clear();
                  _bookCodeCtrl.clear();
                }
              },
              child: const Text(
                'Proses Peminjaman',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const Divider(height: 60, thickness: 1),

          // PANEL PENGEMBALIAN BUKU
          const Text(
            'Input Pengembalian',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),

          // INPUT KODE BUKU KEMBALI + TOMBOL SCANNER
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _returnBookCodeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Kode Buku Dikembalikan',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.qr_code_scanner,
                    size: 28,
                    color: AppTheme.secondary,
                  ),
                  tooltip: 'Scan QR Code Buku',
                  onPressed: () async {
                    final scannedCode = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ScannerView(),
                      ),
                    );
                    if (scannedCode != null)
                      setState(
                        () => _returnBookCodeCtrl.text = scannedCode.toString(),
                      );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                final msg = vm.processReturn(_returnBookCodeCtrl.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(msg),
                    backgroundColor: msg.contains('berhasil')
                        ? AppTheme.primary
                        : Colors.red.shade400,
                  ),
                );
                if (msg.contains('berhasil')) _returnBookCodeCtrl.clear();
              },
              child: const Text(
                'Proses Pengembalian',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const Divider(height: 60, thickness: 1),

          // PANEL PENCARIAN STATUS BUKU
          const Text(
            'Cek Status Buku',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchTitleCtrl,
            decoration: const InputDecoration(
              labelText: 'Cari Judul Buku...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (val) =>
                setState(() => _searchResult = vm.checkBookStatusByTitle(val)),
          ),
          const SizedBox(height: 16),
          if (_searchResult.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _searchResult,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
