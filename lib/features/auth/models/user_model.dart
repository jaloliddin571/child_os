enum UserRole { parent, child }

class UserModel {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? parentUid; // faqat bola uchun
  final int xp;
  final int balance; // so'mda

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.parentUid,
    this.xp = 0,
    this.balance = 0,
  });

  bool get isParent => role == UserRole.parent;

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] == 'parent' ? UserRole.parent : UserRole.child,
      parentUid: map['parentUid'],
      xp: map['xp'] ?? 0,
      balance: map['balance'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'role': role.name,
    'parentUid': parentUid,
    'xp': xp,
    'balance': balance,
    'createdAt': DateTime.now().toIso8601String(),
  };
}