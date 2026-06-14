import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

final firebaseAuthProvider =
Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final firestoreProvider =
Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final firebaseUser = ref.watch(authStateProvider).value;
  if (firebaseUser == null) return Stream.value(null);

  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(firebaseUser.uid)
      .snapshots()
      .map((doc) => doc.exists
      ? UserModel.fromMap(doc.data()!, doc.id)
      : null);
});

class AuthNotifier extends StateNotifier<AsyncValue<UserRole?>> {
  AuthNotifier(this.ref) : super(const AsyncValue.data(null));
  final Ref ref;

  FirebaseAuth get _auth => ref.read(firebaseAuthProvider);
  FirebaseFirestore get _db => ref.read(firestoreProvider);

  // Login — role qaytaradi
  Future<UserRole?> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firestore dan role ni bir marta o'qiymiz
      final doc = await _db
          .collection('users')
          .doc(cred.user!.uid)
          .get();

      if (!doc.exists) {
        state = const AsyncValue.data(null);
        return null;
      }

      final user = UserModel.fromMap(doc.data()!, doc.id);
      state = AsyncValue.data(user.role);
      return user.role;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<UserRole?> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? parentCode,
  }) async {
    state = const AsyncValue.loading();
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String? parentUid;
      if (role == UserRole.child && parentCode != null) {
        final snap = await _db
            .collection('users')
            .where('inviteCode', isEqualTo: parentCode)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) parentUid = snap.docs.first.id;
      }

      final user = UserModel(
        uid: cred.user!.uid,
        name: name,
        email: email,
        role: role,
        parentUid: parentUid,
      );

      await _db.collection('users').doc(cred.user!.uid).set(user.toMap());

      if (role == UserRole.parent) {
        final code = cred.user!.uid.substring(0, 6).toUpperCase();
        await _db
            .collection('users')
            .doc(cred.user!.uid)
            .update({'inviteCode': code});
      }

      state = AsyncValue.data(role);
      return role;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
StateNotifierProvider<AuthNotifier, AsyncValue<UserRole?>>(
        (ref) => AuthNotifier(ref));