import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DashboardLayout extends StatelessWidget {
  final Widget body;
  final String title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool isAdmin;

  const DashboardLayout({
    Key? key,
    required this.body,
    required this.title,
    this.actions,
    this.floatingActionButton,
    required this.isAdmin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: FaIcon(FontAwesomeIcons.userCircle, size: 30),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isAdmin ? 'Admin Dashboard' : 'Internee Dashboard',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            if (isAdmin) ...[
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.briefcase),
                title: const Text('Internships'),
                onTap: () => Navigator.pushReplacementNamed(context, '/admin/internships'),
              ),
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.tasks),
                title: const Text('Tasks'),
                onTap: () => Navigator.pushReplacementNamed(context, '/admin/tasks'),
              ),
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.users),
                title: const Text('Internees'),
                onTap: () => Navigator.pushReplacementNamed(context, '/admin/internees'),
              ),
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.fileAlt),
                title: const Text('Applications'),
                onTap: () => Navigator.pushReplacementNamed(context, '/admin/applications'),
              ),

               ListTile(
                leading: const FaIcon(FontAwesomeIcons.chartLine),
                title: const Text(' Internees Progress'),
                onTap: () => Navigator.pushReplacementNamed(context, '/admin/internee_progress'),
              ),

            ] else ...[
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.briefcase),
                title: const Text('Available Internships'),
                onTap: () => Navigator.pushReplacementNamed(context, '/internee/internships'),
              ),
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.tasks),
                title: const Text('My Tasks'),
                onTap: () => Navigator.pushReplacementNamed(context, '/internee/tasks'),
              ),
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.chartLine),
                title: const Text('My Progress'),
                onTap: () => Navigator.pushReplacementNamed(context, '/internee/progress'),
              ),
            ],
            const Divider(),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.signOutAlt),
              title: const Text('Logout'),
              onTap: () {
                // TODO: Implement logout
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
