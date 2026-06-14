import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../tasks/models/task_model.dart';
import '../../tasks/providers/task_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class AddTaskSheet extends ConsumerStatefulWidget {
  final String parentUid;
  const AddTaskSheet({super.key, required this.parentUid});

  @override
  ConsumerState<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<AddTaskSheet> {
  final _titleCtrl = TextEditingController();
  TaskSubject _subject = TaskSubject.math;
  int _xp = 20;
  int _money = 500;
  String? _childUid;

  final _subjects = [
    (TaskSubject.math, '📐', 'Matematika'),
    (TaskSubject.english, '🇬🇧', 'Ingliz tili'),
    (TaskSubject.uzbek, '🇺🇿', 'Ona tili'),
    (TaskSubject.science, '🔬', 'Fan'),
    (TaskSubject.reading, '📖', 'Kitob'),
    (TaskSubject.other, '✏️', 'Boshqa'),
  ];

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(taskNotifierProvider).isLoading;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Yangi vazifa',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _titleCtrl,
              label: 'Vazifa nomi',
              hint: 'Masalan: 5-mashq bajaring',
            ),
            const SizedBox(height: 16),
            const Text('Fan', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _subjects.map((s) {
                final selected = _subject == s.$1;
                return GestureDetector(
                  onTap: () => setState(() => _subject = s.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withOpacity(0.15)
                          : AppColors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Text('${s.$2} ${s.$3}',
                        style: TextStyle(
                          fontSize: 13,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('XP: $_xp',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                      Slider(
                        value: _xp.toDouble(),
                        min: 10,
                        max: 100,
                        divisions: 9,
                        activeColor: AppColors.xpGold,
                        onChanged: (v) =>
                            setState(() => _xp = v.round()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pul: $_money so\'m',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                      Slider(
                        value: _money.toDouble(),
                        min: 100,
                        max: 2000,
                        divisions: 19,
                        activeColor: AppColors.success,
                        onChanged: (v) =>
                            setState(() => _money = v.round()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Vazifa qo\'shish',
              isLoading: isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) return;

    // Bolani topish (parentUid bo'yicha)
    final snap = await ref
        .read(firestoreProvider)
        .collection('users')
        .where('parentUid', isEqualTo: widget.parentUid)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Hali bola qo\'shilmagan'),
          backgroundColor: AppColors.warning,
        ));
      }
      return;
    }

    final childUid = snap.docs.first.id;
    final task = TaskModel(
      id: '',
      title: _titleCtrl.text.trim(),
      childUid: childUid,
      parentUid: widget.parentUid,
      subject: _subject,
      xpReward: _xp,
      moneyReward: _money,
      dueDate: DateTime.now(),
    );

    await ref.read(taskNotifierProvider.notifier).addTask(task);
    if (mounted) Navigator.pop(context);
  }
}