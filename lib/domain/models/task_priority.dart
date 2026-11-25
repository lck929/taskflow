enum TaskPriority {
  low,
  medium,
  high,
}

class TaskModel {
  final String id;
  final String title;
  final String description;
  final DateTime? dueDate;
  final TaskPriority priority;
  final String assignee;
  final bool isCompleted;
  final DateTime createdAt;

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    this.dueDate,
    required this.priority,
    required this.assignee,
    this.isCompleted = false,
    required this.createdAt,
  });

  bool get isOverdue {
    if (isCompleted || dueDate == null) {
      return false;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final due = DateTime(
      dueDate!.year,
      dueDate!.month,
      dueDate!.day,
    );

    return due.isBefore(today);
  }

  TaskModel copyWith({
    String? title,
    String? description,
    TaskPriority? priority,
    String? assignee,
    bool? isCompleted,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate,
      priority: priority ?? this.priority,
      assignee: assignee ?? this.assignee,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority.name,
      'assignee': assignee,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      dueDate: json['dueDate'] == null
          ? null
          : DateTime.parse(json['dueDate'] as String),
      priority: TaskPriority.values.byName(
        json['priority'] as String,
      ),
      assignee: json['assignee'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
