class CreditCard {
  final int? id;
  final String name;
  final int color;
  final int closingDay;
  final int dueDay;
  final double? limitAmount;
  final String? cardNumber;
  final String? expirationDate;

  CreditCard({
    this.id,
    required this.name,
    required this.color,
    required this.closingDay,
    required this.dueDay,
    this.limitAmount,
    this.cardNumber,
    this.expirationDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'closing_day': closingDay,
      'due_day': dueDay,
      'limit_amount': limitAmount,
      'card_number': cardNumber,
      'expiration_date': expirationDate,
    };
  }

  factory CreditCard.fromMap(Map<String, dynamic> map) {
    return CreditCard(
      id: map['id'] as int?,
      name: map['name'] as String,
      color: map['color'] as int,
      closingDay: map['closing_day'] as int,
      dueDay: map['due_day'] as int,
      limitAmount: map['limit_amount'] != null ? (map['limit_amount'] as num).toDouble() : null,
      cardNumber: map['card_number'] as String?,
      expirationDate: map['expiration_date'] as String?,
    );
  }

  CreditCard copyWith({
    int? id,
    String? name,
    int? color,
    int? closingDay,
    int? dueDay,
    double? limitAmount,
    String? cardNumber,
    String? expirationDate,
  }) {
    return CreditCard(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      closingDay: closingDay ?? this.closingDay,
      dueDay: dueDay ?? this.dueDay,
      limitAmount: limitAmount ?? this.limitAmount,
      cardNumber: cardNumber ?? this.cardNumber,
      expirationDate: expirationDate ?? this.expirationDate,
    );
  }
}
