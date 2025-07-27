import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:internship_portal/models/task.dart';
import 'package:internship_portal/services/task_service.dart';
import 'package:internship_portal/widgets/common_widgets.dart';
import 'package:internship_portal/widgets/dashboard_layout.dart';

class InterneeProgressScreen extends StatefulWidget {
  const InterneeProgressScreen({Key? key}) : super(key: key);

  @override
  _InterneeProgressScreenState createState() => _InterneeProgressScreenState();
}

class _InterneeProgressScreenState extends State<InterneeProgressScreen> {
  final _taskService = TaskService();
  bool _isLoading = true;
  List<Task> _completedTasks = [];
  List<Task> _pendingTasks = [];
  List<Task> _inProgressTasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await _taskService.getInterneeAssignedTasks();
      setState(() {
        _completedTasks = tasks.where((t) => t.status?.toLowerCase() == 'completed').toList();
        _pendingTasks = tasks.where((t) => t.status?.toLowerCase() == 'pending').toList();
        _inProgressTasks = tasks.where((t) => t.status?.toLowerCase() == 'in_progress').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load progress!'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'My Progress',
      isAdmin: false,
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressOverview(),
              const SizedBox(height: 24),
              _buildTasksSection('Completed Tasks', _completedTasks, Colors.green),
              _buildTasksSection('In Progress Tasks', _inProgressTasks, Colors.blue),
              _buildTasksSection('Pending Tasks', _pendingTasks, Colors.orange),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressOverview() {
    final total = _completedTasks.length + _pendingTasks.length + _inProgressTasks.length;
    final completionRate = total > 0 ? (_completedTasks.length / total * 100) : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall Progress',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  'Completed',
                  _completedTasks.length,
                  FontAwesomeIcons.checkCircle,
                  Colors.green,
                ),
                _buildStatCard(
                  'In Progress',
                  _inProgressTasks.length,
                  FontAwesomeIcons.spinner,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Pending',
                  _pendingTasks.length,
                  FontAwesomeIcons.clock,
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: completionRate / 100,
              backgroundColor: Colors.grey[200],
              color: Colors.green,
            ),
            const SizedBox(height: 8),
            Text(
              'Completion Rate: ${completionRate.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Column(
      children: [
        FaIcon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTasksSection(String title, List<Task> tasks, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              FaIcon(FontAwesomeIcons.tasks, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No $title',
              style: TextStyle(color: Colors.grey[600]),
            ),
          )
        else
          ...tasks.map((task) => Card(
                child: ListTile(
                  leading: const FaIcon(FontAwesomeIcons.fileAlt),
                  title: Text(task.title),
                  subtitle: Text(
                    task.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: task.submissionPath != null
                      ? const FaIcon(
                          FontAwesomeIcons.checkDouble,
                          color: Colors.green,
                        )
                      : null,
                ),
              )),
      ],
    );
  }
}
