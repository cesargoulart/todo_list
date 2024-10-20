import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TodoListScreen(),
    );
  }
}

class Todo {
  String title;
  bool isDone;
  DateTime createdTime;
  DateTime? deadline;

  Todo({
    required this.title,
    this.isDone = false,
    required this.createdTime,
    this.deadline,
  });
}

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final List<Todo> _todos = [];
  final TextEditingController _controller = TextEditingController();
  bool _hideCompleted = false;
  DateTime? _selectedDeadline;

  void _addTodo() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _todos.add(Todo(
          title: _controller.text,
          createdTime: DateTime.now(),
          deadline: _selectedDeadline,
        ));
        _controller.clear();
        _selectedDeadline = null;
      });
    }
  }

  void _toggleTodoStatus(int sortedIndex) {
    final originalIndex = _todos.indexOf(_getSortedTodos()[sortedIndex]);
    setState(() {
      _todos[originalIndex].isDone = !_todos[originalIndex].isDone;
    });
  }

  void _removeTodoItem(int sortedIndex) {
    final originalIndex = _todos.indexOf(_getSortedTodos()[sortedIndex]);
    setState(() {
      _todos.removeAt(originalIndex);
    });
  }

  void _selectDeadline(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDeadline) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  List<Todo> _getSortedTodos() {
    List<Todo> sortedTodos = List.from(_todos);
    sortedTodos.sort((a, b) {
      if (a.deadline == null && b.deadline == null) return 0;
      if (a.deadline == null) return 1;
      if (b.deadline == null) return -1;
      return a.deadline!.compareTo(b.deadline!);
    });
    return sortedTodos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List'),
        actions: [
          IconButton(
            icon: Icon(_hideCompleted ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _hideCompleted = !_hideCompleted;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Enter todo',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDeadline(context),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTodo,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _getSortedTodos().length,
              itemBuilder: (context, sortedIndex) {
                final todo = _getSortedTodos()[sortedIndex];
                if (_hideCompleted && todo.isDone) {
                  return Container(); // Return an empty container for hidden items
                }
                return ListTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo.title,
                        style: TextStyle(
                          decoration: todo.isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      Text(
                        'Created at: ${todo.createdTime.hour}:${todo.createdTime.minute}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      if (todo.deadline != null)
                        Text(
                          'Deadline: ${todo.deadline!.day}/${todo.deadline!.month}/${todo.deadline!.year}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),
                  leading: Checkbox(
                    value: todo.isDone,
                    onChanged: (value) {
                      _toggleTodoStatus(sortedIndex);
                    },
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      _removeTodoItem(sortedIndex);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}