class Member {
  final String id;
  final String memberCode;
  final String name;
  final String jenjang;

  Member({
    required this.id,
    required this.memberCode,
    required this.name,
    required this.jenjang,
  });
}

class Book {
  final String id;
  final String
  bookCode; // Tetap ada secara internal sebagai Nomor Inventaris Otomatis
  final String title;
  final String classification;
  final String subject;
  final String author;
  bool isBorrowed;

  Book({
    required this.id,
    required this.bookCode,
    required this.title,
    required this.classification,
    required this.subject,
    required this.author,
    this.isBorrowed = false,
  });
}

class BorrowRecord {
  final String id;
  final Member member;
  final Book book;
  final DateTime borrowDate;
  DateTime? returnDate;

  BorrowRecord({
    required this.id,
    required this.member,
    required this.book,
    required this.borrowDate,
    this.returnDate,
  });
}
