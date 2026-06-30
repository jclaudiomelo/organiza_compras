import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/purchase.dart';
import '../models/purchase_item.dart';
import '../models/credit_card.dart';

class SupabaseHelper {
  static final SupabaseHelper instance = SupabaseHelper._init();
  final SupabaseClient _supabase = Supabase.instance.client;

  SupabaseHelper._init();

  String get _userId {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }
    return user.id;
  }

  Future<int> insertPurchase(Purchase purchase) async {
    // Check if purchase with this access key already exists
    final existing = await _supabase
        .from('purchases')
        .select('id')
        .eq('access_key', purchase.accessKey)
        .maybeSingle();

    int purchaseId;
    if (existing != null) {
      purchaseId = existing['id'] as int;
      // Update purchase info
      await _supabase.from('purchases').update({
        'store_name': purchase.storeName,
        'date': purchase.date.toIso8601String(),
        'total_value': purchase.totalValue,
        'payment_method': purchase.paymentMethod,
        'credit_card_id': purchase.creditCardId,
        'installments': purchase.installments,
        'is_manual': purchase.isManual,
      }).eq('id', purchaseId);

      // Delete existing items to re-import
      await _supabase
          .from('purchase_items')
          .delete()
          .eq('purchase_id', purchaseId);
    } else {
      final result = await _supabase.from('purchases').insert({
        'user_id': _userId,
        'access_key': purchase.accessKey,
        'store_name': purchase.storeName,
        'date': purchase.date.toIso8601String(),
        'total_value': purchase.totalValue,
        'payment_method': purchase.paymentMethod,
        'credit_card_id': purchase.creditCardId,
        'installments': purchase.installments,
        'is_manual': purchase.isManual,
      }).select('id').single();
      
      purchaseId = result['id'] as int;
    }

    // Insert all purchase items
    if (purchase.items.isNotEmpty) {
      final itemsData = purchase.items.map((item) {
        return {
          'purchase_id': purchaseId,
          'user_id': _userId,
          'name': item.name,
          'quantity': item.quantity,
          'unit': item.unit,
          'unit_price': item.unitPrice,
          'total_price': item.totalPrice,
          'category': item.category,
        };
      }).toList();

      await _supabase.from('purchase_items').insert(itemsData);
    }

    return purchaseId;
  }

  Future<List<Purchase>> getPurchases() async {
    final response = await _supabase
        .from('purchases')
        .select('*, purchase_items(*)')
        .order('date', ascending: false);

    List<Purchase> purchases = [];
    for (var row in response) {
      final itemsList = row['purchase_items'] as List<dynamic>? ?? [];
      final items = itemsList.map((itemRow) => PurchaseItem.fromMap(itemRow)).toList();
      purchases.add(Purchase.fromMap(row, items: items));
    }

    return purchases;
  }

  Future<Purchase?> getPurchaseById(int id) async {
    final row = await _supabase
        .from('purchases')
        .select('*, purchase_items(*)')
        .eq('id', id)
        .maybeSingle();

    if (row != null) {
      final itemsList = row['purchase_items'] as List<dynamic>? ?? [];
      final items = itemsList.map((itemRow) => PurchaseItem.fromMap(itemRow)).toList();
      return Purchase.fromMap(row, items: items);
    }
    return null;
  }

  Future<void> deletePurchase(int id) async {
    await _supabase.from('purchases').delete().eq('id', id);
  }

  Future<void> updateItemCategory(int itemId, String newCategory) async {
    await _supabase
        .from('purchase_items')
        .update({'category': newCategory})
        .eq('id', itemId);
  }

  Future<void> updatePurchasePaymentDetails(int purchaseId, String method, int? creditCardId, int installments) async {
    await _supabase
        .from('purchases')
        .update({
          'payment_method': method,
          'credit_card_id': creditCardId,
          'installments': installments,
        })
        .eq('id', purchaseId);
  }

  // --- Credit Cards CRUD ---
  Future<List<CreditCard>> getCreditCards() async {
    final response = await _supabase.from('credit_cards').select().order('name');
    return response.map((row) => CreditCard.fromMap(row)).toList();
  }

  Future<void> insertCreditCard(CreditCard card) async {
    await _supabase.from('credit_cards').insert({
      'user_id': _userId,
      'name': card.name,
      'color': card.color.toSigned(32),
      'closing_day': card.closingDay,
      'due_day': card.dueDay,
      'limit_amount': card.limitAmount,
      'card_number': card.cardNumber,
      'expiration_date': card.expirationDate,
    });
  }

  Future<void> updateCreditCard(CreditCard card) async {
    await _supabase.from('credit_cards').update({
      'name': card.name,
      'color': card.color.toSigned(32),
      'closing_day': card.closingDay,
      'due_day': card.dueDay,
      'limit_amount': card.limitAmount,
      'card_number': card.cardNumber,
      'expiration_date': card.expirationDate,
    }).eq('id', card.id!);
  }

  Future<void> deleteCreditCard(int id) async {
    // Nullify credit_card_id in purchases before deleting card
    await _supabase.from('purchases').update({'credit_card_id': null}).eq('credit_card_id', id);
    await _supabase.from('credit_cards').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getUniqueProducts() async {
    // Supabase RPC or select distinct.
    // For simplicity without RPC, we fetch all items. Since it's user specific, volume is manageable.
    final items = await _supabase.from('purchase_items').select('name, category');
    
    // Process distinct in memory
    final Map<String, String> uniqueMap = {};
    for (var item in items) {
      uniqueMap[item['name']] = item['category'];
    }
    
    final result = uniqueMap.entries.map((e) => {'name': e.key, 'category': e.value}).toList();
    result.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));
    return result;
  }

  Future<List<Map<String, dynamic>>> getProductPriceHistory(String productName) async {
    final response = await _supabase
        .from('purchase_items')
        .select('unit_price, quantity, unit, total_price, purchases!inner(date, store_name)')
        .eq('name', productName)
        .order('purchases(date)', ascending: true);
        
    return response.map((row) {
      final purchase = row['purchases'] as Map<String, dynamic>;
      return {
        'unit_price': row['unit_price'],
        'quantity': row['quantity'],
        'unit': row['unit'],
        'total_price': row['total_price'],
        'date': purchase['date'],
        'store_name': purchase['store_name'],
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    return await _supabase.from('categories').select().order('id', ascending: true);
  }

  Future<void> insertCategory(String name, int colorValue, int iconCodePoint) async {
    await _supabase.from('categories').insert({
      'user_id': _userId,
      'name': name,
      'color': colorValue.toSigned(32),
      'icon_code': iconCodePoint,
    });
  }

  Future<void> updateCategory(int id, String oldName, String newName, int colorValue, int iconCodePoint) async {
    await _supabase.from('categories').update({
      'name': newName,
      'color': colorValue.toSigned(32),
      'icon_code': iconCodePoint,
    }).eq('id', id);

    // Cascade to items
    await _supabase
        .from('purchase_items')
        .update({'category': newName})
        .eq('category', oldName);
  }

  Future<void> deleteCategory(int id, String categoryName) async {
    await _supabase.from('categories').delete().eq('id', id);

    // Reset items
    await _supabase
        .from('purchase_items')
        .update({'category': 'Outros'})
        .eq('category', categoryName);
  }

  Future<void> ensureDefaultCategories() async {
    final existing = await getCategories();
    if (existing.isEmpty) {
      await _supabase.from('categories').insert([
        {'user_id': _userId, 'name': 'Alimentação', 'color': 0xFF2ECC71.toSigned(32), 'icon_code': Icons.shopping_cart.codePoint},
        {'user_id': _userId, 'name': 'Bebidas', 'color': 0xFF3498DB.toSigned(32), 'icon_code': Icons.wine_bar.codePoint},
        {'user_id': _userId, 'name': 'Limpeza', 'color': 0xFFE67E22.toSigned(32), 'icon_code': Icons.cleaning_services.codePoint},
        {'user_id': _userId, 'name': 'Higiene', 'color': 0xFFE91E63.toSigned(32), 'icon_code': Icons.sanitizer.codePoint},
        {'user_id': _userId, 'name': 'Outros', 'color': 0xFF95A5A6.toSigned(32), 'icon_code': Icons.category.codePoint},
      ]);
    }
  }

  // We map settings to SharedPreferences or we use a settings table.
  // The SQL didn't create a 'settings' table with user_id, let's use SharedPreferences.
}
