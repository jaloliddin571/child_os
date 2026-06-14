import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../auth/providers/auth_provider.dart';
import '../auth/providers/wallet_provider.dart';
import 'models/transaction_model.dart';
import '../../core/theme/app_colors.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (user) {
        if (user == null) return const SizedBox();
        final txAsync = ref.watch(transactionsProvider(user.uid));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Cho\'ntak puli'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            children: [
              // Balance card
              _BalanceCard(balance: user.balance, xp: user.xp),

              // Spend button (faqat bola uchun)
              if (!user.isParent)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: ElevatedButton.icon(
                    onPressed: () => _showSpendSheet(context, user.uid, user.balance),
                    icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                    label: const Text('Sarflash'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: AppColors.success,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TabBar(
                    controller: _tab,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    tabs: const [
                      Tab(text: 'Topilgan'),
                      Tab(text: 'Sarflangan'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Transaction list
              Expanded(
                child: txAsync.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (txs) {
                    return TabBarView(
                      controller: _tab,
                      children: [
                        _TxList(
                          txs: txs
                              .where((t) => t.type == TxType.earned)
                              .toList(),
                          emptyMsg: 'Hali hech narsa topilmadi',
                        ),
                        _TxList(
                          txs: txs
                              .where((t) => t.type == TxType.spent)
                              .toList(),
                          emptyMsg: 'Hali hech narsa sarflanmadi',
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSpendSheet(BuildContext ctx, String uid, int balance) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _SpendSheet(childUid: uid, balance: balance),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final int balance;
  final int xp;
  const _BalanceCard({required this.balance, required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Joriy balans',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Text(
                  '${NumberFormat('#,###').format(balance)} so\'m',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.xpGold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.xpGold.withOpacity(0.25)),
            ),
            child: Column(
              children: [
                const Text('⭐',
                    style: TextStyle(fontSize: 22)),
                Text('$xp XP',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.xpGold,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TxList extends StatelessWidget {
  final List<TransactionModel> txs;
  final String emptyMsg;
  const _TxList({required this.txs, required this.emptyMsg});

  @override
  Widget build(BuildContext context) {
    if (txs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💸', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 10),
            Text(emptyMsg,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: txs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _TxItem(tx: txs[i]),
    );
  }
}

class _TxItem extends StatelessWidget {
  final TransactionModel tx;
  const _TxItem({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isEarned = tx.type == TxType.earned;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (isEarned ? AppColors.success : AppColors.error)
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(tx.emoji,
                  style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    )),
                Text(
                  DateFormat('dd MMM, HH:mm').format(tx.createdAt),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '${isEarned ? '+' : '-'}${NumberFormat('#,###').format(tx.amount)} so\'m',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isEarned ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpendSheet extends ConsumerStatefulWidget {
  final String childUid;
  final int balance;
  const _SpendSheet({required this.childUid, required this.balance});

  @override
  ConsumerState<_SpendSheet> createState() => _SpendSheetState();
}

class _SpendSheetState extends ConsumerState<_SpendSheet> {
  final _items = [
    ('🎮', 'O\'yin vaqti (1 soat)', 2000),
    ('🍕', 'Tushlik tanlash', 3000),
    ('📱', 'Qo\'shimcha screen time', 1500),
    ('🎬', 'Kino ko\'rish', 2500),
    ('🛒', 'Xarid qilish', 5000),
  ];

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(walletNotifierProvider).isLoading;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Nima olasiz?',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('Balans: ${NumberFormat('#,###').format(widget.balance)} so\'m',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ..._items.map((item) {
            final canAfford = widget.balance >= item.$3;
            return GestureDetector(
              onTap: canAfford && !isLoading
                  ? () async {
                await ref
                    .read(walletNotifierProvider.notifier)
                    .spend(
                  childUid: widget.childUid,
                  amount: item.$3,
                  title: item.$2,
                  emoji: item.$1,
                );
                if (mounted) Navigator.pop(context);
              }
                  : null,
              child: Opacity(
                opacity: canAfford ? 1 : 0.4,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Text(item.$1,
                          style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(item.$2,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            )),
                      ),
                      Text(
                        '${NumberFormat('#,###').format(item.$3)} so\'m',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}