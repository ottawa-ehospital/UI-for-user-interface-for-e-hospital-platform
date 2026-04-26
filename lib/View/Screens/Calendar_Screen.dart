import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CalendarScreen extends StatefulWidget {
  final String doctorId;

  const CalendarScreen({super.key, required this.doctorId});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Task>> _tasks = {};
  bool _isLoading = false;

  String get doctorId => widget.doctorId;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(
          'https://tysnx3mi2s.us-east-1.awsapprunner.com/api/users/tasks',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      print('Fetch tasks response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> tasksJson = jsonDecode(response.body);
        final Map<DateTime, List<Task>> groupedTasks = {};

        for (var taskJson in tasksJson) {
          final task = Task.fromJson(taskJson);
          final dateKey = DateTime.utc(task.date.year, task.date.month, task.date.day);
          
          if (groupedTasks[dateKey] == null) {
            groupedTasks[dateKey] = [];
          }
          groupedTasks[dateKey]!.add(task);
        }

        setState(() {
          _tasks = groupedTasks;
        });
      } else {
        throw Exception('Failed to fetch tasks: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching tasks: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load tasks: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createTask(Task task) async {
    try {
      final taskDateTime = DateTime(
        task.date.year,
        task.date.month,
        task.date.day,
        task.time.hour,
        task.time.minute,
      );

      final requestBody = {
        'Doctor': doctorId,
        'Patient': task.patientId ?? '',
        'Title': task.title,
        'Start': taskDateTime.toIso8601String(),
        'End': taskDateTime.add(const Duration(hours: 1)).toIso8601String(),
        'Description':
            task.description.isNotEmpty ? task.description : task.title,
      };

      print('Creating task with body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('https://tysnx3mi2s.us-east-1.awsapprunner.com/api/users/tasks/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('Create task response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _fetchTasks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task created successfully')),
          );
        }
      } else {
        throw Exception('Failed to create task: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error creating task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create task: $e')),
        );
      }
    }
  }

  Future<void> _updateTask(Task task) async {
    try {
      final taskDateTime = DateTime(
        task.date.year,
        task.date.month,
        task.date.day,
        task.time.hour,
        task.time.minute,
      );

      final requestBody = {
        'Patient': task.patientId ?? '',
        'Title': task.title,
        'Description':
            task.description.isNotEmpty ? task.description : task.title,
        'Start': taskDateTime.toIso8601String(),
        'End': taskDateTime.add(const Duration(hours: 1)).toIso8601String(),
      };

      print('Updating task ${task.id} with body: ${jsonEncode(requestBody)}');

      final response = await http.put(
        Uri.parse('https://tysnx3mi2s.us-east-1.awsapprunner.com/api/users/tasks/${task.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('Update task response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        await _fetchTasks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task updated successfully')),
          );
        }
      } else {
        throw Exception('Failed to update task: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error updating task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update task: $e')),
        );
      }
    }
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      print('Deleting task: $taskId');

      final response = await http.delete(
        Uri.parse('https://tysnx3mi2s.us-east-1.awsapprunner.com/api/users/tasks/$taskId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Delete task response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        await _fetchTasks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task deleted successfully')),
          );
        }
      } else {
        throw Exception('Failed to delete task: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error deleting task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete task: $e')),
        );
      }
    }
  }

  List<Task> _getTasksForDay(DateTime day) {
    return _tasks[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;

          return _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Calendar",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 24),

                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: TableCalendar(
                            firstDay: DateTime.utc(2020, 1, 1),
                            lastDay: DateTime.utc(2030, 12, 31),
                            focusedDay: _focusedDay,
                            selectedDayPredicate: (day) =>
                                isSameDay(_selectedDay, day),
                            calendarFormat: CalendarFormat.month,
                            startingDayOfWeek: StartingDayOfWeek.monday,
                            eventLoader: _getTasksForDay,
                            calendarStyle: CalendarStyle(
                              todayDecoration: BoxDecoration(
                                color: const Color(0xFF3F51B5).withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              selectedDecoration: const BoxDecoration(
                                color: Color(0xFF3F51B5),
                                shape: BoxShape.circle,
                              ),
                              markerDecoration: const BoxDecoration(
                                color: Color(0xFFFF5252),
                                shape: BoxShape.circle,
                              ),
                              weekendTextStyle:
                                  const TextStyle(color: Colors.black87),
                              outsideDaysVisible: true,
                              outsideTextStyle:
                                  TextStyle(color: Colors.grey[400]),
                            ),
                            headerStyle: HeaderStyle(
                              formatButtonVisible: false,
                              titleCentered: true,
                              titleTextStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                              leftChevronIcon: const Icon(
                                Icons.chevron_left,
                                color: Color(0xFF3F51B5),
                              ),
                              rightChevronIcon: const Icon(
                                Icons.chevron_right,
                                color: Color(0xFF3F51B5),
                              ),
                            ),
                            daysOfWeekStyle: DaysOfWeekStyle(
                              weekdayStyle: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                              weekendStyle: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            },
                            onPageChanged: (focusedDay) {
                              setState(() {
                                _focusedDay = focusedDay;
                              });
                              _fetchTasks();
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Tasks for ${DateFormat('MMM dd, yyyy').format(_selectedDay ?? DateTime.now())}",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () =>
                                          _showAddTaskDialog(context),
                                      icon: const Icon(Icons.add, size: 20),
                                      label: const Text("Add Task"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF3F51B5),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      "Tasks for ${DateFormat('MMM dd, yyyy').format(_selectedDay ?? DateTime.now())}",
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _showAddTaskDialog(context),
                                    icon: const Icon(Icons.add, size: 20),
                                    label: const Text("Add Task"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFF3F51B5),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                        const SizedBox(height: 16),
                        _buildTaskList(),
                      ],
                    ),
                  ),
                );
        },
      ),
    );
  }

  Widget _buildTaskList() {
    final tasks = _getTasksForDay(_selectedDay ?? DateTime.now());

    if (tasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.event_note, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                "No tasks for this day",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildTaskCard(task);
      },
    );
  }

  Widget _buildTaskCard(Task task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: task.priority.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                task.priority.icon,
                color: task.priority.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        task.time.format(context),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: task.priority.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          task.priority.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: task.priority.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      task.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) async {
                if (value == 'edit') {
                  _showEditTaskDialog(context, task);
                } else if (value == 'delete') {
                  await _deleteTask(task.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        selectedDate: _selectedDay ?? DateTime.now(),
        onTaskAdded: (task) async {
          await _createTask(task);
        },
      ),
    );
  }

  void _showEditTaskDialog(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        selectedDate: task.date,
        existingTask: task,
        onTaskAdded: (updatedTask) async {
          await _updateTask(updatedTask);
        },
      ),
    );
  }
}

class Task {
  final String id;
  final String title;
  final TaskPriority priority;
  final DateTime date;
  final TimeOfDay time;
  final String description;
  final String? patientId;

  Task({
    required this.id,
    required this.title,
    required this.priority,
    required this.date,
    required this.time,
    required this.description,
    this.patientId,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    final startTime = DateTime.parse(json['Start']);

    return Task(
      id: json['id'].toString(),
      title: json['Title'] ?? json['Description'] ?? 'Task',
      priority: TaskPriority.none,
      date: startTime,
      time: TimeOfDay(hour: startTime.hour, minute: startTime.minute),
      description: json['Description'] ?? '',
      patientId: json['Patient']?.toString(),
    );
  }
}

enum TaskPriority {
  high,
  medium,
  low,
  none;

  String get label {
    switch (this) {
      case TaskPriority.high:
        return 'High Priority';
      case TaskPriority.medium:
        return 'Medium Priority';
      case TaskPriority.low:
        return 'Low Priority';
      case TaskPriority.none:
        return 'No Priority';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.high:
        return const Color(0xFFFF5252);
      case TaskPriority.medium:
        return const Color(0xFF4CAF50);
      case TaskPriority.low:
        return const Color(0xFFFFC107);
      case TaskPriority.none:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData get icon {
    switch (this) {
      case TaskPriority.high:
        return Icons.flag;
      case TaskPriority.medium:
        return Icons.flag;
      case TaskPriority.low:
        return Icons.flag;
      case TaskPriority.none:
        return Icons.flag_outlined;
    }
  }
}

class AddTaskDialog extends StatefulWidget {
  final DateTime selectedDate;
  final Task? existingTask;
  final Function(Task) onTaskAdded;

  const AddTaskDialog({
    super.key,
    required this.selectedDate,
    this.existingTask,
    required this.onTaskAdded,
  });

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _patientIdController = TextEditingController();

  TaskPriority _selectedPriority = TaskPriority.none;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _showPriorityDropdown = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _selectedTime = TimeOfDay.now();

    if (widget.existingTask != null) {
      _titleController.text = widget.existingTask!.title;
      _descriptionController.text = widget.existingTask!.description;
      _patientIdController.text = widget.existingTask!.patientId ?? '';
      _selectedPriority = widget.existingTask!.priority;
      _selectedDate = widget.existingTask!.date;
      _selectedTime = widget.existingTask!.time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      elevation: 24,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.existingTask != null
                          ? "Edit task"
                          : "Add a new task",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon:
                          const Icon(Icons.close, color: Color(0xFF3F51B5)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                const Text("Title",
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: "Enter task title",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFF3F51B5)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter a title' : null,
                ),
                const SizedBox(height: 20),

                const Text("Patient ID (Optional)",
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _patientIdController,
                  decoration: InputDecoration(
                    hintText: "Enter patient ID",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFF3F51B5)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 20),

                const Text("Priority",
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () =>
                      setState(() => _showPriorityDropdown = !_showPriorityDropdown),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(_selectedPriority.icon,
                                color: _selectedPriority.color, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _selectedPriority.label,
                              style: TextStyle(
                                color: _selectedPriority == TaskPriority.none
                                    ? Colors.grey[600]
                                    : _selectedPriority.color,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          _showPriorityDropdown
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showPriorityDropdown) ...[
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[300]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: TaskPriority.values.map((priority) {
                        return InkWell(
                          onTap: () => setState(() {
                            _selectedPriority = priority;
                            _showPriorityDropdown = false;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: priority != TaskPriority.values.last
                                    ? BorderSide(color: Colors.grey[200]!)
                                    : BorderSide.none,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(priority.icon,
                                    color: priority.color, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  priority.label,
                                  style: TextStyle(
                                    color: priority.color,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                const Text("Date/Time",
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setState(() => _selectedDate = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 20, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedDate != null
                                      ? DateFormat('MMM dd, yyyy')
                                          .format(_selectedDate!)
                                      : 'Select Date',
                                  style: TextStyle(
                                    color: _selectedDate != null
                                        ? Colors.black87
                                        : Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime ?? TimeOfDay.now(),
                          );
                          if (time != null) {
                            setState(() => _selectedTime = time);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 20, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                _selectedTime != null
                                    ? _selectedTime!.format(context)
                                    : 'Select Time',
                                style: TextStyle(
                                  color: _selectedTime != null
                                      ? Colors.black87
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const Text("Description",
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Enter task description",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFF3F51B5)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text("Cancel",
                          style: TextStyle(color: Colors.black87)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate() &&
                            _selectedDate != null &&
                            _selectedTime != null) {
                          print('=== Task Form Values ===');
                          print('ID: ${widget.existingTask?.id ?? "NEW"}');
                          print('Title: ${_titleController.text}');
                          print('Description: ${_descriptionController.text}');
                          print('Patient ID: ${_patientIdController.text}');
                          print('Date: $_selectedDate');
                          print('Time: $_selectedTime');
                          print('Priority: $_selectedPriority');

                          final task = Task(
                            id: widget.existingTask?.id ?? '',
                            title: _titleController.text.trim(),
                            priority: _selectedPriority,
                            date: _selectedDate!,
                            time: _selectedTime!,
                            description: _descriptionController.text.trim(),
                            patientId: _patientIdController.text.trim().isNotEmpty
                                ? _patientIdController.text.trim()
                                : null,
                          );

                          widget.onTaskAdded(task);
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please fill all required fields (Title, Date, Time)',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3F51B5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(widget.existingTask != null ? "Update" : "Add"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _patientIdController.dispose();
    super.dispose();
  }
}