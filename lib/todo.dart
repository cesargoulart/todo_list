class Todo {
  int? id;
  String title;
  bool isDone;
  DateTime createdTime;
  DateTime? deadline;
  String category; // New field

  Todo({
    this.id,
    required this.title,
    this.isDone = false,
    required this.createdTime,
    this.deadline,
    this.category = 'General', // New parameter with default value
    
    
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isDone': isDone ? 1 : 0,
      'createdTime': createdTime.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'],
      title: map['title'],
      isDone: map['isDone'] == 1,
      createdTime: DateTime.parse(map['createdTime']),
      deadline: map['deadline'] != null ? DateTime.parse(map['deadline']) : null,
    );
  }
}