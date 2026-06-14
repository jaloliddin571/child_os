enum TaskStatus { pending, completed, failed }
enum TaskSubject { math, english, uzbek, science, reading, other }

class TaskModel {
  final String id;
  final String title;
  final String childUid;
  final String parentUid;
  final TaskSubject subject;
  final TaskStatus status;
  final int xpReward;
  final int moneyReward; // so'mda
  final DateTime dueDate;
  final DateTime? completedAt;
  final String? photoUrl; // AI tekshiruv uchun

  const TaskModel({
    required this.id,
    required this.title,
    required this.childUid,
    required this.parentUid,
    required this.subject,
    this.status = TaskStatus.pending,
    this.xpReward = 20,
    this.moneyReward = 500,
    required this.dueDate,
    this.completedAt,
    this.photoUrl,
  });

  bool get isCompleted => status == TaskStatus.completed;
  bool get isPending => status == TaskStatus.pending;

  String get subjectEmoji => switch (subject) {
    TaskSubject.math => '📐',
    TaskSubject.english => '🇬🇧',
    TaskSubject.uzbek => '🇺🇿',
    TaskSubject.science => '🔬',
    TaskSubject.reading => '📖',
    TaskSubject.other => '✏️',
  };

  factory TaskModel.fromMap(Map<String, dynamic> map, String id) {
    return TaskModel(
      id: id,
      title: map['title'] ?? '',
      childUid: map['childUid'] ?? '',
      parentUid: map['parentUid'] ?? '',
      subject: TaskSubject.values.byName(map['subject'] ?? 'other'),
      status: TaskStatus.values.byName(map['status'] ?? 'pending'),
      xpReward: map['xpReward'] ?? 20,
      moneyReward: map['moneyReward'] ?? 500,
      dueDate: DateTime.parse(map['dueDate']),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
      photoUrl: map['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'childUid': childUid,
    'parentUid': parentUid,
    'subject': subject.name,
    'status': status.name,
    'xpReward': xpReward,
    'moneyReward': moneyReward,
    'dueDate': dueDate.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'photoUrl': photoUrl,
  };

  TaskModel copyWith({TaskStatus? status, DateTime? completedAt}) {
    return TaskModel(
      id: id,
      title: title,
      childUid: childUid,
      parentUid: parentUid,
      subject: subject,
      status: status ?? this.status,
      xpReward: xpReward,
      moneyReward: moneyReward,
      dueDate: dueDate,
      completedAt: completedAt ?? this.completedAt,
      photoUrl: photoUrl,
    );
  }
}