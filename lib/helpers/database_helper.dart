import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/library_models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('perpustakaan_widyaloka.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // 1. Tabel Anggota
    await db.execute('''
      CREATE TABLE members (
        id TEXT PRIMARY KEY,
        memberCode TEXT UNIQUE,
        name TEXT,
        jenjang TEXT
      )
    ''');

    // 2. Tabel Buku
    await db.execute('''
      CREATE TABLE books (
        id TEXT PRIMARY KEY,
        bookCode TEXT UNIQUE,
        title TEXT,
        classification TEXT,
        subject TEXT,
        author TEXT,
        isBorrowed INTEGER
      )
    ''');

    // 3. Tabel Riwayat Transaksi (Untuk kebutuhan Grafik & Track Record)
    await db.execute('''
      CREATE TABLE borrow_records (
        id TEXT PRIMARY KEY,
        memberCode TEXT,
        bookCode TEXT,
        borrowDate TEXT,
        returnDate TEXT
      )
    ''');
  }

  // --- OPERASI TABEL ANGGOTA ---
  Future<void> insertMember(Member member) async {
    final db = await instance.database;
    await db.insert('members', {
      'id': member.id,
      'memberCode': member.memberCode,
      'name': member.name,
      'jenjang': member.jenjang,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<Member>> readAllMembers() async {
    final db = await instance.database;
    final result = await db.query('members');
    return result
        .map(
          (json) => Member(
            id: json['id'] as String,
            memberCode: json['memberCode'] as String,
            name: json['name'] as String,
            jenjang: json['jenjang'] as String,
          ),
        )
        .toList();
  }

  Future<void> updateMember(Member member) async {
    final db = await instance.database;
    await db.update(
      'members',
      {'name': member.name, 'jenjang': member.jenjang},
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  Future<void> deleteMember(String memberCode) async {
    final db = await instance.database;
    await db.delete(
      'members',
      where: 'memberCode = ?',
      whereArgs: [memberCode],
    );
  }

  // --- OPERASI TABEL BUKU ---
  Future<void> insertBook(Book book) async {
    final db = await instance.database;
    await db.insert('books', {
      'id': book.id,
      'bookCode': book.bookCode,
      'title': book.title,
      'classification': book.classification,
      'subject': book.subject,
      'author': book.author,
      'isBorrowed': book.isBorrowed ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<Book>> readAllBooks() async {
    final db = await instance.database;
    final result = await db.query('books');
    return result
        .map(
          (json) => Book(
            id: json['id'] as String,
            bookCode: json['bookCode'] as String,
            title: json['title'] as String,
            classification: json['classification'] as String,
            subject: json['subject'] as String,
            author: json['author'] as String,
            isBorrowed: json['isBorrowed'] == 1,
          ),
        )
        .toList();
  }

  Future<void> updateBookStatus(String bookCode, bool isBorrowed) async {
    final db = await instance.database;
    await db.update(
      'books',
      {'isBorrowed': isBorrowed ? 1 : 0},
      where: 'bookCode = ?',
      whereArgs: [bookCode],
    );
  }

  Future<void> deleteBook(String bookCode) async {
    final db = await instance.database;
    await db.delete('books', where: 'bookCode = ?', whereArgs: [bookCode]);
  }

  // --- OPERASI RIWAYAT TRANSAKSI ---
  Future<void> insertBorrowRecord(BorrowRecord record) async {
    final db = await instance.database;
    await db.insert('borrow_records', {
      'id': record.id,
      'memberCode': record.member.memberCode,
      'bookCode': record.book.bookCode,
      'borrowDate': record.borrowDate.toIso8601String(),
      'returnDate': record.returnDate?.toIso8601String(),
    });
  }

  Future<void> updateBorrowRecordReturn(
    String recordId,
    DateTime returnDate,
  ) async {
    final db = await instance.database;
    await db.update(
      'borrow_records',
      {'returnDate': returnDate.toIso8601String()},
      where: 'id = ?',
      whereArgs: [recordId],
    );
  }

  Future<List<Map<String, dynamic>>> readAllRawBorrowRecords() async {
    final db = await instance.database;
    return await db.query('borrow_records');
  }
}
