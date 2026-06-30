import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/purchase_controller.dart';

class ProductHistoryScreen extends StatefulWidget {
  final String productName;
  final PurchaseController controller;

  const ProductHistoryScreen({
    super.key,
    required this.productName,
    required this.controller,
  });

  @override
  State<ProductHistoryScreen> createState() => _ProductHistoryScreenState();
}

class _ProductHistoryScreenState extends State<ProductHistoryScreen> {
  final NumberFormat _currencyFormat = NumberFormat.simpleCurrency(locale: 'pt_BR');
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await widget.controller.getProductPriceHistory(widget.productName);
    setState(() {
      _history = history;
      _isLoading = false;
    });
  }

  double _getMinPrice() {
    if (_history.isEmpty) return 0;
    return _history.map((e) => e['unit_price'] as double).reduce((a, b) => a < b ? a : b);
  }

  double _getMaxPrice() {
    if (_history.isEmpty) return 0;
    return _history.map((e) => e['unit_price'] as double).reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final minPrice = _getMinPrice();
    final maxPrice = _getMaxPrice();
    
    // Setup data points for line chart
    List<FlSpot> spots = [];
    for (int i = 0; i < _history.length; i++) {
      double price = _history[i]['unit_price'] as double;
      final quantity = (_history[i]['quantity'] as num?)?.toDouble() ?? 1.0;
      final totalPrice = (_history[i]['total_price'] as num?)?.toDouble() ?? (quantity * price);
      
      if (price == totalPrice && quantity != 1.0 && quantity > 0) {
        price = totalPrice / quantity;
      }
      
      spots.add(FlSpot(i.toDouble(), price));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      appBar: AppBar(
        title: const Text('Histórico de Preços', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F0E17),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent))
          : _history.isEmpty
              ? Center(
                  child: Text(
                    'Sem histórico para este produto',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    // Product Header Details Card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16161A),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.withOpacity(0.08)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.productName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStatBlock('Menor Preço', _currencyFormat.format(minPrice), Colors.greenAccent),
                                  _buildStatBlock('Maior Preço', _currencyFormat.format(maxPrice), Colors.redAccent),
                                  _buildStatBlock('Variação', 
                                    maxPrice > 0 ? '${((maxPrice - minPrice) / minPrice * 100).toStringAsFixed(1)}%' : '0%', 
                                    Colors.orangeAccent
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Price Chart (Show only if we have at least 2 points to draw a line)
                    if (spots.length >= 2)
                      SliverToBoxAdapter(
                        child: Container(
                          height: 220,
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.only(top: 24, bottom: 8, right: 24, left: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16161A),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.withOpacity(0.08)),
                          ),
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.grey.withOpacity(0.05),
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 46,
                                    getTitlesWidget: (value, meta) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: Text(
                                          _currencyFormat.format(value).replaceAll('R\$', '').trim(),
                                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index >= 0 && index < _history.length) {
                                        final dateStr = _history[index]['date'] as String;
                                        final date = DateTime.tryParse(dateStr) ?? DateTime.now();
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 6.0),
                                          child: Text(
                                            DateFormat('dd/MM').format(date),
                                            style: const TextStyle(color: Colors.grey, fontSize: 9),
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                    reservedSize: 22,
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              minX: 0,
                              maxX: (spots.length - 1).toDouble(),
                              minY: minPrice * 0.9,
                              maxY: maxPrice * 1.1,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: true,
                                  color: Colors.deepPurpleAccent,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.deepPurpleAccent.withOpacity(0.15),
                                  ),
                                ),
                              ],
                              lineTouchData: LineTouchData(
                                touchTooltipData: LineTouchTooltipData(
                                  tooltipBgColor: const Color(0xFF16161A),
                                  getTooltipItems: (touchedSpots) {
                                    return touchedSpots.map((spot) {
                                      final index = spot.x.toInt();
                                      final item = _history[index];
                                      final dateStr = item['date'] as String;
                                      final date = DateTime.tryParse(dateStr) ?? DateTime.now();
                                      final store = item['store_name'] as String;
                                      return LineTooltipItem(
                                        '${_currencyFormat.format(spot.y)}\n${_dateFormat.format(date)}\n$store',
                                        const TextStyle(color: Colors.white, fontSize: 10),
                                      );
                                    }).toList();
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // History Title
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Text(
                          'Comparativo de Compras',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // History entries list
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          // Show list in reverse chronological order
                          final item = _history[_history.length - 1 - index];
                          double price = item['unit_price'] as double;
                          final dateStr = item['date'] as String;
                          final date = DateTime.tryParse(dateStr) ?? DateTime.now();
                          final storeName = item['store_name'] as String;
                          
                          final quantity = (item['quantity'] as num?)?.toDouble() ?? 1.0;
                          final unit = (item['unit'] as String?) ?? 'UN';
                          final totalPrice = (item['total_price'] as num?)?.toDouble() ?? (quantity * price);

                          if (price == totalPrice && quantity != 1.0 && quantity > 0) {
                            price = totalPrice / quantity;
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16161A),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.withOpacity(0.08)),
                              ),
                              child: Row(
                                children: [
                                  // Bullet Icon
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurpleAccent.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.calendar_today,
                                      color: Colors.deepPurpleAccent,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  // Detail
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          storeName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_dateFormat.format(date)}  •  ${quantity.toStringAsFixed(unit.toUpperCase() == 'KG' ? 3 : 0)} $unit',
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Price
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _currencyFormat.format(price),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Total: ${_currencyFormat.format(totalPrice)}',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: _history.length,
                      ),
                    ),
                    
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 40),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStatBlock(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[500], fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
