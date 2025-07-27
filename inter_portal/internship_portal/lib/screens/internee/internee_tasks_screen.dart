import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:internship_portal/models/task.dart';
import 'package:internship_portal/services/task_service.dart';
import 'package:internship_portal/widgets/common_widgets.dart';
import 'package:internship_portal/widgets/dashboard_layout.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

class InterneeTasksScreen extends StatefulWidget {
  const InterneeTasksScreen({Key? key}) : super(key: key);

  @override
  _InterneeTasksScreenState createState() => _InterneeTasksScreenState();
}

class _InterneeTasksScreenState extends State<InterneeTasksScreen> {
  final _taskService = TaskService();
  bool _isLoading = true;
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  final _dateFormat = DateFormat('MMM dd, yyyy');
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _sortBy = 'dueDate';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      _tasks = await _taskService.getInterneeAssignedTasks();
      _filterAndSortTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load tasks!'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  void _filterAndSortTasks() {
    _filteredTasks = _tasks.where((task) {
      final matchesSearch = task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          task.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _statusFilter == 'all' || task.status?.toLowerCase() == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    _filteredTasks.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'dueDate':
          comparison = (a.dueDate ?? DateTime.now())
              .compareTo(b.dueDate ?? DateTime.now());
          break;
        case 'title':
          comparison = a.title.compareTo(b.title);
          break;
        case 'status':
          comparison = (a.status ?? '').compareTo(b.status ?? '');
          break;
        default:
          comparison = 0;
      }
      return _sortAscending ? comparison : -comparison;
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Tasks'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Status'),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _statusFilter,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All')),
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'completed', child: Text('Completed')),
                DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
              ],
              onChanged: (value) {
                Navigator.pop(context);
                setState(() {
                  _statusFilter = value!;
                  _filterAndSortTasks();
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Tasks'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sort by'),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _sortBy,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'dueDate', child: Text('Due Date')),
                DropdownMenuItem(value: 'title', child: Text('Title')),
                DropdownMenuItem(value: 'status', child: Text('Status')),
              ],
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                  _filterAndSortTasks();
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Order'),
                const Spacer(),
                IconButton(
                  icon: FaIcon(
                    _sortAscending
                        ? FontAwesomeIcons.sortAmountDown
                        : FontAwesomeIcons.sortAmountUp,
                  ),
                  onPressed: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                      _filterAndSortTasks();
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitTask(Task task) async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null) {
        setState(() => _isLoading = true);
        try {
          final success = await _taskService.submitTask(
            task.taskId,
            result.files.first.bytes!,
            result.files.first.name,
          );
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Task submitted successfully')),
            );
            _loadTasks();
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to submit task'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error:  {e.toString()}'), backgroundColor: Colors.red),
            );
          }
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error:  {e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'My Tasks',
      isAdmin: false,
      actions: [
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.filter),
          onPressed: _showFilterDialog,
          tooltip: 'Filter tasks',
        ),
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.sort),
          onPressed: _showSortDialog,
          tooltip: 'Sort tasks',
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _filterAndSortTasks();
                });
              },
            ),
          ),
          Expanded(
            child: LoadingOverlay(
              isLoading: _isLoading,
              child: _filteredTasks.isEmpty
                  ? const Center(
                      child: Text('No tasks found'),
                    )
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = _filteredTasks[index];
                  final bool isSubmitted = task.submissionPath != null;
                  final bool isPending = task.status?.toLowerCase() == 'pending';

                  return Card(
                    child: ExpansionTile(
                      leading: const FaIcon(FontAwesomeIcons.tasks),
                      title: Text(task.title),
                      subtitle: Text(
                        task.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (task.dueDate != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Chip(
                                label: Text(_dateFormat.format(task.dueDate!)),
                                avatar: const FaIcon(
                                  FontAwesomeIcons.calendar,
                                  size: 12,
                                ),
                              ),
                            ),
                          if (task.status != null)
                            StatusChip(
                              status: task.status!,
                              backgroundColor: _getStatusColor(task.status!)
                                  .withOpacity(0.1),
                              textColor: _getStatusColor(task.status!),
                            ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Description:',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(task.description),
                              const SizedBox(height: 16),
                              if (isSubmitted) ...[
                                Row(
                                  children: [
                                    const FaIcon(
                                      FontAwesomeIcons.fileAlt,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        task.submissionPath!.split('/').last,
                                        style: const TextStyle(color: Colors.blue),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 16),
                              if (!isSubmitted && isPending)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: CustomButton(
                                    text: 'Submit Task',
                                    onPressed: () => _submitTask(task),
                                    icon: FontAwesomeIcons.upload,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
