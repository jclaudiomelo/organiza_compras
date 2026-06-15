import 'purchase_item.dart';

class Purchase {
  final int? id;
  final String accessKey;
  final String storeName;
  final DateTime date;
  final double totalValue;
  final List<PurchaseItem> items;

  Purchase({
    this.id,
    required this.accessKey,
    required this.storeName,
    required this.date,
    required this.totalValue,
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'access_key': accessKey,
      'store_name': storeName,
      'date': date.toIso8601String(),
      'total_value': totalValue,
    };
  }

  factory Purchase.fromMap(Map<String, dynamic> map, {List<PurchaseItem> items = const []}) {
    return Purchase(
      id: map['id'] as int?,
      accessKey: map['access_key'] as String,
      storeName: map['store_name'] as String,
      date: DateTime.parse(map['date'] as String),
      totalValue: (map['total_value'] as num).toDouble(),
      items: items,
    );
  }

  Purchase copyWith({
    int? id,
    String? accessKey,
    String? storeName,
    DateTime? date,
    double? totalValue,
    List<PurchaseItem>? items,
  }) {
    return Purchase(
      id: id ?? this.id,
      accessKey: accessKey ?? this.accessKey,
      storeName: storeName ?? this.storeName,
      date: date ?? this.date,
      totalValue: totalValue ?? this.totalValue,
      items: items ?? this.items,
    );
  }
}
