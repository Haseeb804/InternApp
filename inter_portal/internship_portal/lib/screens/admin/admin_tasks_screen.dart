import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:internship_portal/models/task.dart';
import 'package:internship_portal/models/internship.dart';
import 'package:internship_portal/services/task_service.dart';
import 'package:internship_portal/services/internship_service.dart';
import 'package:internship_portal/widgets/common_widgets.dart';
import 'package:internship_portal/widgets/dashboard_layout.dart';
import 'package:internship_portal/services/user_service.dart';
import 'package:internship_portal/models/user.dart';
import 'package:intl/intl.dart';

class AdminTasksScreen extends StatefulWidget {
  const AdminTasksScreen({Key? key}) : super(key: key);

  @override
  _AdminTasksScreenState createState() => _AdminTasksScreenState();
}

class _AdminTasksScreenState extends State<AdminTasksScreen> {
  final _taskService = TaskService();
  final _internshipService = InternshipService();
  final _userService = UserService();
  bool _isLoading = true;
  List<Task> _tasks = [];
  List<Internship> _internships = [];
  List<User> _internees = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _tasks = await _taskService.getAdminTasks();
      _internships = await _internshipService.getAllInternships();
      _internees = await _userService.getAllInternees();
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddTaskDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    Internship? selectedInternship = _internships.isNotEmpty ? _internships.first : null;
    User? selectedInternee = _internees.isNotEmpty ? _internees.first : null;
    DateTime? dueDate;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Enter task title',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter task description',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Internship>(
                  value: selectedInternship,
                  decoration: const InputDecoration(
                    labelText: 'Internship',
                  ),
                  items: _internships.map((internship) => DropdownMenuItem(
                    value: internship,
                    child: Text(internship.title),
                  )).toList(),
                  onChanged: (value) {
                    setState(() => selectedInternship = value);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<User>(
                  value: selectedInternee,
                  decoration: const InputDecoration(
                    labelText: 'Assign to Internee',
                  ),
                  items: _internees.map((internee) => DropdownMenuItem(
                    value: internee,
                    child: Text(internee.username),
                  )).toList(),
                  onChanged: (value) {
                    setState(() => selectedInternee = value);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Due Date:'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(dueDate?.toLocal().toString().split(' ')[0] ?? 'None'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dueDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => dueDate = picked);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    descriptionController.text.isNotEmpty &&
                    selectedInternship != null &&
                    selectedInternee != null) {
                  final task = await _taskService.createTask(
                    selectedInternship?.internshipId ?? 0,
                    titleController.text,
                    descriptionController.text,
                    dueDate,
                  );
                  if (task != null) {
                    final assigned = await _taskService.assignTask(
                      task.taskId, 
                      selectedInternee?.userId ?? 0,
                    );
                    if (assigned) {
                      Navigator.pop(context, true);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Task created and assigned successfully!')),
                        );
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to assign task!'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all fields and select internship and internee'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  void _showEditTaskDialog(Task task) async {
    final titleController = TextEditingController(text: task.title);
    final descriptionController = TextEditingController(text: task.description);
    Internship? selectedInternship = _internships.firstWhere(
      (i) => i.internshipId == task.internshipId,
      orElse: () => _internships.first,
    );
    User? selectedInternee = _internees.isNotEmpty ? _internees.first : null;
    DateTime? dueDate = task.dueDate;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Internship>(
                  value: selectedInternship,
                  decoration: const InputDecoration(
                    labelText: 'Internship',
                  ),
                  items: _internships.map((internship) => DropdownMenuItem(
                    value: internship,
                    child: Text(internship.title),
                  )).toList(),
                  onChanged: (value) {
                    setState(() => selectedInternship = value);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<User>(
                  value: selectedInternee,
                  decoration: const InputDecoration(
                    labelText: 'Assign to Internee',
                  ),
                  items: _internees.map((internee) => DropdownMenuItem(
                    value: internee,
                    child: Text(internee.username),
                  )).toList(),
                  onChanged: (value) {
                    setState(() => selectedInternee = value);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Due Date:'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(dueDate?.toLocal().toString().split(' ')[0] ?? 'None'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dueDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => dueDate = picked);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    descriptionController.text.isNotEmpty &&
                    selectedInternship != null &&
                    selectedInternee != null) {
                  final updated = await _taskService.updateTask(
                    task.taskId,
                    titleController.text,
                    descriptionController.text,
                    selectedInternship?.internshipId ?? 0,
                    dueDate,
                  );
                  if (updated != null) {
                    final assignmentUpdated = await _taskService.updateAssignment(
                      task.taskId,
                      selectedInternee?.userId ?? 0,  
                    );
                    
                    if (assignmentUpdated) {
                      Navigator.pop(context, true);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Task updated successfully!')),
                        );
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to update task assignment!'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to update task!'), backgroundColor: Colors.red),
                      );
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all fields and select internship and internee'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Tasks',
      isAdmin: true,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskDialog,
        icon: const FaIcon(FontAwesomeIcons.plus),
        label: const Text('Add Task'),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: _tasks.isEmpty
            ? const Center(
                child: Text('No tasks found'),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  final internship = _internships.firstWhere(
                    (i) => i.internshipId == task.internshipId,
                    orElse: () => Internship(
                      internshipId: 0,
                      title: 'Unknown Internship',
                      description: '',
                      status: 'unknown',
                      createdBy: 0,
                      createdAt: DateTime.now(),
                    ),
                  );

                  return Card(
                    child: ListTile(
                      title: Text(task.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Internship: ${internship.title}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (task.dueDate != null) Text(
                            'Due: ${DateFormat('yyyy-MM-dd').format(task.dueDate!)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const FaIcon(FontAwesomeIcons.edit),
                            onPressed: () {
                              _showEditTaskDialog(task);
                            },
                          ),
                          IconButton(
                            icon: const FaIcon(FontAwesomeIcons.trash),
                            color: Colors.red,
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Task'),
                                  content: const Text('Are you sure you want to delete this task?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                final deleted = await _taskService.deleteTask(task.taskId);
                                if (deleted) {
                                  _loadData();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Task deleted successfully!')),
                                    );
                                  }
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Failed to delete task!'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}