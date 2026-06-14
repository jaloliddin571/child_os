import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/providers/auth_provider.dart';
import '../../wallet/models/transaction_model.dart';

final transactionsProvider =
StreamProvider.family<List<TransactionModel>, String>((ref, childUid) {
  return ref
      .watch(firestoreProvider)
      .collection('transactions')
      .where('childUid', isEqualTo: childUid)
      .orderBy('createdAt', descending: true)
      .limit(30)
      .snapshots()
      .map((s) => s.docs
      .map((d) => TransactionModel.fromMap(d.data(), d.id))
      .toList());
});

class WalletNotifier extends StateNotifier<AsyncValue<void>> {
  WalletNotifier(this.ref) : super(const AsyncValue.data(null));
  final Ref ref;

  FirebaseFirestore get _db => ref.read(firestoreProvider);

  // Pul sarflash (bolaning so'rovi)
  Future<void> spend({
    required String childUid,
    required int amount,
    required String title,
    required String emoji,
  }) async {
    state = const AsyncValue.loading();
    try {
      final userRef = _db.collection('users').doc(childUid);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(userRef);
        final balance = snap.data()?['balance'] ?? 0;
        if (balance < amount) throw Exception('Balans yetarli emas');

        tx.update(userRef, {'balance': FieldValue.increment(-amount)});
        tx.set(_db.collection('transactions').doc(), {
          'childUid': childUid,
          'type': TxType.spent.name,
          'amount': amount,
          'title': title,
          'emoji': emoji,
          'createdAt': DateTime.now().toIso8601String(),
        });
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Ota-ona tomonidan pul qo'shish (bonus)
  Future<void> addBonus({
    required String childUid,
    required int amount,
    required String title,
  }) async {
    final userRef = _db.collection('users').doc(childUid);
    await _db.runTransaction((tx) async {
      tx.update(userRef, {'balance': FieldValue.increment(amount)});
      tx.set(_db.collection('transactions').doc(), {
        'childUid': childUid,
        'type': TxType.earned.name,
        'amount': amount,
        'title': title,
        'emoji': '🎁',
        'createdAt': DateTime.now().toIso8601String(),
      });
    });
  }
}

final walletNotifierProvider =
StateNotifierProvider<WalletNotifier, AsyncValue<void>>(
        (ref) => WalletNotifier(ref));