import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import '../models/library_models.dart';
import '../helpers/database_helper.dart';

class LibraryViewModel extends ChangeNotifier {
  List<Member> _members = [];
  List<Book> _books = [];
  final List<BorrowRecord> _records = [];
  final List<BorrowRecord> _borrowHistory = [];

  final List<String> _availableClassifications = ['A', 'B1', 'B2', 'B3', 'C'];

  LibraryViewModel() {
    _initDatabaseFromDb();
  }

  Future<void> _initDatabaseFromDb() async {
    final dbMembers = await DatabaseHelper.instance.readAllMembers();
    final dbBooks = await DatabaseHelper.instance.readAllBooks();

    if (dbMembers.isEmpty) {
      final defaultMember = Member(
        id: 'M1',
        memberCode: 'ANG-001',
        name: 'Fawwaz',
        jenjang: 'SMA',
      );
      await DatabaseHelper.instance.insertMember(defaultMember);
      _members.add(defaultMember);
    } else {
      _members = dbMembers;
    }

    _books = dbBooks;
    // Pastikan daftar buku selalu tersortir rapi berdasarkan nomor kode panggilnya
    _books.sort((a, b) => a.bookCode.compareTo(b.bookCode));

    for (var book in _books) {
      if (!_availableClassifications.contains(book.classification)) {
        _availableClassifications.add(book.classification);
      }
    }

    final rawRecords = await DatabaseHelper.instance.readAllRawBorrowRecords();
    for (var raw in rawRecords) {
      try {
        final member = _members.firstWhere(
          (m) => m.memberCode == raw['memberCode'],
        );
        final book = _books.firstWhere((b) => b.bookCode == raw['bookCode']);

        final record = BorrowRecord(
          id: raw['id'],
          member: member,
          book: book,
          borrowDate: DateTime.parse(raw['borrowDate']),
          returnDate: raw['returnDate'] != null
              ? DateTime.parse(raw['returnDate'])
              : null,
        );

        _borrowHistory.add(record);
        if (record.returnDate == null) {
          _records.add(record);
        }
      } catch (_) {}
    }
    notifyListeners();
  }

  List<Member> get members => _members;
  List<Book> get books => _books;
  List<BorrowRecord> get records => _records;
  List<String> get availableClassifications => _availableClassifications;

  Map<String, List<Book>> get booksByClassification {
    Map<String, List<Book>> map = {};
    for (var book in _books) {
      if (!map.containsKey(book.classification)) map[book.classification] = [];
      map[book.classification]!.add(book);
    }
    return map;
  }

  List<Map<String, dynamic>> get dynamicChartData {
    List<Map<String, dynamic>> data = [];
    DateTime now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      DateTime target = now.subtract(Duration(days: i));
      int outCount = _borrowHistory
          .where(
            (r) =>
                r.borrowDate.year == target.year &&
                r.borrowDate.month == target.month &&
                r.borrowDate.day == target.day,
          )
          .length;

      int inCount = _borrowHistory
          .where(
            (r) =>
                r.returnDate != null &&
                r.returnDate!.year == target.year &&
                r.returnDate!.month == target.month &&
                r.returnDate!.day == target.day,
          )
          .length;

      data.add({
        'day': _getDayName(target.weekday),
        'in': inCount.toDouble(),
        'out': outCount.toDouble(),
      });
    }
    return data;
  }

  String _getDayName(int weekday) {
    const days = {
      1: 'Sen',
      2: 'Sel',
      3: 'Rab',
      4: 'Kam',
      5: 'Jum',
      6: 'Sab',
      7: 'Min',
    };
    return days[weekday] ?? '';
  }

  Map<String, int> getMemberStats(String memberCode) {
    final now = DateTime.now();
    int daily = 0, weekly = 0, monthly = 0;

    for (var record in _borrowHistory) {
      if (record.member.memberCode == memberCode) {
        final daysDiff = now.difference(record.borrowDate).inDays;
        if (record.borrowDate.year == now.year &&
            record.borrowDate.month == now.month &&
            record.borrowDate.day == now.day)
          daily++;
        if (daysDiff <= 7) weekly++;
        if (daysDiff <= 30) monthly++;
      }
    }
    return {'daily': daily, 'weekly': weekly, 'monthly': monthly};
  }

  List<int>? exportToExcelBytes() {
    var excel = Excel.createExcel();
    Sheet sheetBooks = excel['Data Buku'];
    sheetBooks.appendRow([
      TextCellValue('Judul Buku'),
      TextCellValue('Klasifikasi'),
      TextCellValue('Subjek'),
      TextCellValue('Penulis'),
    ]);
    for (var book in _books) {
      sheetBooks.appendRow([
        TextCellValue(book.title),
        TextCellValue(book.classification),
        TextCellValue(book.subject),
        TextCellValue(book.author),
      ]);
    }

    Sheet sheetMembers = excel['Data Anggota'];
    sheetMembers.appendRow([
      TextCellValue('Kode Anggota'),
      TextCellValue('Nama Lengkap'),
      TextCellValue('Jenjang'),
    ]);
    for (var member in _members) {
      sheetMembers.appendRow([
        TextCellValue(member.memberCode),
        TextCellValue(member.name),
        TextCellValue(member.jenjang),
      ]);
    }
    return excel.encode();
  }

  String _parseCellValue(Data? cell) {
    if (cell == null || cell.value == null) return '';
    final val = cell.value;
    if (val is TextCellValue) return val.value.toString();
    if (val is IntCellValue) return val.value.toString();
    if (val is DoubleCellValue) return val.value.toString();
    return val.toString();
  }

  // --- FIX SORTIR OPTIMIZATION: Disortir berdasarkan klasifikasi sebelum auto-numbering ---
  String importFromExcelBytes(List<int> bytes) {
    try {
      var excel = Excel.decodeBytes(bytes);
      int importedBooks = 0;
      int importedMembers = 0;

      if (excel.tables.containsKey('Data Buku')) {
        var table = excel.tables['Data Buku']!;
        List<Map<String, String>> temporaryRows = [];

        // 1. Kumpulkan seluruh data mentah baris Excel
        for (int i = 1; i < table.maxRows; i++) {
          var row = table.rows[i];
          if (row.length >= 1) {
            String title = _parseCellValue(row[0]);
            if (title.isEmpty) continue;

            String clsf = row.length >= 2
                ? _parseCellValue(row[1]).trim().toUpperCase()
                : 'A';
            String sbjt = row.length >= 3 ? _parseCellValue(row[2]) : '300';
            String auth = row.length >= 4 ? _parseCellValue(row[3]) : '-';

            temporaryRows.add({
              'title': title,
              'classification': clsf.isEmpty ? 'A' : clsf,
              'subject': sbjt.isEmpty ? '300' : sbjt,
              'author': auth.isEmpty ? '-' : auth,
            });
          }
        }

        // 2. PROSES SORTIR UTAMA: Urutkan data Excel berdasarkan Klasifikasi (A -> B1 -> B2 dst.)
        temporaryRows.sort(
          (a, b) => a['classification']!.compareTo(b['classification']!),
        );

        // 3. Masukkan ke database dengan penomoran urut yang sudah rapi tersortir
        for (int i = 0; i < temporaryRows.length; i++) {
          var item = temporaryRows[i];
          String clsf = item['classification']!;

          int currentClassCount = _books
              .where((b) => b.classification == clsf)
              .length;
          int nextNumber = currentClassCount + 1;
          // Menggunakan padLeft(3, '0') agar menghasilkan kode standar rapi seperti B2-001
          String autoBookCode =
              '$clsf-${nextNumber.toString().padLeft(3, '0')}';

          final newBook = Book(
            id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
            bookCode: autoBookCode,
            title: item['title']!,
            classification: clsf,
            subject: item['subject']!,
            author: item['author']!,
          );

          _books.add(newBook);
          DatabaseHelper.instance.insertBook(newBook);
          addClassification(clsf);
          importedBooks++;
        }
      }

      if (excel.tables.containsKey('Data Anggota')) {
        var table = excel.tables['Data Anggota']!;
        for (int i = 1; i < table.maxRows; i++) {
          var row = table.rows[i];
          if (row.length >= 2) {
            String code = _parseCellValue(row[0]);
            String name = _parseCellValue(row[1]);
            if (code.isEmpty || name.isEmpty) continue;

            String jnjg = row.length >= 3 ? _parseCellValue(row[2]) : 'SD';

            if (!_members.any((m) => m.memberCode == code)) {
              final newMember = Member(
                id:
                    DateTime.now().millisecondsSinceEpoch.toString() +
                    i.toString(),
                memberCode: code,
                name: name,
                jenjang: jnjg.isEmpty ? 'SD' : jnjg,
              );
              _members.add(newMember);
              DatabaseHelper.instance.insertMember(newMember);
              importedMembers++;
            }
          }
        }
      }

      // Pastikan list internal selalu terurut rapi setelah ada penambahan data baru
      _books.sort((a, b) => a.bookCode.compareTo(b.bookCode));
      notifyListeners();
      return 'Berhasil Mengimpor $importedBooks Buku & $importedMembers Anggota!';
    } catch (e) {
      return 'Gagal membaca format file Excel.';
    }
  }

  void addClassification(String newClassification) {
    String formatted = newClassification.trim().toUpperCase();
    if (formatted.isNotEmpty &&
        !_availableClassifications.contains(formatted)) {
      _availableClassifications.add(formatted);
      notifyListeners();
    }
  }

  void addBook(
    String title,
    String classification,
    String subject,
    String author,
  ) async {
    String cleanClass = classification.trim().toUpperCase();
    int currentClassCount = _books
        .where((b) => b.classification == cleanClass)
        .length;
    int nextNumber = currentClassCount + 1;
    String autoBookCode =
        '$cleanClass-${nextNumber.toString().padLeft(3, '0')}';

    final newBook = Book(
      id: DateTime.now().toString(),
      bookCode: autoBookCode,
      title: title,
      classification: cleanClass,
      subject: subject,
      author: author,
    );

    _books.add(newBook);
    await DatabaseHelper.instance.insertBook(newBook);
    _books.sort((a, b) => a.bookCode.compareTo(b.bookCode));
    notifyListeners();
  }

  void addMember(String name, String jenjang) async {
    int nextNumber = _members.length + 1;
    String autoCode = 'ANG-${nextNumber.toString().padLeft(3, '0')}';
    final newMember = Member(
      id: DateTime.now().toString(),
      memberCode: autoCode,
      name: name,
      jenjang: jenjang,
    );

    _members.add(newMember);
    await DatabaseHelper.instance.insertMember(newMember);
    notifyListeners();
  }

  void editMember(String id, String newName, String newJenjang) async {
    final index = _members.indexWhere((m) => m.id == id);
    if (index != -1) {
      final updated = Member(
        id: id,
        memberCode: _members[index].memberCode,
        name: newName,
        jenjang: newJenjang,
      );
      _members[index] = updated;
      await DatabaseHelper.instance.updateMember(updated);
      notifyListeners();
    }
  }

  String deleteMember(String memberCode) {
    if (_records.any((r) => r.member.memberCode == memberCode))
      return 'Gagal: Anggota sedang meminjam buku!';
    _members.removeWhere((m) => m.memberCode == memberCode);
    DatabaseHelper.instance.deleteMember(memberCode);
    notifyListeners();
    return 'Anggota berhasil dihapus!';
  }

  String deleteBook(String bookCode) {
    final book = _books.firstWhere((b) => b.bookCode == bookCode);
    if (book.isBorrowed) return 'Gagal: Buku sedang dipinjam!';
    _books.remove(book);
    DatabaseHelper.instance.deleteBook(bookCode);
    notifyListeners();
    return 'Buku berhasil dihapus!';
  }

  String processBorrow(String memberCode, String bookCode) {
    try {
      final member = _members.firstWhere((m) => m.memberCode == memberCode);
      final book = _books.firstWhere((b) => b.bookCode == bookCode);
      if (book.isBorrowed) return 'Buku sedang dipinjam!';

      book.isBorrowed = true;
      DatabaseHelper.instance.updateBookStatus(bookCode, true);

      final newRecord = BorrowRecord(
        id: DateTime.now().toString(),
        member: member,
        book: book,
        borrowDate: DateTime.now(),
      );

      _records.add(newRecord);
      _borrowHistory.add(newRecord);
      DatabaseHelper.instance.insertBorrowRecord(newRecord);
      notifyListeners();
      return 'Berhasil dipinjam!';
    } catch (e) {
      return 'Kode Anggota atau Kode Buku tidak ditemukan!';
    }
  }

  String processReturn(String bookCode) {
    try {
      final book = _books.firstWhere((b) => b.bookCode == bookCode);
      if (!book.isBorrowed) return 'Buku ini sedang tidak dipinjam.';

      final activeRecord = _records.firstWhere(
        (r) => r.book.bookCode == bookCode,
      );
      final historyRecord = _borrowHistory.lastWhere(
        (r) => r.id == activeRecord.id,
      );

      final now = DateTime.now();
      historyRecord.returnDate = now;
      DatabaseHelper.instance.updateBorrowRecordReturn(activeRecord.id, now);

      book.isBorrowed = false;
      DatabaseHelper.instance.updateBookStatus(bookCode, false);
      _records.remove(activeRecord);
      notifyListeners();
      return 'Buku berhasil dikembalikan!';
    } catch (e) {
      return 'Kode Buku tidak valid atau tidak ditemukan.';
    }
  }

  String checkBookStatusByTitle(String title) {
    if (title.isEmpty) return '';
    try {
      final book = _books.firstWhere(
        (b) => b.title.toLowerCase().contains(title.toLowerCase()),
      );
      if (book.isBorrowed) {
        final record = _records.firstWhere(
          (r) => r.book.bookCode == book.bookCode,
        );
        return 'Buku "${book.title}" dipinjam oleh ${record.member.name}';
      }
      return 'Buku "${book.title}" TERSEDIA.';
    } catch (e) {
      return 'Buku tidak ditemukan.';
    }
  }
}
