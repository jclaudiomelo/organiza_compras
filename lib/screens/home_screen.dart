import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/purchase_controller.dart';
import '../models/purchase.dart';
import 'scan_screen.dart';
import 'purchase_detail_screen.dart';
import 'reports_screen.dart';
import 'products_screen.dart';
import 'categories_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final PurchaseController controller;

  const HomeScreen({super.key, required this.controller});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NumberFormat _currencyFormat = NumberFormat.simpleCurrency(locale: 'pt_BR');
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  String _selectedFilter = 'Todos'; // 'Todos', 'Hoje', '7 dias', 'Este Mês', 'Mês Passado', 'Personalizado'
  DateTimeRange? _customDateRange;
  bool _showAllHistory = false;

  @override
  void initState() {
    super.initState();
    widget.controller.loadPurchases();
  }


  List<Purchase> get _filteredPurchases {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return widget.controller.purchases.where((purchase) {
      final localDate = purchase.date.toLocal();
      final purchaseDateOnly = DateTime(localDate.year, localDate.month, localDate.day);
      
      switch (_selectedFilter) {
        case 'Hoje':
          return purchaseDateOnly.year == today.year && 
                 purchaseDateOnly.month == today.month && 
                 purchaseDateOnly.day == today.day;
        case '7 dias':
          final sevenDaysAgo = today.subtract(const Duration(days: 7));
          return purchaseDateOnly.isAfter(sevenDaysAgo) || purchaseDateOnly.isAtSameMomentAs(sevenDaysAgo);
        case 'Este Mês':
          return localDate.year == now.year && localDate.month == now.month;
        case 'Mês Passado':
          final lastMonth = now.month == 1 ? 12 : now.month - 1;
          final year = now.month == 1 ? now.year - 1 : now.year;
          return localDate.year == year && localDate.month == lastMonth;
        case 'Personalizado':
          if (_customDateRange != null) {
            final start = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
            final end = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day).add(const Duration(days: 1));
            return purchaseDateOnly.isAfter(start.subtract(const Duration(seconds: 1))) && purchaseDateOnly.isBefore(end);
          }
          return true;
        default:
          return true;
      }
    }).toList();
  }

  double _calculateTotalSpent(List<Purchase> list) {
    return list.fold(0.0, (sum, p) => sum + p.totalValue);
  }

  int _countTotalItems(List<Purchase> list) {
    return list.fold(0, (sum, p) => sum + p.items.length);
  }

  Widget _buildFilterChip(String filter, {String? label}) {
    final isSelected = _selectedFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label ?? filter),
        selected: isSelected,
        onSelected: (selected) async {
          if (filter == 'Personalizado') {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 1)),
              initialDateRange: _customDateRange,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: Colors.deepPurpleAccent,
                      onPrimary: Colors.white,
                      surface: Color(0xFF16161A),
                      onSurface: Colors.white,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() {
                _selectedFilter = 'Personalizado';
                _customDateRange = picked;
              });
            }
          } else {
            setState(() {
              _selectedFilter = filter;
            });
          }
        },
        selectedColor: Colors.deepPurpleAccent,
        backgroundColor: const Color(0xFF16161A),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[400],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? Colors.deepPurpleAccent : Colors.grey.withOpacity(0.08),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: const Color(0xFF16161A),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withOpacity(0.06)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final filtered = _filteredPurchases;
        final totalSpent = _calculateTotalSpent(filtered);
        final totalItems = _countTotalItems(filtered);

        return Scaffold(
          backgroundColor: const Color(0xFF0F0E17),
          body: widget.controller.isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent))
              : SafeArea(
                  child: RefreshIndicator(
                    color: Colors.deepPurpleAccent,
                    onRefresh: widget.controller.loadPurchases,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // Welcome Header Row
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.deepPurpleAccent.withOpacity(0.15),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      height: 48,
                                      width: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const CircleAvatar(
                                        radius: 24,
                                        backgroundColor: Color(0xFF16161A),
                                        child: Icon(
                                          Icons.shopping_bag_outlined,
                                          color: Colors.deepPurpleAccent,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                RichText(
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontSize: 26,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Organiza',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w300,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'Compras',
                                        style: TextStyle(
                                          color: Colors.deepPurpleAccent,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 24),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SettingsScreen(controller: widget.controller),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Spending Hero Summary Card
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6246EA), Color(0xFF3B2E9C)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.deepPurpleAccent.withOpacity(0.25),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'VALOR TOTAL FILTRADO',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _currencyFormat.format(totalSpent),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            const Icon(Icons.receipt_long, color: Colors.white60, size: 16),
                                            const SizedBox(width: 8),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${filtered.length} notas',
                                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                                ),
                                                const Text(
                                                  'Lidas',
                                                  style: TextStyle(color: Colors.white60, fontSize: 9),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            const Icon(Icons.shopping_bag_outlined, color: Colors.white60, size: 16),
                                            const SizedBox(width: 8),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '$totalItems itens',
                                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                                ),
                                                const Text(
                                                  'Adquiridos',
                                                  style: TextStyle(color: Colors.white60, fontSize: 9),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Section Title: Quick Menu
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                            child: Text(
                              'Ações Rápidas',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        // 2x2 Grid Menu
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          sliver: SliverGrid.count(
                            crossAxisCount: 2,
                            childAspectRatio: 1.4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            children: [
                              _buildMenuCard(
                                icon: Icons.qr_code_scanner,
                                title: 'Escanear Nota',
                                subtitle: 'Câmera / Digitação',
                                color: Colors.deepPurpleAccent,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ScanScreen(controller: widget.controller),
                                    ),
                                  );
                                },
                              ),
                              _buildMenuCard(
                                icon: Icons.bar_chart_outlined,
                                title: 'Relatórios',
                                subtitle: 'Gastos por categoria',
                                color: Colors.greenAccent,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ReportsScreen(controller: widget.controller),
                                    ),
                                  );
                                },
                              ),
                              _buildMenuCard(
                                icon: Icons.inventory_2_outlined,
                                title: 'Produtos',
                                subtitle: 'Lista e comparativo',
                                color: Colors.blueAccent,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductsScreen(controller: widget.controller),
                                    ),
                                  );
                                },
                              ),
                              _buildMenuCard(
                                icon: Icons.category_outlined,
                                title: 'Categorias',
                                subtitle: 'Ajustes e CRUD',
                                color: Colors.orangeAccent,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CategoriesScreen(controller: widget.controller),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        // Section Title: History with toggle filters
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 28.0, bottom: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Histórico de Notas',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (filtered.isNotEmpty)
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _showAllHistory = !_showAllHistory;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Text(
                                        _showAllHistory ? 'Ver Menos' : 'Ver Todas (${filtered.length})',
                                        style: const TextStyle(
                                          color: Colors.deepPurpleAccent,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Horizontal Filter Chips inside CustomScrollView
                        SliverToBoxAdapter(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            child: Row(
                              children: [
                                _buildFilterChip('Todos'),
                                _buildFilterChip('Hoje'),
                                _buildFilterChip('7 dias', label: '7 Dias'),
                                _buildFilterChip('Este Mês'),
                                _buildFilterChip('Mês Passado'),
                                _buildFilterChip('Personalizado', label: _customDateRange != null 
                                    ? '${DateFormat('dd/MM').format(_customDateRange!.start)} - ${DateFormat('dd/MM').format(_customDateRange!.end)}'
                                    : 'Personalizado...'),
                              ],
                            ),
                          ),
                        ),

                        const SliverToBoxAdapter(
                          child: SizedBox(height: 10),
                        ),

                        // List of purchases (Full list if _showAllHistory is true, else limit to top 3)
                        filtered.isEmpty
                            ? SliverToBoxAdapter(
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.receipt_outlined, size: 48, color: Colors.grey[700]),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Nenhum recibo no filtro selecionado',
                                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final purchase = filtered[index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => PurchaseDetailScreen(
                                                purchase: purchase,
                                                controller: widget.controller,
                                              ),
                                            ),
                                          );
                                        },
                                        onLongPress: () {
                                          _showDeleteConfirmationDialog(context, purchase);
                                        },
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF16161A),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: Colors.grey.withOpacity(0.06),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              // Store icon indicator
                                              Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: Colors.deepPurpleAccent.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  Icons.storefront,
                                                  color: Colors.deepPurpleAccent,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              // Details
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      purchase.storeName,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '${_dateFormat.format(purchase.date)} • ${purchase.items.length} itens',
                                                      style: TextStyle(
                                                        color: Colors.grey[500],
                                                        fontSize: 11,
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
                                                    _currencyFormat.format(purchase.totalValue),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Icon(
                                                    Icons.chevron_right,
                                                    color: Colors.grey[600],
                                                    size: 16,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  childCount: _showAllHistory 
                                      ? filtered.length 
                                      : (filtered.length > 3 ? 3 : filtered.length),
                                ),
                              ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 40),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Purchase purchase) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16161A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Excluir Nota Fiscal', style: TextStyle(color: Colors.white)),
          content: Text(
            'Deseja realmente excluir a compra realizada em "${purchase.storeName}" no valor de ${_currencyFormat.format(purchase.totalValue)}?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                widget.controller.deletePurchase(purchase.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nota fiscal excluída com sucesso!'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }
}
