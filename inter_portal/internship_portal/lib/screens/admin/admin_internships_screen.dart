import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:internship_portal/models/internship.dart';
import 'package:internship_portal/services/internship_service.dart';
import 'package:internship_portal/widgets/common_widgets.dart';
import 'package:internship_portal/widgets/dashboard_layout.dart';

class AdminInternshipsScreen extends StatefulWidget {
  const AdminInternshipsScreen({Key? key}) : super(key: key);

  @override
  _AdminInternshipsScreenState createState() => _AdminInternshipsScreenState();
}

class _AdminInternshipsScreenState extends State<AdminInternshipsScreen> {
  final _internshipService = InternshipService();
  bool _isLoading = true;
  List<Internship> _internships = [];

  @override
  void initState() {
    super.initState();
    _loadInternships();
  }

  Future<void> _loadInternships() async {
    setState(() => _isLoading = true);
    _internships = await _internshipService.getAllInternships();
    setState(() => _isLoading = false);
  }

  Future<void> _showAddInternshipDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String status = 'available';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Internship'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter internship title',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter internship description',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                ),
                items: const [
                  DropdownMenuItem(value: 'available', child: Text('Available')),
                  DropdownMenuItem(value: 'not available', child: Text('Not Available')),
                ],
                onChanged: (value) {
                  setState(() => status = value!);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty && descriptionController.text.isNotEmpty) {
                  final internship = await _internshipService.createInternship(
                    titleController.text,
                    descriptionController.text,
                    status,
                  );
                  if (internship != null) {
                    Navigator.pop(context, true);
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      _loadInternships();
    }
  }

  void _showEditInternshipDialog(Internship internship) async {
    final titleController = TextEditingController(text: internship.title);
    final descriptionController = TextEditingController(text: internship.description);
    String status = internship.status;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Internship'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'available', child: Text('Available')),
                  DropdownMenuItem(value: 'not available', child: Text('Not Available')),
                ],
                onChanged: (value) => setState(() => status = value!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty && descriptionController.text.isNotEmpty) {
                  final updated = await _internshipService.updateInternship(
                    internship.internshipId, titleController.text, descriptionController.text, status,
                  );
                  if (updated) {
                    Navigator.pop(context, true);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Internship updated successfully!')),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to update internship!'), backgroundColor: Colors.red),
                      );
                    }
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (result == true) _loadInternships();
  }

  Future<void> _deleteInternship(int internshipId) async {
  try {
    setState(() => _isLoading = true);
    final response = await _internshipService.deleteInternship(internshipId);
    
    if (response['success'] == true) {
      // Optimistic update - remove from local list immediately
      setState(() {
        _internships.removeWhere((internship) => internship.internshipId == internshipId);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${response['data']['title']} deleted successfully!'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete internship!'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  void _showDeleteInternshipDialog(Internship internship) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Internship'),
        content: const Text('This will delete the internship and all related tasks. Are you sure?'),
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
      await _deleteInternship(internship.internshipId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Internships',
      isAdmin: true,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddInternshipDialog,
        icon: const FaIcon(FontAwesomeIcons.plus),
        label: const Text('Add Internship'),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: _internships.isEmpty
            ? const Center(
                child: Text('No internships found'),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _internships.length,
                itemBuilder: (context, index) {
                  final internship = _internships[index];
                  return Card(
                    child: ListTile(
                      title: Text(internship.title),
                      subtitle: Text(
                        internship.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatusChip(
                            status: internship.status,
                            backgroundColor: internship.status == 'available'
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            textColor: internship.status == 'available'
                                ? Colors.green
                                : Colors.red,
                          ),
                          IconButton(
                            icon: const FaIcon(FontAwesomeIcons.edit),
                            onPressed: () {
                              _showEditInternshipDialog(internship);
                            },
                          ),
                          IconButton(
                            icon: const FaIcon(FontAwesomeIcons.trash),
                            color: Colors.red,
                            onPressed: () {
                              _showDeleteInternshipDialog(internship);
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