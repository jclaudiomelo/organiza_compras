import 'purchase_item.dart';

class Purchase {
  final int? id;
  final String accessKey;
  final String storeName;
  final DateTime date;
  final double totalValue;
  final String paymentMethod;
  final int? creditCardId;
  final int installments;
  final bool isManual;
  final List<PurchaseItem> items;

  Purchase({
    this.id,
    required this.accessKey,
    required this.storeName,
    required this.date,
    required this.totalValue,
    this.paymentMethod = 'Não Informado',
    this.creditCardId,
    this.installments = 1,
    this.isManual = false,
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'access_key': accessKey,
      'store_name': storeName,
      'date': date.toIso8601String(),
      'total_value': totalValue,
      'payment_method': paymentMethod,
      'credit_card_id': creditCardId,
      'installments': installments,
      'is_manual': isManual,
    };
  }

  factory Purchase.fromMap(Map<String, dynamic> map, {List<PurchaseItem> items = const []}) {
    return Purchase(
      id: map['id'] as int?,
      accessKey: map['access_key'] as String,
      storeName: map['store_name'] as String,
      date: DateTime.parse(map['date'] as String),
      totalValue: (map['total_value'] as num).toDouble(),
      paymentMethod: map['payment_method'] as String? ?? 'Não Informado',
      creditCardId: map['credit_card_id'] as int?,
      installments: map['installments'] as int? ?? 1,
      isManual: map['is_manual'] as bool? ?? false,
      items: items,
    );
  }

  Purchase copyWith({
    int? id,
    String? accessKey,
    String? storeName,
    DateTime? date,
    double? totalValue,
    String? paymentMethod,
    int? creditCardId,
    int? installments,
    bool? isManual,
    List<PurchaseItem>? items,
  }) {
    return Purchase(
      id: id ?? this.id,
      accessKey: accessKey ?? this.accessKey,
      storeName: storeName ?? this.storeName,
      date: date ?? this.date,
      totalValue: totalValue ?? this.totalValue,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      creditCardId: creditCardId ?? this.creditCardId,
      installments: installments ?? this.installments,
      isManual: isManual ?? this.isManual,
      items: items ?? this.items,
    );
  }
}
