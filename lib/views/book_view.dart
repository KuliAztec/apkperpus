import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../viewmodels/library_viewmodel.dart';
import '../theme/app_theme.dart';
import 'print_barcode_view.dart';

class BookView extends StatefulWidget {
  const BookView({super.key});

  @override
  State<BookView> createState() => _BookViewState();
}

class _BookViewState extends State<BookView> {
  final titleCtrl = TextEditingController();
  final subjectCtrl = TextEditingController();
  final authorCtrl = TextEditingController();
  String? selectedClassification;

  void _showAddClassificationDialog(BuildContext context, LibraryViewModel vm) {
    final newClassCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Tambah Kode Klasifikasi',
          style: TextStyle(color: AppTheme.primary),
        ),
        content: TextField(
          controller: newClassCtrl,
          decoration: const InputDecoration(
            labelText: 'Kode Notasi (Cth: B1, B2, D)',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () {
              if (newClassCtrl.text.isNotEmpty) {
                vm.addClassification(newClassCtrl.text);
                setState(
                  () => selectedClassification = newClassCtrl.text
                      .trim()
                      .toUpperCase(),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, LibraryViewModel vm, var book) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Buku', style: TextStyle(color: Colors.red)),
        content: Text('Hapus buku "${book.title}" secara permanen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              final msg = vm.deleteBook(book.bookCode);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(msg),
                  backgroundColor: msg.contains('Gagal')
                      ? Colors.red.shade400
                      : AppTheme.primary,
                ),
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<LibraryViewModel>(context);
    final booksGrouped = vm.booksByClassification;
    if (selectedClassification == null &&
        vm.availableClassifications.isNotEmpty) {
      selectedClassification = vm.availableClassifications.first;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Judul Lengkap Buku',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: subjectCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nomor/Nama Subjek (Cth: 300 atau Komputer)',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: authorCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Penulis/Pengarang',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedClassification,
                  decoration: const InputDecoration(
                    labelText: 'Kode Klasifikasi Buku',
                  ),
                  // PERBAIKAN DI SINI: Langsung menampilkan kode klasifikasinya saja
                  items: vm.availableClassifications
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => selectedClassification = val),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: AppTheme.textDark),
                  onPressed: () => _showAddClassificationDialog(context, vm),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                ),
                onPressed: () {
                  if (titleCtrl.text.isNotEmpty &&
                      subjectCtrl.text.isNotEmpty &&
                      authorCtrl.text.isNotEmpty &&
                      selectedClassification != null) {
                    vm.addBook(
                      titleCtrl.text,
                      selectedClassification!,
                      subjectCtrl.text,
                      authorCtrl.text,
                    );
                    titleCtrl.clear();
                    subjectCtrl.clear();
                    authorCtrl.clear();
                  }
                },
                child: const Text(
                  'Tambah Buku',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.print),
              label: const Text(
                'Cetak Label QR Massal',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrintBarcodeView(),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 40, thickness: 1),
          Expanded(
            child: ListView.builder(
              itemCount: booksGrouped.length,
              itemBuilder: (context, index) {
                String classification = booksGrouped.keys.elementAt(index);
                var booksInClass = booksGrouped[classification]!;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 1,
                  child: ExpansionTile(
                    iconColor: AppTheme.primary,
                    collapsedIconColor: AppTheme.textDark,
                    // PERBAIKAN DI SINI: Langsung menampilkan kode klasifikasi saja
                    title: Text(
                      '$classification (${booksInClass.length} Buku)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    children: booksInClass.map((book) {
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        leading: SizedBox(
                          width: 45,
                          height: 45,
                          child: BarcodeWidget(
                            barcode: Barcode.qrCode(),
                            data: book.bookCode,
                            color: AppTheme.textDark,
                            drawText: false,
                          ),
                        ),
                        title: Text(
                          book.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'No. Urut Label: ${book.bookCode} | Penulis: ${book.author}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _confirmDelete(context, vm, book),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
