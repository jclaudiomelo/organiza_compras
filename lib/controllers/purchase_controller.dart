import 'package:flutter/foundation.dart';
import '../models/purchase.dart';
import '../services/supabase_helper.dart';
import '../services/sefaz_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseController extends ChangeNotifier {
  final SupabaseHelper _dbHelper = SupabaseHelper.instance;

  List<Purchase> _purchases = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _defaultState = 'SC';

  List<Purchase> get purchases => _purchases;
  List<Map<String, dynamic>> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get defaultState => _defaultState;

  // Calculate totals and statistics
  double get totalSpent => _purchases.fold(0.0, (sum, p) => sum + p.totalValue);

  // Group spending by category
  Map<String, double> get categorySpending {
    final Map<String, double> spending = {};
    for (var purchase in _purchases) {
      for (var item in purchase.items) {
        spending[item.category] = (spending[item.category] ?? 0.0) + item.totalPrice;
      }
    }
    return spending;
  }

  Future<void> _loadCategoriesOnly() async {
    try {
      _categories = await _dbHelper.getCategories();
    } catch (_) {}
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final state = prefs.getString('default_state');
      if (state != null) {
        _defaultState = state;
      }
    } catch (_) {}
  }

  // Load all purchases, categories, and settings from local DB
  Future<void> loadPurchases() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _dbHelper.ensureDefaultCategories();
      _purchases = await _dbHelper.getPurchases();
      await _loadCategoriesOnly();
      await _loadSettings();
    } catch (e) {
      _errorMessage = 'Erro ao carregar compras: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateDefaultState(String state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('default_state', state);
      _defaultState = state;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erro ao atualizar estado padrão: $e';
      notifyListeners();
    }
  }

  // Scan QR code, fetch SEFAZ details, and store in database
  Future<bool> scanAndAddPurchase(String qrCodeUrl) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Fetch and parse NFC-e
      final purchase = await SefazParser.parseQRCode(qrCodeUrl);
      
      // Check if already exists to prevent duplicates
      final alreadyExists = _purchases.any((p) => p.accessKey == purchase.accessKey);
      if (alreadyExists) {
        throw Exception('Esta nota fiscal já foi importada anteriormente.');
      }
      
      // 2. Insert to local SQLite
      await _dbHelper.insertPurchase(purchase);
      
      // 3. Reload list
      await loadPurchases();
      return true;
    } catch (e) {
      _errorMessage = 'Falha ao processar cupom: ${e.toString().replaceAll('Exception:', '')}';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Directly add a purchase by parsing raw HTML content (e.g. from WebView after solving captcha)
  Future<bool> addParsedPurchase(String htmlContent, String sourceUrl) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final purchase = SefazParser.parseHtmlContent(htmlContent, sourceUrl);
      
      // Check if already exists to prevent duplicates
      final alreadyExists = _purchases.any((p) => p.accessKey == purchase.accessKey);
      if (alreadyExists) {
        throw Exception('Esta nota fiscal já foi importada anteriormente.');
      }
      
      await _dbHelper.insertPurchase(purchase);
      await loadPurchases();
      return true;
    } catch (e) {
      _errorMessage = 'Falha ao processar HTML do cupom: ${e.toString().replaceAll('Exception:', '')}';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save an already parsed Purchase object to the database
  Future<bool> savePurchase(Purchase purchase) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final alreadyExists = _purchases.any((p) => p.accessKey == purchase.accessKey);
      if (alreadyExists) {
        throw Exception('Esta nota fiscal já foi importada anteriormente.');
      }
      
      await _dbHelper.insertPurchase(purchase);
      await loadPurchases();
      return true;
    } catch (e) {
      _errorMessage = 'Falha ao salvar o cupom: ${e.toString().replaceAll('Exception:', '')}';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete purchase from list and DB
  Future<void> deletePurchase(int id) async {
    try {
      await _dbHelper.deletePurchase(id);
      await loadPurchases();
    } catch (e) {
      _errorMessage = 'Erro ao deletar compra: $e';
      notifyListeners();
    }
  }

  // Update item category
  Future<void> updateItemCategory(int itemId, String newCategory) async {
    try {
      await _dbHelper.updateItemCategory(itemId, newCategory);
      await loadPurchases();
    } catch (e) {
      _errorMessage = 'Erro ao atualizar categoria: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getUniqueProducts() async {
    try {
      return await _dbHelper.getUniqueProducts();
    } catch (e) {
      _errorMessage = 'Erro ao buscar produtos: $e';
      notifyListeners();
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getProductPriceHistory(String productName) async {
    try {
      return await _dbHelper.getProductPriceHistory(productName);
    } catch (e) {
      _errorMessage = 'Erro ao buscar histórico de preços: $e';
      notifyListeners();
      return [];
    }
  }

  Future<bool> addCategory(String name, int colorValue, int iconCodePoint) async {
    try {
      await _dbHelper.insertCategory(name, colorValue, iconCodePoint);
      await loadPurchases();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao criar categoria: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> editCategory(int id, String oldName, String newName, int colorValue, int iconCodePoint) async {
    try {
      await _dbHelper.updateCategory(id, oldName, newName, colorValue, iconCodePoint);
      await loadPurchases();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar categoria: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(int id, String categoryName) async {
    try {
      await _dbHelper.deleteCategory(id, categoryName);
      await loadPurchases();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao excluir categoria: $e';
      notifyListeners();
      return false;
    }
  }
}
