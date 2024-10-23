import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'database_helper.dart';
import 'todo.dart';

void main() {
  // Initialize FFI
  sqfliteFfiInit();
  // Change the default factory
  databaseFactory = databaseFactoryFfi;
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

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final List<Todo> _todos = [];
  final TextEditingController _controller = TextEditingController();
  bool _hideCompleted = false;
  bool _hideTasksOverThreeDays = false;  // New state variable for the 3-day filter
  DateTime? _selectedDeadline;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    final todos = await _dbHelper.getTodos();
    setState(() {
      _todos.addAll(todos);
    });
  }

  void _addTodo() async {
    if (_controller.text.isNotEmpty) {
      final newTodo = Todo(
        title: _controller.text,
        createdTime: DateTime.now(),
        deadline: _selectedDeadline,
      );
      final id = await _dbHelper.insertTodo(newTodo);
      setState(() {
        _todos.add(newTodo..id = id);
        _controller.clear();
        _selectedDeadline = null;
      });
    }
  }

  void _toggleTodoStatus(int sortedIndex) async {
    final originalIndex = _todos.indexOf(_getSortedTodos()[sortedIndex]);
    final todo = _todos[originalIndex];
    todo.isDone = !todo.isDone;
    await _dbHelper.updateTodo(todo);
    setState(() {
      _todos[originalIndex] = todo;
    });
  }

  void _removeTodoItem(int sortedIndex) async {
    final originalIndex = _todos.indexOf(_getSortedTodos()[sortedIndex]);
    final todo = _todos[originalIndex];
    await _dbHelper.deleteTodo(todo.id!);
    setState(() {
      _todos.removeAt(originalIndex);
    });
  }

  // Function to filter tasks with deadlines over 3 days from now
  List<Todo> _getSortedTodos() {
    List<Todo> sortedTodos = List.from(_todos);
    sortedTodos.sort((a, b) {
      if (a.deadline == null && b.deadline == null) return 0;
      if (a.deadline == null) return 1;
      if (b.deadline == null) return -1;
      return a.deadline!.compareTo(b.deadline!);
    });

    if (_hideTasksOverThreeDays) {
      final now = DateTime.now();
      final threeDaysLater = now.add(const Duration(days: 3));
      sortedTodos = sortedTodos.where((todo) {
        if (todo.deadline == null) return true;  // Keep tasks with no deadline
        return todo.deadline!.isBefore(threeDaysLater);  // Filter out tasks with deadlines > 3 days
      }).toList();
    }

    return sortedTodos;
  }

  // Function to toggle the 3-day deadline filter
  void _toggleThreeDayFilter() {
    setState(() {
      _hideTasksOverThreeDays = !_hideTasksOverThreeDays;
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
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _selectedDeadline = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
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
          ElevatedButton(
            onPressed: _toggleThreeDayFilter,  // Button to toggle the 3-day filter
            child: Text(
              _hideTasksOverThreeDays
                  ? 'Show All Tasks'
                  : 'Hide Tasks with Deadline > 3 Days',
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
                        'Created at: ${DateFormat('yyyy-MM-dd HH:mm').format(todo.createdTime)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      if (todo.deadline != null)
                        Text(
                          'Deadline: ${DateFormat('yyyy-MM-dd HH:mm').format(todo.deadline!)}',
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
                  )5
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
