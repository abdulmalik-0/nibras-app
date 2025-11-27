
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:nibras_app/models/category_model.dart';
import 'package:nibras_app/screens/category_management_page.dart';
import 'package:nibras_app/screens/question_management_page.dart';
import 'package:nibras_app/screens/reported_questions_page.dart';
import 'package:nibras_app/screens/user_management_page.dart';
import 'package:nibras_app/services/auth_service.dart';
import 'package:nibras_app/services/supabase_service.dart';
import 'package:nibras_app/widgets/admin_layout.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final _authService = AuthService();
  final _supabaseService = SupabaseService();
  
  bool _isLoading = true;
  
  // Stats data
  List<Map<String, dynamic>> _questionCounts = [];
  Map<String, dynamic> _reportStats = {};
  List<Map<String, dynamic>> _topAdmins = [];
  List<Map<String, dynamic>> _mostPlayed = [];
  List<CategoryModel> _categories = [];
  
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final results = await Future.wait([
        _supabaseService.getCategoryQuestionCounts(),
        _supabaseService.getReportStats(),
        _supabaseService.getTopAdminResolvers(),
        _supabaseService.getMostPlayedCategories(),
        _supabaseService.getCategories(),
      ]);

      if (mounted) {
        setState(() {
          _questionCounts = results[0] as List<Map<String, dynamic>>;
          _reportStats = results[1] as Map<String, dynamic>;
          _topAdmins = results[2] as List<Map<String, dynamic>>;
          _mostPlayed = results[3] as List<Map<String, dynamic>>;
          _categories = results[4] as List<CategoryModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getCategoryName(String id) {
    final category = _categories.firstWhere(
      (c) => c.id == id,
      orElse: () => CategoryModel(
        id: id,
        nameAr: id,
        name: id,
        icon: 'help',
        color: '#000000',
        order: 0,
      ),
    );
    return category.nameAr;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF151521),
        body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      );
    }

    return AdminLayout(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsGrid(),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildActivityChart()),
                const SizedBox(width: 24),
                Expanded(child: _buildStatusChart()),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('توزيع الأسئلة'),
            _buildQuestionDistributionTable(),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('أكثر الفئات لعباً'),
                      _buildMostPlayedList(),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('أفضل المشرفين'),
                      _buildTopAdminsList(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 24,
      mainAxisSpacing: 24,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('إجمالي البلاغات', (_reportStats['total_reports'] ?? 0).toString(), Icons.report, Colors.orange),
        _buildStatCard('الأسئلة', _questionCounts.fold<int>(0, (sum, item) => sum + (item['count'] as int)).toString(), Icons.quiz, Colors.blue),
        _buildStatCard('الفئات', _categories.length.toString(), Icons.category, Colors.purple),
        _buildStatCard('المشرفين', _topAdmins.length.toString(), Icons.people, Colors.green),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChart() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'نشاط التطبيق',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return const FlLine(
                      color: Color(0xFF2A2A3C),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(color: Colors.grey, fontSize: 12);
                        switch (value.toInt()) {
                          case 0: return const Text('السبت', style: style);
                          case 2: return const Text('الاثنين', style: style);
                          case 4: return const Text('الأربعاء', style: style);
                          case 6: return const Text('الجمعة', style: style);
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 12));
                      },
                      reservedSize: 42,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 6,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3),
                      FlSpot(1, 1),
                      FlSpot(2, 4),
                      FlSpot(3, 2),
                      FlSpot(4, 5),
                      FlSpot(5, 3),
                      FlSpot(6, 4),
                    ],
                    isCurved: true,
                    color: Colors.blueAccent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blueAccent.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChart() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'حالة البلاغات',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 20,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(color: Colors.grey, fontSize: 12);
                        switch (value.toInt()) {
                          case 0: return const Text('جديد', style: style);
                          case 1: return const Text('قيد الحل', style: style);
                          case 2: return const Text('مغلق', style: style);
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [BarChartRodData(toY: 8, color: Colors.redAccent, width: 20, borderRadius: BorderRadius.circular(4))],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [BarChartRodData(toY: 12, color: Colors.orangeAccent, width: 20, borderRadius: BorderRadius.circular(4))],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [BarChartRodData(toY: 15, color: Colors.greenAccent, width: 20, borderRadius: BorderRadius.circular(4))],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, right: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildQuestionDistributionTable() {
    final Map<String, Map<String, int>> groupedCounts = {};
    for (var item in _questionCounts) {
      final catId = item['category_id'] as String;
      final diff = item['difficulty'] as String;
      final count = item['count'] as int;

      if (!groupedCounts.containsKey(catId)) {
        groupedCounts[catId] = {'easy': 0, 'medium': 0, 'hard': 0};
      }
      groupedCounts[catId]![diff] = count;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.black.withOpacity(0.3)),
                  dataRowColor: MaterialStateProperty.all(Colors.transparent),
                  columnSpacing: constraints.maxWidth < 600 ? 20 : (constraints.maxWidth - 200) / 5,
                  horizontalMargin: 20,
                  columns: const [
                    DataColumn(label: Text('الفئة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                    DataColumn(label: Text('سهل', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent))),
                    DataColumn(label: Text('وسط', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent))),
                    DataColumn(label: Text('صعب', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent))),
                    DataColumn(label: Text('المجموع', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent))),
                  ],
                  rows: groupedCounts.entries.map((entry) {
                    final catId = entry.key;
                    final counts = entry.value;
                    final total = (counts['easy'] ?? 0) + (counts['medium'] ?? 0) + (counts['hard'] ?? 0);

                    return DataRow(cells: [
                      DataCell(Text(_getCategoryName(catId), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      DataCell(Text((counts['easy'] ?? 0).toString(), style: const TextStyle(color: Colors.white70))),
                      DataCell(Text((counts['medium'] ?? 0).toString(), style: const TextStyle(color: Colors.white70))),
                      DataCell(Text((counts['hard'] ?? 0).toString(), style: const TextStyle(color: Colors.white70))),
                      DataCell(Text(total.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                    ]);
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMostPlayedList() {
    if (_mostPlayed.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2D),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('لا توجد بيانات كافية', style: TextStyle(color: Colors.white70))),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _mostPlayed.length,
        separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.1), height: 1),
        itemBuilder: (context, index) {
          final item = _mostPlayed[index];
          final catId = item['category_id'] as String;
          final count = item['play_count'] as int;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            title: Text(_getCategoryName(catId), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count مرة',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopAdminsList() {
    if (_topAdmins.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2D),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('لا توجد بيانات', style: TextStyle(color: Colors.white70))),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _topAdmins.length,
        separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.1), height: 1),
        itemBuilder: (context, index) {
          final item = _topAdmins[index];
          final email = item['email'] as String;
          final count = item['resolved_count'] as int;

          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.greenAccent,
              child: Icon(Icons.person, color: Colors.black87),
            ),
            title: Text(email, style: const TextStyle(color: Colors.white)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
              ),
              child: Text(
                '$count حل',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent),
              ),
            ),
          );
        },
      ),
    );
  }
}

