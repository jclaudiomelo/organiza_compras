import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import '../controllers/purchase_controller.dart';
import '../models/purchase.dart';
import '../models/purchase_item.dart';

class AddManualExpenseScreen extends StatefulWidget {
  final PurchaseController controller;

  const AddManualExpenseScreen({super.key, required this.controller});

  @override
  State<AddManualExpenseScreen> createState() => _AddManualExpenseScreenState();
}

class _AddManualExpenseScreenState extends State<AddManualExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Outros';
  String _selectedMethod = 'Pix';
  int? _selectedCreditCardId;
  int _selectedInstallments = 1;

  final CurrencyTextInputFormatter _currencyFormatter = CurrencyTextInputFormatter.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  final List<String> _methods = [
    'Pix',
    'Cartão de Crédito',
    'Cartão de Débito',
    'Dinheiro',
    'Vale Alimentação',
    'Boleto'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.controller.categories.isNotEmpty) {
      _selectedCategory = widget.controller.categories.first['name'] as String;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.deepPurpleAccent,
              onPrimary: Colors.white,
              surface: Color(0xFF24242B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    
    final value = _currencyFormatter.getUnformattedValue().toDouble();
    if (value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Valor inválido.')));
      return;
    }

    if (_selectedMethod == 'Cartão de Crédito' && _selectedCreditCardId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione um cartão de crédito.')));
      return;
    }

    // Create a dummy PurchaseItem for the category
    final dummyItem = PurchaseItem(
      name: _descriptionController.text.trim(),
      quantity: 1,
      unit: 'UN',
      unitPrice: value,
      totalPrice: value,
      category: _selectedCategory,
    );

    // Create the manual purchase
    final manualPurchase = Purchase(
      accessKey: 'MANUAL_\${DateTime.now().millisecondsSinceEpoch}',
      storeName: _descriptionController.text.trim(),
      date: _selectedDate,
      totalValue: value,
      paymentMethod: _selectedMethod,
      creditCardId: _selectedMethod == 'Cartão de Crédito' ? _selectedCreditCardId : null,
      installments: _selectedMethod == 'Cartão de Crédito' ? _selectedInstallments : 1,
      isManual: true,
      items: [dummyItem],
    );

    final success = await widget.controller.savePurchase(manualPurchase);
    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0E17),
        elevation: 0,
        title: const Text('Nova Despesa Manual', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Description
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Descrição (ex: Conta de Luz)',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              
              // Value and Date
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _valueController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [_currencyFormatter],
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        labelText: 'Valor (R\$)',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Obrigatório' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data',
                          labelStyle: TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        ),
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(_selectedDate),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                dropdownColor: const Color(0xFF24242B),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)),
                ),
                items: widget.controller.categories.map((c) => DropdownMenuItem(
                  value: c['name'] as String,
                  child: Text(c['name'] as String),
                )).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 16),

              // Payment Method
              DropdownButtonFormField<String>(
                value: _selectedMethod,
                dropdownColor: const Color(0xFF24242B),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Forma de Pagamento',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)),
                ),
                items: _methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (val) => setState(() => _selectedMethod = val!),
              ),
              
              if (_selectedMethod == 'Cartão de Crédito') ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedCreditCardId,
                  dropdownColor: const Color(0xFF24242B),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Qual Cartão?',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)),
                  ),
                  items: widget.controller.creditCards.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (val) => setState(() => _selectedCreditCardId = val),
                  validator: (val) => val == null ? 'Selecione um cartão' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedInstallments,
                  dropdownColor: const Color(0xFF24242B),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Parcelas',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)),
                  ),
                  items: List.generate(24, (i) => i + 1).map((i) => DropdownMenuItem(value: i, child: Text('\${i}x'))).toList(),
                  onChanged: (val) => setState(() => _selectedInstallments = val!),
                ),
              ],
              
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: widget.controller.isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Salvar Despesa', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
