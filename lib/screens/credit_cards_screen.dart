import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import '../controllers/purchase_controller.dart';
import '../models/credit_card.dart';

class CreditCardsScreen extends StatefulWidget {
  final PurchaseController controller;

  const CreditCardsScreen({super.key, required this.controller});

  @override
  State<CreditCardsScreen> createState() => _CreditCardsScreenState();
}

class _CreditCardsScreenState extends State<CreditCardsScreen> {
  final NumberFormat _currencyFormat = NumberFormat.simpleCurrency(locale: 'pt_BR');

  void _showAddCardDialog({CreditCard? cardToEdit}) {
    final isEdit = cardToEdit != null;
    final nameController = TextEditingController(text: cardToEdit?.name ?? '');
    final numberController = TextEditingController(text: cardToEdit?.cardNumber ?? '');
    final expController = TextEditingController(text: cardToEdit?.expirationDate ?? '');
    final closingDayController = TextEditingController(text: cardToEdit?.closingDay.toString() ?? '');
    final dueDayController = TextEditingController(text: cardToEdit?.dueDay.toString() ?? '');
    
    final currencyFormatter = CurrencyTextInputFormatter.currency(locale: 'pt_BR', symbol: 'R\$');
    String initialLimit = '';
    if (cardToEdit?.limitAmount != null) {
      initialLimit = currencyFormatter.formatDouble(cardToEdit!.limitAmount!);
    }
    final limitController = TextEditingController(text: initialLimit);
    
    final cardMask = MaskTextInputFormatter(mask: '#### #### #### ####', filter: {"#": RegExp(r'[0-9]')});
    final expMask = MaskTextInputFormatter(mask: '##/##', filter: {"#": RegExp(r'[0-9]')});
    
    Color selectedColor = cardToEdit != null ? Color(cardToEdit.color) : Colors.deepPurpleAccent;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16161A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isEdit ? 'Editar Cartão' : 'Novo Cartão',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Nome do Cartão (ex: Nubank)',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: numberController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [cardMask],
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Número do Cartão',
                            labelStyle: TextStyle(color: Colors.grey),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: expController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [expMask],
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Validade',
                            hintText: 'MM/AA',
                            hintStyle: TextStyle(color: Colors.white24),
                            labelStyle: TextStyle(color: Colors.grey),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: closingDayController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Dia de Fechamento',
                            labelStyle: TextStyle(color: Colors.grey),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: dueDayController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Dia de Vencimento',
                            labelStyle: TextStyle(color: Colors.grey),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: limitController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [currencyFormatter],
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Limite (Opcional)',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Cor do Cartão: ', style: TextStyle(color: Colors.white70)),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                backgroundColor: const Color(0xFF16161A),
                                content: SingleChildScrollView(
                                  child: BlockPicker(
                                    pickerColor: selectedColor,
                                    onColorChanged: (color) {
                                      setModalState(() {
                                        selectedColor = color;
                                      });
                                    },
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK', style: TextStyle(color: Colors.deepPurpleAccent)),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: CircleAvatar(backgroundColor: selectedColor, radius: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final number = numberController.text.trim();
                      final exp = expController.text.trim();
                      final closing = int.tryParse(closingDayController.text);
                      final due = int.tryParse(dueDayController.text);
                      final limit = currencyFormatter.getUnformattedValue().toDouble();

                      if (name.isEmpty || closing == null || due == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Preencha os campos obrigatórios corretamente.')),
                        );
                        return;
                      }

                      final newCard = CreditCard(
                        id: cardToEdit?.id,
                        name: name,
                        cardNumber: number.isNotEmpty ? number : null,
                        expirationDate: exp.isNotEmpty ? exp : null,
                        color: selectedColor.value,
                        closingDay: closing,
                        dueDay: due,
                        limitAmount: limit > 0 ? limit : null,
                      );

                      if (isEdit) {
                        await widget.controller.editCreditCard(newCard);
                      } else {
                        await widget.controller.addCreditCard(newCard);
                      }

                      if (mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(isEdit ? 'Salvar Alterações' : 'Adicionar Cartão', style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(CreditCard card) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16161A),
          title: const Text('Excluir Cartão', style: TextStyle(color: Colors.white)),
          content: Text('Deseja realmente excluir o cartão ${card.name}?', style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await widget.controller.deleteCreditCard(card.id!);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Excluir', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Map<String, double> _calculateInvoices(CreditCard card) {
    final now = DateTime.now();
    double currentInvoiceTotal = 0.0;
    double nextInvoiceTotal = 0.0;
    
    for (var purchase in widget.controller.purchases) {
      if (purchase.creditCardId == card.id) {
        final purchaseDate = purchase.date;
        final installmentValue = purchase.totalValue / purchase.installments;

        for (int i = 0; i < purchase.installments; i++) {
          DateTime baseClosingDate = DateTime(purchaseDate.year, purchaseDate.month, card.closingDay);
          int monthOffset = purchaseDate.isAfter(baseClosingDate) ? 1 : 0;
          
          DateTime invoiceHitMonth = DateTime(purchaseDate.year, purchaseDate.month + monthOffset + i, 1);
          
          // Current month invoice
          if (invoiceHitMonth.year == now.year && invoiceHitMonth.month == now.month) {
            currentInvoiceTotal += installmentValue;
          }
          
          // Next month invoice
          DateTime nextMonth = DateTime(now.year, now.month + 1, 1);
          if (invoiceHitMonth.year == nextMonth.year && invoiceHitMonth.month == nextMonth.month) {
            nextInvoiceTotal += installmentValue;
          }
        }
      }
    }
    
    return {
      'current': currentInvoiceTotal,
      'next': nextInvoiceTotal,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final cards = widget.controller.creditCards;

        return Scaffold(
          backgroundColor: const Color(0xFF0F0E17),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F0E17),
            title: const Text('Meus Cartões', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: cards.isEmpty
              ? const Center(
                  child: Text('Nenhum cartão cadastrado.', style: TextStyle(color: Colors.white70)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    final invoices = _calculateInvoices(card);
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Color(card.color).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Color(card.color).withOpacity(0.4), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: Color(card.color).withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icon
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Color(card.color).withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.credit_card, color: Color(card.color)),
                                ),
                                const SizedBox(width: 16),
                                // Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        card.name,
                                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      if (card.cardNumber != null && card.cardNumber!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          card.cardNumber!,
                                          style: const TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 2.0, fontFamily: 'monospace'),
                                        ),
                                      ],
                                      if (card.expirationDate != null && card.expirationDate!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Validade: \${card.expirationDate}',
                                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Text(
                                        'Fechamento: dia \${card.closingDay} • Vencimento: dia \${card.dueDay}',
                                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                      ),
                                      if (card.limitAmount != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Limite: \${_currencyFormat.format(card.limitAmount)}',
                                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                // Edit/Delete
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, color: Colors.white54),
                                  color: const Color(0xFF24242B),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showAddCardDialog(cardToEdit: card);
                                    } else if (value == 'delete') {
                                      _showDeleteDialog(card);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Editar', style: TextStyle(color: Colors.white))),
                                    const PopupMenuItem(value: 'delete', child: Text('Excluir', style: TextStyle(color: Colors.redAccent))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Invoice Footer
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: Color(card.color).withOpacity(0.08),
                              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Fatura Atual (estimativa)', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                    Text(
                                      _currencyFormat.format(invoices['current']),
                                      style: TextStyle(color: Color(card.color), fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Próxima Fatura', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                    Text(
                                      _currencyFormat.format(invoices['next']),
                                      style: TextStyle(color: Color(card.color).withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddCardDialog(),
            backgroundColor: Colors.deepPurpleAccent,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }
}
