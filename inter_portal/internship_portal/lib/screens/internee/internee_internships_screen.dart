import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:internship_portal/models/internship.dart';
import 'package:internship_portal/services/internship_service.dart';
import 'package:internship_portal/widgets/common_widgets.dart';
import 'package:internship_portal/widgets/dashboard_layout.dart';
import 'internee_application_form_screen.dart';

class InterneeInternshipsScreen extends StatefulWidget {
  const InterneeInternshipsScreen({Key? key}) : super(key: key);

  @override
  _InterneeInternshipsScreenState createState() =>
      _InterneeInternshipsScreenState();
}

class _InterneeInternshipsScreenState extends State<InterneeInternshipsScreen> {
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
    try {
      _internships = await _internshipService.getAvailableInternships();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load internships!'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Available Internships',
      isAdmin: false,
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: _internships.isEmpty
            ? const Center(
                child: Text('No available internships found'),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _internships.length,
                itemBuilder: (context, index) {
                  final internship = _internships[index];
                  return Card(
                    child: ExpansionTile(
                      leading: const FaIcon(FontAwesomeIcons.briefcase),
                      title: Text(internship.title),
                      subtitle: Text(
                        internship.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: StatusChip(
                        status: internship.status,
                        backgroundColor: Colors.green.withOpacity(0.1),
                        textColor: Colors.green,
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
                              Text(internship.description),
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.centerRight,
                                child: CustomButton(
                                  text: 'Apply',
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => InterneeApplicationFormScreen(internshipId: internship.internshipId),
                                      ),
                                    );
                                  },
                                  icon: FontAwesomeIcons.paperPlane,
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
    );
  }
}
