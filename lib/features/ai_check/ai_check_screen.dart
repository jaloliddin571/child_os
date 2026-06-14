import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_button.dart';

// AI tekshiruv natijasi modeli
class AiResult {
  final int correct;
  final int total;
  final String feedback;
  final List<AiError> errors;
  final String encouragement;

  const AiResult({
    required this.correct,
    required this.total,
    required this.feedback,
    required this.errors,
    required this.encouragement,
  });

  int get score => total == 0 ? 0 : ((correct / total) * 100).round();

  factory AiResult.fromJson(Map<String, dynamic> j) => AiResult(
    correct: j['correct'] ?? 0,
    total: j['total'] ?? 0,
    feedback: j['feedback'] ?? '',
    errors: (j['errors'] as List? ?? [])
        .map((e) => AiError.fromJson(e))
        .toList(),
    encouragement: j['encouragement'] ?? '',
  );
}

class AiError {
  final int number;
  final String given;
  final String correct;
  final String hint;

  const AiError({
    required this.number,
    required this.given,
    required this.correct,
    required this.hint,
  });

  factory AiError.fromJson(Map<String, dynamic> j) => AiError(
    number: j['number'] ?? 0,
    given: j['given'] ?? '',
    correct: j['correct'] ?? '',
    hint: j['hint'] ?? '',
  );
}

// Provider
final aiCheckProvider =
StateNotifierProvider.autoDispose<AiCheckNotifier, AiCheckState>(
        (ref) => AiCheckNotifier());

class AiCheckState {
  final File? image;
  final bool isLoading;
  final AiResult? result;
  final String? error;

  const AiCheckState({
    this.image,
    this.isLoading = false,
    this.result,
    this.error,
  });

  AiCheckState copyWith({
    File? image,
    bool? isLoading,
    AiResult? result,
    String? error,
  }) =>
      AiCheckState(
        image: image ?? this.image,
        isLoading: isLoading ?? this.isLoading,
        result: result ?? this.result,
        error: error ?? this.error,
      );
}

class AiCheckNotifier extends StateNotifier<AiCheckState> {
  AiCheckNotifier() : super(const AiCheckState());

  final _picker = ImagePicker();

  Future<void> pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked == null) return;
    state = state.copyWith(
      image: File(picked.path),
      result: null,
      error: null,
    );
  }

  Future<void> analyze(String subject) async {
    if (state.image == null) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final bytes = await state.image!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final prompt = '''
Sen BolaJon OS ilovasining AI tekshiruvchisisanu O'zbek maktab o'quvchisining 
uy vazifasi rasmini ko'ryapsan (fan: $subject).

Vazifangiz:
1. Barcha javoblarni tekshir
2. To'g'ri va noto'g'rilarini aniqlash
3. O'zbek tilida qisqa izoh ber

Faqat JSON formatida javob ber, boshqa hech narsa yozma:
{
  "correct": <to'g'ri sonlar>,
  "total": <jami masalalar>,
  "feedback": "<umumiy baho O'zbek tilida>",
  "errors": [
    {
      "number": <misol nomeri>,
      "given": "<o'quvchi javobi>",
      "correct": "<to'g'ri javob>",
      "hint": "<qisqa maslahat>"
    }
  ],
  "encouragement": "<rag'batlantiruvchi gap>"
}
''';

      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': const String.fromEnvironment('ANTHROPIC_API_KEY'),
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 1000,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': 'image/jpeg',
                    'data': base64Image,
                  },
                },
                {'type': 'text', 'text': prompt},
              ],
            },
          ],
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('API xato: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final text = (data['content'] as List)
          .firstWhere((c) => c['type'] == 'text')['text'] as String;

      // JSON ni ajratib olish
      final jsonStr = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final result = AiResult.fromJson(jsonDecode(jsonStr));
      state = state.copyWith(isLoading: false, result: result);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Tahlil qilishda xato: $e',
      );
    }
  }

  void reset() => state = const AiCheckState();
}

// --- SCREEN ---

class AiCheckScreen extends ConsumerStatefulWidget {
  const AiCheckScreen({super.key});

  @override
  ConsumerState<AiCheckScreen> createState() => _AiCheckScreenState();
}

class _AiCheckScreenState extends ConsumerState<AiCheckScreen> {
  String _subject = 'Matematika';
  final _subjects = [
    'Matematika', 'Ingliz tili', 'Ona tili', 'Fan', 'Boshqa'
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiCheckProvider);
    final notifier = ref.read(aiCheckProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Tekshiruv'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fan tanlash
              const Text(
                'Fan tanlang',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _subjects.map((s) {
                    final sel = _subject == s;
                    return GestureDetector(
                      onTap: () => setState(() => _subject = s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.primary.withOpacity(0.15)
                              : AppColors.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: sel
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Text(s,
                            style: TextStyle(
                              fontSize: 13,
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: sel
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            )),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // Rasm yuklash
              GestureDetector(
                onTap: () => _showPickerSheet(context, notifier),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: state.image != null
                          ? AppColors.primary
                          : AppColors.border,
                      width: state.image != null ? 1.5 : 1,
                    ),
                  ),
                  child: state.image != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.file(
                      state.image!,
                      fit: BoxFit.cover,
                    ),
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.camera_alt_rounded,
                          size: 40, color: AppColors.textMuted),
                      SizedBox(height: 12),
                      Text(
                        'Uy vazifasini rasmga oling',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Kamera yoki galereyadan tanlang',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),

              if (state.error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Text(state.error!,
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 13)),
                ),
              ],

              const SizedBox(height: 16),

              // Tekshirish tugmasi
              if (state.result == null)
                AppButton(
                  label: state.image == null
                      ? 'Avval rasm tanlang'
                      : 'AI bilan tekshirish',
                  isLoading: state.isLoading,
                  onPressed: state.image == null
                      ? null
                      : () => notifier.analyze(_subject),
                ),

              // Natija
              if (state.result != null) ...[
                const SizedBox(height: 8),
                _ResultCard(result: state.result!),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: notifier.reset,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: const Text('Qayta tekshirish',
                      style:
                      TextStyle(color: AppColors.textSecondary)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showPickerSheet(BuildContext ctx, AiCheckNotifier notifier) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PickerOption(
              icon: Icons.camera_alt_rounded,
              label: 'Kamera',
              onTap: () {
                Navigator.pop(ctx);
                notifier.pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 10),
            _PickerOption(
              icon: Icons.photo_library_rounded,
              label: 'Galereya',
              onTap: () {
                Navigator.pop(ctx);
                notifier.pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PickerOption(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 14),
            Text(label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                )),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final AiResult result;
  const _ResultCard({required this.result});

  Color get _scoreColor {
    if (result.score >= 80) return AppColors.success;
    if (result.score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Score header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Natija',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${result.correct}/${result.total} to\'g\'ri',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        result.feedback,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _scoreColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${result.score}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _scoreColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Errors
          if (result.errors.isNotEmpty) ...[
            Divider(color: AppColors.border, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Xato tahlili',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...result.errors.map((e) => _ErrorRow(error: e)),
                ],
              ),
            ),
          ],

          // Encouragement
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.success.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Text('🌟', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result.encouragement,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.success,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final AiError error;
  const _ErrorRow({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${error.number}-misol',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${error.given} → ${error.correct}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '💡 ${error.hint}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}