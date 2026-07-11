import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import '../viewmodels/library_viewmodel.dart';
import '../theme/app_theme.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  void _handleImportExcel(BuildContext context, LibraryViewModel vm) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null) {
      String msg = '';
      if (result.files.single.bytes != null) {
        msg = vm.importFromExcelBytes(result.files.single.bytes!);
      } else if (result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        msg = vm.importFromExcelBytes(bytes);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: msg.contains('Gagal')
              ? Colors.red
              : AppTheme.primary,
        ),
      );
    }
  }

  void _handleExportExcel(BuildContext context, LibraryViewModel vm) async {
    final bytes = vm.exportToExcelBytes();
    if (bytes == null) return;

    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Simpan Backup Data Excel:',
      fileName: 'Backup_Perpustakaan_Widyaloka.xlsx',
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (outputFile != null) {
      final file = File(outputFile);
      await file.writeAsBytes(bytes);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data berhasil diexport ke format Excel!'),
          backgroundColor: AppTheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<LibraryViewModel>(context);
    final chartData = vm.dynamicChartData;

    const colorIn = Colors.cyanAccent;
    const colorOut = Colors.pinkAccent;
    const cardGradient = LinearGradient(
      colors: [Color(0xFF1E1E2C), Color(0xFF2D2D44)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // JUDUL UTAMA
          const Text(
            'Perpustakaan Widyaloka Desa Nusawungu',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),

          // TOMBOL EXCEL (Diturunkan ke bawah judul)
          Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(
                  Icons.file_upload_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text(
                  'Import File Excel',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => _handleImportExcel(context, vm),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(
                  Icons.file_download_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text(
                  'Export File Excel',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => _handleExportExcel(context, vm),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // KARTU STATISTIK
          Row(
            children: [
              Expanded(
                child: _buildModernStatCard(
                  'Total Buku Perpus',
                  vm.books.length.toString(),
                  Icons.menu_book_rounded,
                  Colors.purpleAccent,
                  cardGradient,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildModernStatCard(
                  'Total Anggota',
                  vm.members.length.toString(),
                  Icons.people_alt_rounded,
                  Colors.blueAccent,
                  cardGradient,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildModernStatCard(
                  'Sedang Dipinjam',
                  vm.records.length.toString(),
                  Icons.timelapse_rounded,
                  colorOut,
                  cardGradient,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // HEADER GRAFIK
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '(7 Hari Terakhir)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              Row(
                children: [
                  _buildLegend(colorIn, 'Buku Masuk'),
                  const SizedBox(width: 16),
                  _buildLegend(colorOut, 'Buku Keluar'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // GRAFIK INTERAKTIF FL_CHART
          Container(
            height: 350,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: cardGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: chartData.every((d) => d['in'] == 0 && d['out'] == 0)
                ? const Center(
                    child: Text(
                      'Belum ada transaksi peminjaman/pengembalian\ndalam 7 hari terakhir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxY(chartData),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) => Colors.black87,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            String type = rodIndex == 0 ? 'Masuk' : 'Keluar';
                            return BarTooltipItem(
                              '$type\n${rod.toY.toInt()} Buku',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 &&
                                  value.toInt() < chartData.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    chartData[value.toInt()]['day'],
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              if (value % 1 == 0) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.white.withOpacity(0.1),
                          strokeWidth: 1,
                        ),
                      ),
                      barGroups: List.generate(chartData.length, (index) {
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: chartData[index]['in'],
                              color: colorIn,
                              width: 12,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: _getMaxY(chartData),
                                color: Colors.white.withOpacity(0.05),
                              ),
                            ),
                            BarChartRodData(
                              toY: chartData[index]['out'],
                              color: colorOut,
                              width: 12,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: _getMaxY(chartData),
                                color: Colors.white.withOpacity(0.05),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  double _getMaxY(List<Map<String, dynamic>> chartData) {
    double max = 2.0;
    for (var data in chartData) {
      if (data['in'] > max) max = data['in'];
      if (data['out'] > max) max = data['out'];
    }
    return max + (max * 0.3);
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.6), blurRadius: 6),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildModernStatCard(
    String title,
    String value,
    IconData icon,
    Color iconColor,
    Gradient bgGradient,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
