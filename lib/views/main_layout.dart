import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'member_view.dart';
import 'book_view.dart';
import 'borrow_view.dart';
import 'dashboard_view.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  Widget _currentView = const DashboardView();
  String _appBarTitle = 'Dashboard Perpustakaan';

  // Tambahkan parameter isMobile untuk mengecek apakah perlu menutup drawer
  void _onMenuTap(Widget view, String title, bool isMobile) {
    setState(() {
      _currentView = view;
      _appBarTitle = title;
    });

    // Hanya tutup sidebar (pop) jika sedang di tampilan Mobile (Drawer)
    if (isMobile) {
      Navigator.pop(context);
    }
  }

  // Pisahkan isi menu ke dalam fungsi agar bisa dipakai ulang di Mobile dan Windows
  Widget _buildMenuContent(bool isMobile) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const DrawerHeader(
          decoration: BoxDecoration(color: AppTheme.primary),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.local_library, size: 48, color: Colors.white),
              SizedBox(height: 12),
              Text(
                'Admin Perpustakaan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.dashboard, color: AppTheme.textDark),
          title: const Text('Dashboard'),
          onTap: () =>
              _onMenuTap(const DashboardView(), 'Dashboard Admin', isMobile),
        ),
        ListTile(
          leading: const Icon(Icons.sync_alt, color: AppTheme.textDark),
          title: const Text('Transaksi'),
          onTap: () => _onMenuTap(
            const BorrowView(),
            'Peminjaman & Pengembalian',
            isMobile,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.people_alt, color: AppTheme.textDark),
          title: const Text('Kelola Anggota'),
          onTap: () => _onMenuTap(const MemberView(), 'Data Anggota', isMobile),
        ),
        ListTile(
          leading: const Icon(Icons.menu_book, color: AppTheme.textDark),
          title: const Text('Katalog & Kode Buku'),
          onTap: () => _onMenuTap(const BookView(), 'Katalog Buku', isMobile),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Deteksi ukuran layar (jika lebar >= 800, anggap sebagai Windows/Desktop)
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: AppBar(title: Text(_appBarTitle)),

      // Jika di Mobile, gunakan Drawer (bisa di-swipe dari kiri)
      // Jika di Windows/Desktop, matikan Drawer
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: AppTheme.background,
              child: _buildMenuContent(true),
            ),

      body: isDesktop
          // Tampilan Windows/Desktop: Sidebar permanen di kiri, konten di kanan
          ? Row(
              children: [
                Container(
                  width: 250, // Lebar sidebar permanen
                  color: AppTheme.background,
                  child: _buildMenuContent(false),
                ),
                const VerticalDivider(width: 1, thickness: 1), // Garis pembatas
                Expanded(child: _currentView),
              ],
            )
          // Tampilan Mobile: Konten memenuhi layar, sidebar disembunyikan di dalam Drawer
          : _currentView,
    );
  }
}
