import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_button.dart';

// RevenueCat provider
final offeringsProvider = FutureProvider<Offerings?>((ref) async {
  try {
    return await Purchases.getOfferings();
  } catch (_) {
    return null;
  }
});

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() =>
      _SubscriptionScreenState();
}

class _SubscriptionScreenState
    extends ConsumerState<SubscriptionScreen> {
  String _selected = 'family';
  bool _isYearly = false;
  bool _isPurchasing = false;

  final _plans = [
    _Plan(
      id: 'basic',
      name: 'Basic',
      emoji: '🌱',
      monthlyPrice: 5000,
      yearlyPrice: 50000,
      features: [
        'Bir bola profili',
        'Kunlik vazifalar',
        'Focus Sprint',
        'Haftalik hisobot',
        'XP va ballar tizimi',
      ],
    ),
    _Plan(
      id: 'family',
      name: 'Family',
      emoji: '👨‍👩‍👧‍👦',
      monthlyPrice: 15000,
      yearlyPrice: 150000,
      features: [
        'Barcha Basic imkoniyatlar',
        '5 tagacha bola profili',
        'AI Homework Check',
        'Cho\'ntak puli tizimi',
        'Prioritet yordam',
        'Detalli tahlil',
      ],
      isPopular: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Obuna'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              const Text(
                'Farzandingizning\no\'sishiga sarmoya qiling',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Istalgan vaqt bekor qilish mumkin',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),

              const SizedBox(height: 20),

              // Monthly / Yearly toggle
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    _ToggleBtn(
                      label: 'Oylik',
                      active: !_isYearly,
                      onTap: () => setState(() => _isYearly = false),
                    ),
                    _ToggleBtn(
                      label: 'Yillik  🔥 -17%',
                      active: _isYearly,
                      onTap: () => setState(() => _isYearly = true),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Plan cards
              ..._plans.map((plan) => _PlanCard(
                plan: plan,
                selected: _selected == plan.id,
                isYearly: _isYearly,
                onTap: () => setState(() => _selected = plan.id),
              )),

              const SizedBox(height: 8),

              // Add-on modules
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Qo\'shimcha modullar',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        )),
                    const SizedBox(height: 12),
                    _AddOnRow(
                        emoji: '💰',
                        name: 'Finance moduli',
                        price: 4000),
                    const SizedBox(height: 8),
                    _AddOnRow(
                        emoji: '❤️',
                        name: 'Healthy Habits',
                        price: 5000),
                    const SizedBox(height: 8),
                    _AddOnRow(
                        emoji: '🧠',
                        name: 'AI Coach',
                        price: 6000),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Subscribe button
              AppButton(
                label: _isPurchasing
                    ? 'Yuklanmoqda...'
                    : 'Obuna bo\'lish',
                isLoading: _isPurchasing,
                onPressed: _purchase,
              ),

              const SizedBox(height: 12),
              const Text(
                'Obuna avtomatik yangilanadi. Istalgan vaqt App Store / Google Play orqali bekor qiling.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _purchase() async {
    setState(() => _isPurchasing = true);
    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.current;
      if (offering == null) throw Exception('Taklif topilmadi');

      // Package tanlash
      final packageId = '${_selected}_${_isYearly ? 'yearly' : 'monthly'}';
      final pkg = offering.availablePackages.firstWhere(
            (p) => p.identifier == packageId,
        orElse: () => offering.availablePackages.first,
      );

      await Purchases.purchasePackage(pkg);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Obuna muvaffaqiyatli ulandi! 🎉'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xato: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }
}

class _Plan {
  final String id, name, emoji;
  final int monthlyPrice, yearlyPrice;
  final List<String> features;
  final bool isPopular;

  const _Plan({
    required this.id,
    required this.name,
    required this.emoji,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.features,
    this.isPopular = false,
  });
}

class _PlanCard extends StatelessWidget {
  final _Plan plan;
  final bool selected, isYearly;
  final VoidCallback onTap;
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.isYearly,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final price = isYearly ? plan.yearlyPrice : plan.monthlyPrice;
    final period = isYearly ? 'yil' : 'oy';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(plan.emoji,
                    style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Text(plan.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    )),
                const Spacer(),
                if (plan.isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'Ommabop',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                if (selected)
                  Container(
                    margin: EdgeInsets.only(left: plan.isPopular ? 8 : 0),
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${NumberFormat('#,###').format(price)}',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color:
                    selected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                Text(
                  ' so\'m / $period',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...plan.features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 16),
                  const SizedBox(width: 8),
                  Text(f,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ToggleBtn(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.all(3),
          height: double.infinity,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddOnRow extends StatefulWidget {
  final String emoji, name;
  final int price;
  const _AddOnRow(
      {required this.emoji, required this.name, required this.price});

  @override
  State<_AddOnRow> createState() => _AddOnRowState();
}

class _AddOnRowState extends State<_AddOnRow> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(widget.emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(widget.name,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textPrimary)),
        ),
        Text(
          '+${NumberFormat('#,###').format(widget.price)} so\'m',
          style: const TextStyle(
              fontSize: 12, color: AppColors.success,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => setState(() => _on = !_on),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 24,
            decoration: BoxDecoration(
              color: _on ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(12),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment:
              _on ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.all(3),
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}