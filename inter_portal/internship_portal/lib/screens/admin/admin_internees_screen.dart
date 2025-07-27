import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:internship_portal/models/user.dart';
import 'package:internship_portal/services/user_service.dart';
import 'package:internship_portal/widgets/common_widgets.dart';
import 'package:internship_portal/widgets/dashboard_layout.dart';

class AdminInterneesScreen extends StatefulWidget {
  const AdminInterneesScreen({Key? key}) : super(key: key);

  @override
  _AdminInterneesScreenState createState() => _AdminInterneesScreenState();
}

class _AdminInterneesScreenState extends State<AdminInterneesScreen> {
  final _userService = UserService();
  bool _isLoading = true;
  List<User> _internees = [];

  @override
  void initState() {
    super.initState();
    _loadInternees();
  }

  Future<void> _loadInternees() async {
    setState(() => _isLoading = true);
    _internees = await _userService.getAllInternees();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Internees',
      isAdmin: true,
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: _internees.isEmpty
            ? const Center(
                child: Text('No internees found'),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _internees.length,
                itemBuilder: (context, index) {
                  final internee = _internees[index];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: FaIcon(FontAwesomeIcons.userGraduate),
                      ),
                      title: Text(internee.username),
                      subtitle: Text(internee.email),
                      trailing: IconButton(
                        icon: const FaIcon(FontAwesomeIcons.chartBar),
                        onPressed: () {
                          // TODO: Navigate to internee progress screen
                        },
                      ),
                      onTap: () {
                        // TODO: Show internee details dialog
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
