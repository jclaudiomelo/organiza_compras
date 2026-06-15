import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../controllers/purchase_controller.dart';

class ReportsScreen extends StatefulWidget {
  final PurchaseController controller;

  const ReportsScreen({super.key, required this.controller});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final NumberFormat _currencyFormat = NumberFormat.simpleCurrency(locale: 'pt_BR');
  int _touchedIndex = -1;

  Map<String, dynamic>? _getCategoryData(String categoryName) {
    try {
      return widget.controller.categories.firstWhere(
        (c) => c['name'] == categoryName,
      );
    } catch (_) {
      return null;
    }
  }

  Color _getCategoryColor(String categoryName) {
    final data = _getCategoryData(categoryName);
    if (data != null) {
      return Color(data['color'] as int);
    }
    return Colors.blueGrey;
  }

  IconData _getCategoryIcon(String categoryName) {
    final data = _getCategoryData(categoryName);
    if (data != null) {
      return IconData(data['icon_code'] as int, fontFamily: 'MaterialIcons');
    }
    return Icons.shopping_bag;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      appBar: AppBar(
        title: const Text('Relatório de Gastos', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F0E17),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final totalSpent = widget.controller.totalSpent;
          final rawCategoryData = widget.controller.categorySpending;

          // Remove categories with 0 spent
          final categoryData = Map<String, double>.fromEntries(
            rawCategoryData.entries.where((e) => e.value > 0),
          );

          if (totalSpent == 0 || categoryData.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.pie_chart_outline_rounded,
                      size: 72,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sem dados para relatórios',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Escanear cupons de NFC-e preencherá automaticamente os gráficos de gastos por categoria.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            );
          }

          // Generate sections for Pie Chart
          final List<PieChartSectionData> sections = [];
          int index = 0;
          categoryData.forEach((category, value) {
            final percentage = (value / totalSpent) * 100;
            final isTouched = index == _touchedIndex;
            final radius = isTouched ? 60.0 : 50.0;
            final fontSize = isTouched ? 16.0 : 12.0;

            sections.add(
              PieChartSectionData(
                color: _getCategoryColor(category),
                value: value,
                title: '${percentage.toStringAsFixed(0)}%',
                radius: radius,
                titleStyle: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            );
            index++;
          });

          return SingleChildScrollView(
            child: Column(
              children: [
                // Total Spent banner
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                  child: Column(
                    children: [
                      const Text(
                        'Total Acumulado em Compras',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currencyFormat.format(totalSpent),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),

                // Interactive Donut Chart
                SizedBox(
                  height: 220,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 4,
                      centerSpaceRadius: 60,
                      sections: sections,
                    ),
                  ),
                ),

                // Category Breakdowns Title
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Resumo por Categoria',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Category Cards list
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: categoryData.length,
                    itemBuilder: (context, idx) {
                      final entry = categoryData.entries.elementAt(idx);
                      final category = entry.key;
                      final spent = entry.value;
                      final percentage = (spent / totalSpent) * 100;
                      final catColor = _getCategoryColor(category);

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16161A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.04)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: catColor.withOpacity(0.12),
                                  radius: 18,
                                  child: Icon(
                                    _getCategoryIcon(category),
                                    color: catColor,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        category,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${percentage.toStringAsFixed(1)}% do total',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _currencyFormat.format(spent),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Linear percent indicator bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: spent / totalSpent,
                                minHeight: 6,
                                backgroundColor: Colors.white10,
                                valueColor: AlwaysStoppedAnimation<Color>(catColor),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}
