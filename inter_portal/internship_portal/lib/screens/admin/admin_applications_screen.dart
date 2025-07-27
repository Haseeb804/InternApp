import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:internship_portal/services/internship_service.dart';
import 'package:internship_portal/widgets/common_widgets.dart';
import 'package:internship_portal/widgets/dashboard_layout.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminApplicationsScreen extends StatefulWidget {
  const AdminApplicationsScreen({Key? key}) : super(key: key);

  @override
  _AdminApplicationsScreenState createState() => _AdminApplicationsScreenState();
}

class _AdminApplicationsScreenState extends State<AdminApplicationsScreen> {
  final _internshipService = InternshipService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _applications = [];
  final _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    _applications = await _internshipService.getApplications();
    setState(() => _isLoading = false);
  }

  Future<void> _updateApplicationStatus(int applicationId, String status) async {
    try {
      setState(() => _isLoading = true);
      final success = await _internshipService.updateApplicationStatus(
        applicationId,
        status,
      );
      if (success) {
        await _loadApplications();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Application $status successfully')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update application!'), backgroundColor: Colors.red),
          );
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
  

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Internship Applications',
      isAdmin: true,
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: _applications.isEmpty
            ? const Center(
                child: Text('No applications found'),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _applications.length,
                itemBuilder: (context, index) {
                  final application = _applications[index];
                  final isPending = application['status'] == 'pending';

                  return Card(
                    child: ExpansionTile(
                      leading: const CircleAvatar(
                        child: FaIcon(FontAwesomeIcons.userGraduate),
                      ),
                      title: Text(application['internee_name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(application['internship_title']),
                          Text(
                            'Applied on: ${_dateFormat.format(DateTime.parse(application['applied_at']))}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      trailing: StatusChip(
                        status: application['status'],
                        backgroundColor: _getStatusColor(application['status'])
                            .withOpacity(0.1),
                        textColor: _getStatusColor(application['status']),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const FaIcon(FontAwesomeIcons.envelope,
                                      size: 16),
                                  const SizedBox(width: 8),
                                  Text(application['internee_email']),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const FaIcon(FontAwesomeIcons.school,
                                      size: 16),
                                  const SizedBox(width: 8),
                                  Text(application['universityname'] ?? ''),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const FaIcon(FontAwesomeIcons.book,
                                      size: 16),
                                  const SizedBox(width: 8),
                                  Text(application['degree'] ?? ''),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const FaIcon(FontAwesomeIcons.user,
                                      size: 16),
                                  const SizedBox(width: 8),
                                  Text(application['name'] ?? ''),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const FaIcon(FontAwesomeIcons.calendar,
                                      size: 16),
                                  const SizedBox(width: 8),
                                  Text(application['semester'] ?? ''),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const FaIcon(FontAwesomeIcons.filePdf,
                                      size: 16, color: Colors.red),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () async {
                                      final url = '${InternshipService.baseUrl}/${application['resumepath'] ?? ''}';
                                      if (await canLaunchUrl(Uri.parse(url))) {
                                        await launchUrl(Uri.parse(url));
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Could not open resume')),
                                        );
                                      }
                                    },
                                    child: const Text('Download Resume'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (isPending)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    CustomButton(
                                      text: 'Reject',
                                      onPressed: () => _updateApplicationStatus(
                                          application['application_id'],
                                          'rejected'),
                                      icon: FontAwesomeIcons.times,
                                    ),
                                    const SizedBox(width: 8),
                                    CustomButton(
                                      text: 'Approve',
                                      onPressed: () => _updateApplicationStatus(
                                          application['application_id'],
                                          'approved'),
                                      icon: FontAwesomeIcons.check,
                                    ),
                                  ],
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
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
