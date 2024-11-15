// FILE: todo.dart

class Todo {
  int? id;
  String title;
  String description;
  DateTime createdTime;
  DateTime? deadline;
  bool isDone;
  String category;

  Todo({
    this.id,
    required this.title,
    required this.description,
    required this.createdTime,
    this.deadline,
    this.isDone = false,
    this.category = 'General',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isDone': isDone ? 1 : 0,
      'createdTime': createdTime.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'category': category,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      isDone: map['isDone'] == 1,
      createdTime: DateTime.parse(map['createdTime']),
      deadline: map['deadline'] != null ? DateTime.parse(map['deadline']) : null,
      category: map['category'] ?? 'General', // Provide a default value if null
    );
  }
}