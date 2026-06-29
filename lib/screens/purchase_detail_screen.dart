import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/purchase.dart';
import '../models/purchase_item.dart';
import '../controllers/purchase_controller.dart';

class PurchaseDetailScreen extends StatefulWidget {
  final Purchase purchase;
  final PurchaseController controller;

  const PurchaseDetailScreen({
    super.key,
    required this.purchase,
    required this.controller,
  });

  @override
  State<PurchaseDetailScreen> createState() => _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState extends State<PurchaseDetailScreen> {
  final NumberFormat _currencyFormat = NumberFormat.simpleCurrency(locale: 'pt_BR');
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  late Purchase _currentPurchase;

  @override
  void initState() {
    super.initState();
    _currentPurchase = widget.purchase;
  }

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

  // Opens category change popup
  void _showCategorySelector(PurchaseItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16161A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final categories = widget.controller.categories.map((c) => c['name'] as String).toList();
        
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            key: const Key('category_selector_bottomsheet'),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Alterar Categoria do Item',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: categories.map((cat) {
                      final isCurrent = item.category == cat;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getCategoryColor(cat).withOpacity(0.2),
                          radius: 16,
                          child: Icon(
                            _getCategoryIcon(cat),
                            color: _getCategoryColor(cat),
                            size: 16,
                          ),
                        ),
                        title: Text(
                          cat,
                          style: TextStyle(
                            color: isCurrent ? Colors.white : Colors.white70,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isCurrent
                            ? const Icon(Icons.check_circle, color: Colors.deepPurpleAccent)
                            : null,
                        onTap: () async {
                          // Update DB and reload
                          await widget.controller.updateItemCategory(item.id!, cat);
                          // Update local screen state
                          final updatedPurchases = widget.controller.purchases;
                          final currentUpdate = updatedPurchases.firstWhere((p) => p.id == _currentPurchase.id);
                          
                          setState(() {
                            _currentPurchase = currentUpdate;
                          });

                          if (mounted) {
                            Navigator.of(this.context).pop();
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPaymentMethodSelector() {
    final methods = [
      'Não Informado',
      'Pix',
      'Cartão de Crédito',
      'Cartão de Débito',
      'Dinheiro',
      'Vale Alimentação'
    ];
    
    String selectedMethod = _currentPurchase.paymentMethod;
    int? selectedCreditCardId = _currentPurchase.creditCardId;
    int selectedInstallments = _currentPurchase.installments > 0 ? _currentPurchase.installments : 1;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16161A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 20, right: 20, top: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Forma de Pagamento', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: methods.contains(selectedMethod) ? selectedMethod : 'Não Informado',
                      dropdownColor: const Color(0xFF24242B),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Método',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)),
                      ),
                      items: methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (val) => setModalState(() => selectedMethod = val!),
                    ),
                    if (selectedMethod == 'Cartão de Crédito') ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: widget.controller.creditCards.any((c) => c.id == selectedCreditCardId) ? selectedCreditCardId : null,
                        dropdownColor: const Color(0xFF24242B),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Qual Cartão?',
                          labelStyle: TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)),
                        ),
                        items: widget.controller.creditCards.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                        onChanged: (val) => setModalState(() => selectedCreditCardId = val),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: selectedInstallments,
                        dropdownColor: const Color(0xFF24242B),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Parcelas',
                          labelStyle: TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)),
                        ),
                        items: List.generate(24, (i) => i + 1).map((i) {
                          final instValue = _currentPurchase.totalValue / i;
                          final formattedValue = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(instValue);
                          return DropdownMenuItem(value: i, child: Text('${i}x de $formattedValue'));
                        }).toList(),
                        onChanged: (val) => setModalState(() => selectedInstallments = val!),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        if (selectedMethod == 'Cartão de Crédito' && selectedCreditCardId == null) {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione um cartão.')));
                           return;
                        }
                        int finalInstallments = selectedMethod == 'Cartão de Crédito' ? selectedInstallments : 1;
                        int? finalCardId = selectedMethod == 'Cartão de Crédito' ? selectedCreditCardId : null;
                        
                        await widget.controller.updatePurchasePaymentDetails(_currentPurchase.id!, selectedMethod, finalCardId, finalInstallments);
                        
                        final updatedPurchases = widget.controller.purchases;
                        final currentUpdate = updatedPurchases.firstWhere((p) => p.id == _currentPurchase.id);
                        setState(() {
                          _currentPurchase = currentUpdate;
                        });
                        if (mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text('Salvar Alterações', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showShareOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16161A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Como deseja exportar os dados?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildShareOptionTile(
                  icon: Icons.chat_outlined,
                  color: Colors.greenAccent,
                  title: 'Texto Formatado (WhatsApp)',
                  subtitle: 'Envia a lista de produtos formatada diretamente em texto',
                  onTap: () {
                    Navigator.pop(context);
                    _shareAsText();
                  },
                ),
                const SizedBox(height: 12),
                _buildShareOptionTile(
                  icon: Icons.picture_as_pdf_outlined,
                  color: Colors.redAccent,
                  title: 'Documento PDF',
                  subtitle: 'Gera um arquivo PDF bem formatado e profissional',
                  onTap: () async {
                    Navigator.pop(context);
                    await _shareAsPDF();
                  },
                ),
                const SizedBox(height: 12),
                _buildShareOptionTile(
                  icon: Icons.table_chart_outlined,
                  color: Colors.blueAccent,
                  title: 'Planilha Excel (CSV)',
                  subtitle: 'Gera um arquivo compatível com Excel para análise',
                  onTap: () async {
                    Navigator.pop(context);
                    await _shareAsCSV();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShareOptionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF24242B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  void _shareAsText() {
    final buffer = StringBuffer();
    buffer.writeln('🛍️ *Organiza Compras - Resumo de Compra*');
    buffer.writeln('🏪 *Estabelecimento:* ${_currentPurchase.storeName}');
    buffer.writeln('📅 *Data/Hora:* ${_dateFormat.format(_currentPurchase.date)}');
    buffer.writeln('🔑 *Chave de Acesso:* ${_formatAccessKey(_currentPurchase.accessKey)}');
    buffer.writeln('----------------------------------------');
    buffer.writeln('📋 *Itens:*');
    for (final item in _currentPurchase.items) {
      final qtyStr = item.quantity.toStringAsFixed(item.unit == 'KG' ? 3 : 0);
      buffer.writeln('• ${item.name}');
      buffer.writeln('  $qtyStr ${item.unit} x ${_currencyFormat.format(item.unitPrice)} = ${_currencyFormat.format(item.totalPrice)}');
    }
    buffer.writeln('----------------------------------------');
    buffer.writeln('💰 *Valor Total: ${_currencyFormat.format(_currentPurchase.totalValue)}*');
    
    Share.share(buffer.toString(), subject: 'Resumo de Compra - ${_currentPurchase.storeName}');
  }

  Future<void> _shareAsPDF() async {
    final pdf = pw.Document();
    final formattedTotal = _currencyFormat.format(_currentPurchase.totalValue);
    final formattedDate = _dateFormat.format(_currentPurchase.date);
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Organiza Compras', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Relatorio de Compra', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Text(formattedDate, style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Estabelecimento: ${_currentPurchase.storeName}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                  pw.SizedBox(height: 4),
                  pw.Text('Chave de Acesso: ${_formatAccessKey(_currentPurchase.accessKey)}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Produtos:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Item', 'Qtd', 'Unidade', 'Vlr. Unit', 'Total'],
              data: _currentPurchase.items.map((item) => [
                item.name,
                item.quantity.toStringAsFixed(item.unit == 'KG' ? 3 : 0),
                item.unit,
                _currencyFormat.format(item.unitPrice),
                _currencyFormat.format(item.totalPrice),
              ]).toList(),
              border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.center,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
              },
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text('VALOR TOTAL: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                      pw.Text(formattedTotal, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.blueGrey900)),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );
    
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/nota_${_currentPurchase.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    await Share.shareXFiles([XFile(file.path)], text: 'Nota Fiscal - ${_currentPurchase.storeName}');
  }

  Future<void> _shareAsCSV() async {
    final buffer = StringBuffer();
    buffer.writeln('Produto;Quantidade;Unidade;Preco Unitario;Preco Total;Categoria');
    for (final item in _currentPurchase.items) {
      final name = item.name.replaceAll(';', ',');
      final qty = item.quantity.toStringAsFixed(item.unit == 'KG' ? 3 : 0);
      final unit = item.unit;
      final unitPrice = item.unitPrice.toStringAsFixed(2);
      final totalPrice = item.totalPrice.toStringAsFixed(2);
      final category = item.category;
      
      buffer.writeln('$name;$qty;$unit;$unitPrice;$totalPrice;$category');
    }
    
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/nota_${_currentPurchase.id}.csv');
    final List<int> bytes = [0xEF, 0xBB, 0xBF] + utf8.encode(buffer.toString());
    await file.writeAsBytes(bytes);
    
    await Share.shareXFiles([XFile(file.path)], text: 'Planilha de Itens - ${_currentPurchase.storeName}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      appBar: AppBar(
        title: const Text('Detalhes da Compra', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F0E17),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _showShareOptionsBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Purchase Summary Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF16161A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentPurchase.storeName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _dateFormat.format(_currentPurchase.date),
                            style: TextStyle(color: Colors.grey[400], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'TOTAL',
                          style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _currencyFormat.format(_currentPurchase.totalValue),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(color: Colors.white10, height: 24),
                // Chave de Acesso Box
                Text(
                  'CHAVE DE ACESSO:',
                  style: TextStyle(color: Colors.grey[500], fontSize: 9, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  _formatAccessKey(_currentPurchase.accessKey),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
                const Divider(color: Colors.white10, height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FORMA DE PAGAMENTO:',
                            style: TextStyle(color: Colors.grey[500], fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentPurchase.paymentMethod == 'Cartão de Crédito' && (_currentPurchase.installments ?? 1) > 1
                                ? '${_currentPurchase.paymentMethod} (${_currentPurchase.installments}x)'
                                : _currentPurchase.paymentMethod,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _showPaymentMethodSelector,
                      icon: const Icon(Icons.edit, size: 14, color: Colors.deepPurpleAccent),
                      label: const Text('Alterar', style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.deepPurpleAccent.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Produtos da Nota',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Items list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: _currentPurchase.items.length,
              itemBuilder: (context, index) {
                final item = _currentPurchase.items[index];
                final catColor = _getCategoryColor(item.category);

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16161A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.04)),
                  ),
                  child: Row(
                    children: [
                      // Circular Icon based on Category
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getCategoryIcon(item.category),
                          color: catColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Item info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  '${item.quantity.toStringAsFixed(item.unit == 'KG' ? 3 : 0)} ${item.unit} x ${_currencyFormat.format(item.unitPrice)}',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Category chip button
                                InkWell(
                                  onTap: () => _showCategorySelector(item),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: catColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: catColor.withOpacity(0.3), width: 0.5),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          item.category,
                                          style: TextStyle(
                                            color: catColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 3),
                                        Icon(Icons.edit, color: catColor, size: 10),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Total price
                      Text(
                        _currencyFormat.format(item.totalPrice),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatAccessKey(String key) {
    if (key.length != 44) return key;
    // Format 44-digit key into blocks of 4 for better reading
    final segments = <String>[];
    for (int i = 0; i < 44; i += 4) {
      segments.add(key.substring(i, i + 4));
    }
    return segments.join(' ');
  }
}
