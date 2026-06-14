import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

enum SprintState { idle, running, paused, done }

class FocusNotifier extends StateNotifier<_FocusState> {
  FocusNotifier() : super(_FocusState.initial());

  Timer? _timer;

  void start() {
    state = state.copyWith(sprintState: SprintState.running);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remaining <= 0) {
        _timer?.cancel();
        state = state.copyWith(sprintState: SprintState.done);
        return;
      }
      state = state.copyWith(remaining: state.remaining - 1);
    });
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(sprintState: SprintState.paused);
  }

  void resume() => start();

  void reset() {
    _timer?.cancel();
    state = _FocusState.initial();
  }

  void setDuration(int minutes) {
    state = state.copyWith(
      total: minutes * 60,
      remaining: minutes * 60,
      sprintState: SprintState.idle,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class _FocusState {
  final int total;
  final int remaining;
  final SprintState sprintState;

  const _FocusState({
    required this.total,
    required this.remaining,
    required this.sprintState,
  });

  factory _FocusState.initial() => const _FocusState(
    total: 25 * 60,
    remaining: 25 * 60,
    sprintState: SprintState.idle,
  );

  double get progress => remaining / total;

  String get timeLabel {
    final m = remaining ~/ 60;
    final s = remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  _FocusState copyWith({
    int? total,
    int? remaining,
    SprintState? sprintState,
  }) =>
      _FocusState(
        total: total ?? this.total,
        remaining: remaining ?? this.remaining,
        sprintState: sprintState ?? this.sprintState,
      );
}

final focusProvider =
StateNotifierProvider.autoDispose<FocusNotifier, _FocusState>(
        (ref) => FocusNotifier());

// --- SCREEN ---

class FocusScreen extends ConsumerWidget {
  const FocusScreen({super.key});

  static const _durations = [15, 20, 25, 30, 45];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(focusProvider);
    final notifier = ref.read(focusProvider.notifier);

    // Sprint tugaganda dialog
    ref.listen(focusProvider, (prev, next) {
      if (next.sprintState == SprintState.done) {
        _showDoneDialog(context, ref);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Sprint'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            notifier.reset();
            context.pop();
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Duration selector
              if (state.sprintState == SprintState.idle) ...[
                const Text(
                  'Vaqtni tanlang',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _durations.map((min) {
                    final selected = state.total == min * 60;
                    return GestureDetector(
                      onTap: () => notifier.setDuration(min),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : AppColors.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          '$min\'',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
              ] else
                const SizedBox(height: 48),

              // Timer ring
              _TimerRing(state: state),

              const SizedBox(height: 48),

              // Controls
              _Controls(state: state, notifier: notifier),

              const Spacer(),

              // Tip
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Telefonni yonboshiga qo\'ying va diqqatingizni to\'liq vazifaga bering.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDoneDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: AppColors.card,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 12),
              const Text(
                'Zo\'r!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sprint muvaffaqiyatli tugadi!\n+30 XP qo\'shildi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(focusProvider.notifier).reset();
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('Asosiy sahifaga'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerRing extends StatelessWidget {
  final _FocusState state;
  const _TimerRing({required this.state});

  Color get _color => switch (state.sprintState) {
    SprintState.running => AppColors.primary,
    SprintState.paused => AppColors.warning,
    SprintState.done => AppColors.success,
    SprintState.idle => AppColors.textMuted,
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 1, end: state.progress),
            duration: const Duration(milliseconds: 300),
            builder: (_, value, __) => CircularProgressIndicator(
              value: value,
              strokeWidth: 10,
              backgroundColor: AppColors.card,
              color: _color,
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.timeLabel,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -2,
                ),
              ),
              Text(
                switch (state.sprintState) {
                  SprintState.running => 'Focus rejimi',
                  SprintState.paused => 'To\'xtatildi',
                  SprintState.done => 'Bajarildi!',
                  SprintState.idle => 'Tayyor',
                },
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final _FocusState state;
  final FocusNotifier notifier;
  const _Controls({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return switch (state.sprintState) {
      SprintState.idle => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: notifier.start,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Boshlash'),
        ),
      ),
      SprintState.running => Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: notifier.pause,
              icon: const Icon(Icons.pause_rounded,
                  color: AppColors.warning),
              label: const Text('Pauza',
                  style: TextStyle(color: AppColors.warning)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.warning),
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: notifier.reset,
              icon: const Icon(Icons.stop_rounded,
                  color: AppColors.error),
              label: const Text("To'xtat",
                  style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
      SprintState.paused => Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: notifier.resume,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Davom ettirish'),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: notifier.reset,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(52, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              side: const BorderSide(color: AppColors.border),
            ),
            child: const Icon(Icons.refresh_rounded,
                color: AppColors.textSecondary),
          ),
        ],
      ),
      SprintState.done => const SizedBox(),
    };
  }
}