import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../../auth/providers/auth_provider.dart';

// Bolaning bugungi vazifalari
final childTasksProvider =
StreamProvider.family<List<TaskModel>, String>((ref, childUid) {
  final db = ref.watch(firestoreProvider);
  final today = DateTime.now();
  final start = DateTime(today.year, today.month, today.day);
  final end = start.add(const Duration(days: 1));

  return db
      .collection('tasks')
      .where('childUid', isEqualTo: childUid)
      .where('dueDate',
      isGreaterThanOrEqualTo: start.toIso8601String(),
      isLessThan: end.toIso8601String())
      .snapshots()
      .map((snap) => snap.docs
      .map((d) => TaskModel.fromMap(d.data(), d.id))
      .toList());
});

// Ota-ona uchun barcha bolalar vazifalari
final parentTasksProvider =
StreamProvider.family<List<TaskModel>, String>((ref, parentUid) {
  final db = ref.watch(firestoreProvider);
  return db
      .collection('tasks')
      .where('parentUid', isEqualTo: parentUid)
      .orderBy('dueDate', descending: true)
      .limit(20)
      .snapshots()
      .map((snap) => snap.docs
      .map((d) => TaskModel.fromMap(d.data(), d.id))
      .toList());
});

class TaskNotifier extends StateNotifier<AsyncValue<void>> {
  TaskNotifier(this.ref) : super(const AsyncValue.data(null));
  final Ref ref;

  FirebaseFirestore get _db => ref.read(firestoreProvider);

  Future<void> addTask(TaskModel task) async {
    state = const AsyncValue.loading();
    try {
      await _db.collection('tasks').add(task.toMap());
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> completeTask(TaskModel task) async {
    try {
      // Vazifani tugatish
      await _db.collection('tasks').doc(task.id).update({
        'status': TaskStatus.completed.name,
        'completedAt': DateTime.now().toIso8601String(),
      });

      // Bolaga XP va pul qo'shish
      await _db.collection('users').doc(task.childUid).update({
        'xp': FieldValue.increment(task.xpReward),
        'balance': FieldValue.increment(task.moneyReward),
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTask(String taskId) async {
    await _db.collection('tasks').doc(taskId).delete();
  }
}

final taskNotifierProvider =
StateNotifierProvider<TaskNotifier, AsyncValue<void>>(
        (ref) => TaskNotifier(ref));
