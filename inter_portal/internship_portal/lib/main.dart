import 'package:flutter/material.dart';
import 'screens/auth/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:internship_portal/providers/user_provider.dart';
import 'package:internship_portal/screens/auth/login_screen.dart';
import 'package:internship_portal/screens/auth/register_screen.dart';
import 'package:internship_portal/screens/admin/admin_internships_screen.dart';
import 'package:internship_portal/screens/admin/admin_tasks_screen.dart';
import 'package:internship_portal/screens/admin/admin_internees_screen.dart';
import 'package:internship_portal/screens/admin/admin_applications_screen.dart';
import 'package:internship_portal/screens/admin/admin_internee_progress_screen.dart';
import 'package:internship_portal/screens/internee/internee_internships_screen.dart';
import 'package:internship_portal/screens/internee/internee_tasks_screen.dart';
import 'package:internship_portal/screens/internee/internee_progress_screen.dart';
import 'package:internship_portal/theme/app_theme.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:internship_portal/providers/user_provider.dart';
import 'package:internship_portal/screens/auth/login_screen.dart';
import 'package:internship_portal/screens/auth/register_screen.dart';
import 'package:internship_portal/screens/admin/admin_internships_screen.dart';
import 'package:internship_portal/screens/admin/admin_tasks_screen.dart';
import 'package:internship_portal/screens/admin/admin_internees_screen.dart';
import 'package:internship_portal/screens/admin/admin_applications_screen.dart';
import 'package:internship_portal/screens/admin/admin_internee_progress_screen.dart';
import 'package:internship_portal/screens/internee/internee_internships_screen.dart';
import 'package:internship_portal/screens/internee/internee_tasks_screen.dart';
import 'package:internship_portal/screens/internee/internee_progress_screen.dart';
import 'package:internship_portal/theme/app_theme.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:internship_portal/providers/user_provider.dart';
import 'package:internship_portal/screens/auth/login_screen.dart';
import 'package:internship_portal/screens/auth/register_screen.dart';
import 'package:internship_portal/screens/admin/admin_internships_screen.dart';
import 'package:internship_portal/screens/admin/admin_tasks_screen.dart';
import 'package:internship_portal/screens/admin/admin_internees_screen.dart';
import 'package:internship_portal/screens/admin/admin_applications_screen.dart';
import 'package:internship_portal/screens/admin/admin_internee_progress_screen.dart';
import 'package:internship_portal/screens/internee/internee_internships_screen.dart';
import 'package:internship_portal/screens/internee/internee_tasks_screen.dart';
import 'package:internship_portal/screens/internee/internee_progress_screen.dart';
import 'package:internship_portal/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDjiVGfDxp8_RUaNce4soR_0rawZtM1miM",
      authDomain: "rentelease-77e8b.firebaseapp.com",
      projectId: "rentelease-77e8b",
      storageBucket: "rentelease-77e8b.appspot.com",
      messagingSenderId: "502330410824",
      appId: "1:502330410824:web:0c51cde314cb0b229b557d",
      measurementId: "G-0TVQ3V6QCH",
    ),
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: const InternshipPortalApp(),
    ),
  );
}

class InternshipPortalApp extends StatelessWidget {
  const InternshipPortalApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Internship Portal',
      theme: AppTheme.lightTheme,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        
        // Admin routes
        '/admin/internships': (context) => const AdminInternshipsScreen(),
        '/admin/tasks': (context) => const AdminTasksScreen(),
        '/admin/internees': (context) => const AdminInterneesScreen(),
        '/admin/applications': (context) => const AdminApplicationsScreen(),
        '/admin/internee_progress': (context) => const AdminInterneeProgressScreen(),
        
        // Internee routes
        '/internee/internships': (context) => const InterneeInternshipsScreen(),
        '/internee/tasks': (context) => const InterneeTasksScreen(),
        '/internee/progress': (context) => const InterneeProgressScreen(),
      },
    );
  }
}
