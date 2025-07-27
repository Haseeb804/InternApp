import 'package:flutter/material.dart';
import 'package:internship_portal/services/admin_service.dart';
import 'package:internship_portal/widgets/dashboard_layout.dart';

class AdminInterneeProgressScreen extends StatefulWidget {
  const AdminInterneeProgressScreen({Key? key}) : super(key: key);

  @override
  _AdminInterneeProgressScreenState createState() => _AdminInterneeProgressScreenState();
}

class _AdminInterneeProgressScreenState extends State<AdminInterneeProgressScreen> {
  bool _isLoading = true;
  List<dynamic> _progressList = [];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);
    try {
      final progress = await AdminService().getInterneeProgress();
      setState(() {
        _progressList = progress;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load internee progress'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Internee Progress',
      isAdmin: true,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _progressList.isEmpty
              ? const Center(child: Text('No progress data found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _progressList.length,
                  itemBuilder: (context, index) {
                    final item = _progressList[index];
                    return Card(
                      child: ListTile(
                        title: Text(item['username']),
                        subtitle: Text(
                            'Completed: ${item['completed_tasks']}, Pending: ${item['pending_tasks']}, Total: ${item['total_tasks']}'),
                        onTap: () {
                        //  Navigator.of(context).pop(); 
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
