class PurchaseItem {
  final int? id;
  final int? purchaseId;
  final String name;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double totalPrice;
  final String category;

  PurchaseItem({
    this.id,
    this.purchaseId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.totalPrice,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'purchase_id': purchaseId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'category': category,
    };
  }

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      id: map['id'] as int?,
      purchaseId: map['purchase_id'] as int?,
      name: map['name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      unitPrice: (map['unit_price'] as num).toDouble(),
      totalPrice: (map['total_price'] as num).toDouble(),
      category: map['category'] as String,
    );
  }

  PurchaseItem copyWith({
    int? id,
    int? purchaseId,
    String? name,
    double? quantity,
    String? unit,
    double? unitPrice,
    double? totalPrice,
    String? category,
  }) {
    return PurchaseItem(
      id: id ?? this.id,
      purchaseId: purchaseId ?? this.purchaseId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      category: category ?? this.category,
    );
  }
}
