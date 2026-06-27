import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/purchase_controller.dart';
import '../models/purchase.dart';
import '../models/credit_card.dart';

class WalletScreen extends StatefulWidget {
  final PurchaseController controller;

  const WalletScreen({super.key, required this.controller});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final NumberFormat _currencyFormat = NumberFormat.simpleCurrency(locale: 'pt_BR');
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  double _monthlyBudget = 2000.0;

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  Future<void> _loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _monthlyBudget = prefs.getDouble('monthly_budget') ?? 2000.0;
    });
  }

  Future<void> _saveBudget(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthly_budget', value);
    setState(() {
      _monthlyBudget = value;
    });
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  String _getMonthName(int month) {
    const months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return months[month - 1];
  }

  // Obter valor gasto por cada compra (ou parcela) neste mês específico
  List<Map<String, dynamic>> get _currentMonthExpenses {
    final List<Map<String, dynamic>> expenses = [];

    for (var p in widget.controller.purchases) {
      if (p.paymentMethod != 'Cartão de Crédito' || p.creditCardId == null) {
        // Gasto normal, cai no mês da compra
        final localDate = p.date.toLocal();
        if (localDate.year == _currentMonth.year && localDate.month == _currentMonth.month) {
          expenses.add({
            'purchase': p,
            'amount': p.totalValue,
            'method': p.paymentMethod,
          });
        }
      } else {
        // Cartão de Crédito: Dividir em parcelas
        final card = widget.controller.creditCards.firstWhere(
          (c) => c.id == p.creditCardId,
          orElse: () => CreditCard(name: 'Cartão Removido', color: 0, closingDay: 1, dueDay: 1),
        );

        final purchaseDate = p.date.toLocal();
        final installmentValue = p.totalValue / p.installments;

        for (int i = 0; i < p.installments; i++) {
          DateTime baseClosingDate = DateTime(purchaseDate.year, purchaseDate.month, card.closingDay);
          int monthOffset = purchaseDate.isAfter(baseClosingDate) ? 1 : 0;
          DateTime invoiceHitMonth = DateTime(purchaseDate.year, purchaseDate.month + monthOffset + i, 1);

          if (invoiceHitMonth.year == _currentMonth.year && invoiceHitMonth.month == _currentMonth.month) {
            expenses.add({
              'purchase': p,
              'amount': installmentValue,
              'method': '\${card.name} (Parcela \${i + 1}/\${p.installments})',
            });
          }
        }
      }
    }
    return expenses;
  }

  Map<String, double> get _spendingByPaymentMethod {
    final Map<String, double> map = {};
    for (var exp in _currentMonthExpenses) {
      final method = exp['method'] as String;
      map[method] = (map[method] ?? 0) + (exp['amount'] as double);
    }
    return map;
  }

  void _editBudgetDialog() {
    final TextEditingController budgetController = TextEditingController(text: _monthlyBudget.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16161A),
          title: const Text('Definir Orçamento', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: budgetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Valor Mensal',
              labelStyle: const TextStyle(color: Colors.grey),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final value = double.tryParse(budgetController.text.replaceAll(',', '.'));
                if (value != null) {
                  _saveBudget(value);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
              child: const Text('Salvar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final expenses = _currentMonthExpenses;
        final totalSpent = expenses.fold(0.0, (sum, exp) => sum + (exp['amount'] as double));
        final budgetPercent = _monthlyBudget > 0 ? (totalSpent / _monthlyBudget) : 0.0;
        final isOverBudget = budgetPercent > 1.0;
        
        final paymentMethods = _spendingByPaymentMethod.entries.toList();
        paymentMethods.sort((a, b) => b.value.compareTo(a.value));

        return Scaffold(
          backgroundColor: const Color(0xFF0F0E17),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F0E17),
            elevation: 0,
            title: const Text('Carteira', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // Month Selector
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, color: Colors.white),
                          onPressed: _previousMonth,
                        ),
                        Text(
                          '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: Colors.white),
                          onPressed: _nextMonth,
                        ),
                      ],
                    ),
                  ),
                ),

                // Budget Card
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16161A),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ORÇAMENTO MENSAL',
                              style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                            ),
                            InkWell(
                              onTap: _editBudgetDialog,
                              child: const Icon(Icons.edit, color: Colors.deepPurpleAccent, size: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _currencyFormat.format(totalSpent),
                              style: TextStyle(
                                color: isOverBudget ? Colors.redAccent : Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                '/ ${_currencyFormat.format(_monthlyBudget)}',
                                style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: budgetPercent > 1.0 ? 1.0 : budgetPercent,
                            minHeight: 12,
                            backgroundColor: Colors.white.withOpacity(0.05),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isOverBudget ? Colors.redAccent : (budgetPercent > 0.8 ? Colors.orangeAccent : Colors.greenAccent),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isOverBudget 
                            ? 'Você ultrapassou o orçamento em ${_currencyFormat.format(totalSpent - _monthlyBudget)}!'
                            : 'Você ainda tem ${_currencyFormat.format(_monthlyBudget - totalSpent)} disponíveis.',
                          style: TextStyle(
                            color: isOverBudget ? Colors.redAccent : Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Payment Methods Title
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Text(
                      'Por Forma de Pagamento',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                // Payment Methods List
                paymentMethods.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Text('Nenhum gasto neste mês.', style: TextStyle(color: Colors.grey[500])),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final method = paymentMethods[index].key;
                          final amount = paymentMethods[index].value;
                          final percent = totalSpent > 0 ? (amount / totalSpent) : 0.0;

                          IconData getMethodIcon() {
                            if (method.contains('Parcela')) return Icons.credit_card;
                            switch (method) {
                              case 'Pix': return Icons.pix;
                              case 'Cartão de Crédito': return Icons.credit_card;
                              case 'Cartão de Débito': return Icons.credit_card_outlined;
                              case 'Dinheiro': return Icons.attach_money;
                              case 'Vale Alimentação': return Icons.restaurant;
                              default: return Icons.account_balance_wallet;
                            }
                          }

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16161A),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.02)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurpleAccent.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(getMethodIcon(), color: Colors.deepPurpleAccent, size: 20),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(method, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: percent,
                                                minHeight: 4,
                                                backgroundColor: Colors.white.withOpacity(0.05),
                                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurpleAccent),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text('${(percent * 100).toStringAsFixed(1)}%', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  _currencyFormat.format(amount),
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        },
                        childCount: paymentMethods.length,
                      ),
                    ),
                    
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        );
      },
    );
  }
}
