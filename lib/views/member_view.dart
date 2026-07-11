import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/library_viewmodel.dart';
import '../theme/app_theme.dart';

class MemberView extends StatefulWidget {
  const MemberView({super.key});

  @override
  State<MemberView> createState() => _MemberViewState();
}

class _MemberViewState extends State<MemberView> {
  final nameCtrl = TextEditingController();
  String? selectedJenjang;
  final List<String> jenjangList = ['TK', 'SD', 'SMP', 'SMA', 'Umum'];

  // Variabel untuk menyimpan kata kunci pencarian
  String searchQuery = '';

  void _showMemberDialog(
    BuildContext context,
    LibraryViewModel vm, {
    var member,
  }) {
    if (member != null) {
      nameCtrl.text = member.name;
      selectedJenjang = member.jenjang;
    } else {
      nameCtrl.clear();
      selectedJenjang = null;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          member == null ? 'Tambah Anggota Baru' : 'Edit Data Anggota',
          style: const TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap (Sesuai KTP/KK/Kartu Pelajar)',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedJenjang,
              decoration: const InputDecoration(
                labelText: 'Jenjang Pendidikan',
              ),
              items: jenjangList
                  .map((j) => DropdownMenuItem(value: j, child: Text(j)))
                  .toList(),
              onChanged: (val) => setState(() => selectedJenjang = val),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && selectedJenjang != null) {
                if (member == null) {
                  vm.addMember(nameCtrl.text, selectedJenjang!);
                } else {
                  vm.editMember(member.id, nameCtrl.text, selectedJenjang!);
                }
                Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, LibraryViewModel vm, var member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Anggota', style: TextStyle(color: Colors.red)),
        content: Text('Hapus ${member.name} dari daftar keanggotaan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              final msg = vm.deleteMember(member.memberCode);
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

    // LOGIKA PENCARIAN REAL-TIME
    // Menyaring anggota berdasarkan Nama atau Kode Anggota yang diketik
    final filteredMembers = vm.members.where((m) {
      final query = searchQuery.toLowerCase();
      final nameLower = m.name.toLowerCase();
      final codeLower = m.memberCode.toLowerCase();

      return nameLower.contains(query) || codeLower.contains(query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // KOTAK PENCARIAN (SEARCH BAR)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) {
                // Memperbarui UI setiap kali ada huruf yang diketik
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari nama warga atau nomor anggota yang lupa...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            searchQuery = '';
                            // Hapus fokus dari keyboard jika tombol X ditekan (opsional)
                            FocusScope.of(context).unfocus();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // TOMBOL TAMBAH ANGGOTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text(
                'Daftarkan Anggota Baru',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              onPressed: () => _showMemberDialog(context, vm),
            ),
          ),

          const Divider(height: 40, thickness: 1),

          // DAFTAR ANGGOTA (HASIL PENCARIAN)
          Expanded(
            child: filteredMembers.isEmpty
                ? const Center(
                    child: Text(
                      'Tidak ada anggota yang cocok dengan pencarian.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredMembers.length,
                    itemBuilder: (context, index) {
                      final member = filteredMembers[index];
                      // Ambil statistik peminjaman warga ini untuk ditampilkan
                      final stats = vm.getMemberStats(member.memberCode);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 1.5,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primary.withOpacity(0.15),
                            radius: 24,
                            child: const Icon(
                              Icons.person,
                              color: AppTheme.primary,
                              size: 28,
                            ),
                          ),
                          title: Text(
                            member.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'ID: ${member.memberCode} | Jenjang: ${member.jenjang}',
                              ),
                              const SizedBox(height: 4),
                              // Indikator keaktifan baca warga
                              Text(
                                'Aktif Pinjam: ${stats['monthly']} buku (Bulan ini)',
                                style: TextStyle(
                                  color: Colors.teal.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blueAccent,
                                ),
                                onPressed: () => _showMemberDialog(
                                  context,
                                  vm,
                                  member: member,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () =>
                                    _confirmDelete(context, vm, member),
                              ),
                            ],
                          ),
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
