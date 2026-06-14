enum TxType { earned, spent }

class TransactionModel {
  final String id;
  final String childUid;
  final TxType type;
  final int amount;
  final String title;
  final String emoji;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.childUid,
    required this.type,
    required this.amount,
    required this.title,
    required this.emoji,
    required this.createdAt,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> m, String id) =>
      TransactionModel(
        id: id,
        childUid: m['childUid'] ?? '',
        type: m['type'] == 'earned' ? TxType.earned : TxType.spent,
        amount: m['amount'] ?? 0,
        title: m['title'] ?? '',
        emoji: m['emoji'] ?? '💰',
        createdAt: DateTime.parse(m['createdAt']),
      );

  Map<String, dynamic> toMap() => {
    'childUid': childUid,
    'type': type.name,
    'amount': amount,
    'title': title,
    'emoji': emoji,
    'createdAt': createdAt.toIso8601String(),
  };
}