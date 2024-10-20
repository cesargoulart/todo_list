import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting date and time

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
      debugShowCheckedModeBanner: false,
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
          createdTime: DateTime.now(), // Task creation date
          deadline: _selectedDeadline, // Task deadline
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

  // Function to select both date and time for deadline
  Future<void> _selectDeadline(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDeadline = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  List<Todo> _getSortedTodos() {
    return _todos.where((todo) => !_hideCompleted || !todo.isDone).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List'),
        actions: [
          IconButton(
            icon: Icon(_hideCompleted ? Icons.visibility_off : Icons.visibility),
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
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'New Todo',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.date_range),
                  onPressed: () => _selectDeadline(context),
                ),
                ElevatedButton(
                  onPressed: _addTodo,
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
          if (_selectedDeadline != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Selected Deadline: ${DateFormat('yyyy-MM-dd HH:mm').format(_selectedDeadline!)}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _getSortedTodos().length,
              itemBuilder: (context, index) {
                final todo = _getSortedTodos()[index];
                return ListTile(
                  leading: Checkbox(
                    value: todo.isDone,
                    onChanged: (_) => _toggleTodoStatus(index),
                  ),
                  title: Text(
                    todo.title,
                    style: TextStyle(
                      decoration: todo.isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Created: ${DateFormat('yyyy-MM-dd HH:mm').format(todo.createdTime)}'),
                      if (todo.deadline != null)
                        Text('Deadline: ${DateFormat('yyyy-MM-dd HH:mm').format(todo.deadline!)}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removeTodoItem(index),
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
