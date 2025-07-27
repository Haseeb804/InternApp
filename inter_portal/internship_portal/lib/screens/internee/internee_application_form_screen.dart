import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:internship_portal/services/internship_service.dart';
import 'package:internship_portal/widgets/common_widgets.dart';
import 'package:internship_portal/widgets/dashboard_layout.dart';

class InterneeApplicationFormScreen extends StatefulWidget {
  final int internshipId;

  const InterneeApplicationFormScreen({Key? key, required this.internshipId}) : super(key: key);

  @override
  _InterneeApplicationFormScreenState createState() => _InterneeApplicationFormScreenState();
}

class _InterneeApplicationFormScreenState extends State<InterneeApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _universityController = TextEditingController();
  final _degreeController = TextEditingController();
  final _semesterController = TextEditingController();
  dynamic _resumeFile; // dynamic to support web and mobile
  bool _isLoading = false;

  Future<void> _pickResume() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      if (kIsWeb) {
        setState(() {
          _resumeFile = result.files.single.bytes != null ? html.File(result.files.single.bytes!, result.files.single.name) : null;
        });
      } else {
        if (result.files.single.path != null) {
          setState(() {
            _resumeFile = File(result.files.single.path!);
          });
        }
      }
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_resumeFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF resume')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await InternshipService().submitInternshipApplication(
        internshipId: widget.internshipId,
        name: _nameController.text.trim(),
        universityName: _universityController.text.trim(),
        degree: _degreeController.text.trim(),
        semester: _semesterController.text.trim(),
        resumeFile: _resumeFile,
      );

      if (result == "success" && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted successfully')),
        );
        Navigator.of(context).pop();
      } else if (result == "already_applied" && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have already applied for this internship.'), backgroundColor: Colors.orange),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit application'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: \$e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _universityController.dispose();
    _degreeController.dispose();
    _semesterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Internship Application',
      isAdmin: false,
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _universityController,
                  decoration: const InputDecoration(labelText: 'University Name'),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter your university name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _degreeController,
                  decoration: const InputDecoration(labelText: 'Degree'),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter your degree' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _semesterController,
                  decoration: const InputDecoration(labelText: 'Semester'),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter your semester' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickResume,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Resume (PDF)'),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _resumeFile != null
                            ? (kIsWeb ? _resumeFile.name : _resumeFile.path.split('/').last)
                            : 'No file selected',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _submitApplication,
                    child: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
