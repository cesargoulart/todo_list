import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'database_helper.dart';
import 'todo.dart';
import 'dart:io'; // Import Platform class
import 'dart:async'; // Import Timer

void main() {
  // Check the platform and initialize the database accordingly
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Initialize FFI for desktop platforms
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  } else {
    // Use the default database factory for mobile platforms
    databaseFactory = databaseFactory;
  }

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
  bool _hideTasksOverThreeDays = false; // New state variable for the 3-day filter
  DateTime? _selectedDeadline;
  String _selectedCategory = 'General'; // New state variable for category
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Timer? _deadlineTimer; // Timer to check deadlines

  @override
  void initState() {
    super.initState();
    _loadTodos();
    _startDeadlineTimer(); // Start the timer
  }

  @override
  void dispose() {
    _deadlineTimer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  Future<void> _loadTodos() async {
    final todos = await _dbHelper.getTodos();
    setState(() {
      _todos.addAll(todos);
    });
  }

  void _startDeadlineTimer() {
    _deadlineTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _checkDeadlines();
    });
  }

  void _checkDeadlines() {
    final now = DateTime.now();
    for (final todo in _todos) {
      if (todo.deadline != null && todo.deadline!.isBefore(now) && !todo.isDone) {
        _showDeadlineDialog(todo);
      }
    }
  }

  void _showDeadlineDialog(Todo todo) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Deadline Reached'),
          content: Text('The deadline for "${todo.title}" has been reached.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _addTodo() async {
    if (_controller.text.isNotEmpty) {
      final newTodo = Todo(
        title: _controller.text,
        createdTime: DateTime.now(),
        deadline: _selectedDeadline,
        category: _selectedCategory, // New field
      );
      final id = await _dbHelper.insertTodo(newTodo);
      setState(() {
        _todos.add(newTodo..id = id);
        _controller.clear();
        _selectedDeadline = null;
        _selectedCategory = 'General'; // Reset category
      });
    }
  }
void _editTodo(Todo todo) async {
  // Store the current values temporarily
  final TextEditingController editController = TextEditingController(text: todo.title);
  DateTime? editDeadline = todo.deadline;
  String editCategory = todo.category;

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit Todo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: editController,
            decoration: const InputDecoration(labelText: 'Task'),
          ),
          // Add deadline picker
          ElevatedButton(
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: editDeadline ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2101),
              );
              if (picked != null) {
                editDeadline = picked;
              }
            },
            child: const Text('Select Deadline'),
          ),
          // Add category dropdown
          DropdownButton<String>(
            value: editCategory,
            items: ['General', 'Work', 'Personal'] // Add your categories
                .map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                editCategory = newValue;
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            if (editController.text.isNotEmpty) {
              todo.title = editController.text;
              todo.deadline = editDeadline;
              todo.category = editCategory;
              
              await _dbHelper.updateTodo(todo);
              
              setState(() {
                // Update the todo in the list
                final index = _todos.indexWhere((t) => t.id == todo.id);
                if (index != -1) {
                  _todos[index] = todo;
                }
              });
              
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
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
        if (todo.deadline == null) return true; // Keep tasks with no deadline
        return todo.deadline!.isBefore(threeDaysLater); // Filter out tasks with deadlines > 3 days
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
          IconButton(
            icon: Icon(_hideTasksOverThreeDays ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _hideTasksOverThreeDays = !_hideTasksOverThreeDays;
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
                DropdownButton<String>(
                  value: _selectedCategory,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                  items: <String>['General', 'Work', 'Personal', 'Shopping']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTodo,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _toggleThreeDayFilter, // Button to toggle the 3-day filter
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
      Text(
        'Category: ${todo.category}',
        style: TextStyle(
          fontSize: 12,
          color: Colors.blue,
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
  // Replace the existing trailing with this:
  trailing: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () => _editTodo(todo),
      ),
      IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () {
          _removeTodoItem(sortedIndex);
        },
      ),
    ],
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