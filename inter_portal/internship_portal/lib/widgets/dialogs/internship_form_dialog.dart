import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:internship_portal/models/internship.dart';
import 'package:internship_portal/widgets/common_widgets.dart';

class InternshipFormDialog extends StatefulWidget {
  final Internship? internship;

  const InternshipFormDialog({
    Key? key,
    this.internship,
  }) : super(key: key);

  @override
  _InternshipFormDialogState createState() => _InternshipFormDialogState();
}

class _InternshipFormDialogState extends State<InternshipFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _status = 'available';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.internship != null) {
      _titleController.text = widget.internship!.title;
      _descriptionController.text = widget.internship!.description;
      _status = widget.internship!.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.internship == null ? 'Add Internship' : 'Edit Internship',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              CustomTextFormField(
                label: 'Title',
                controller: _titleController,
                prefixIcon: FontAwesomeIcons.briefcase,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              CustomTextFormField(
                label: 'Description',
                controller: _descriptionController,
                prefixIcon: FontAwesomeIcons.alignLeft,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Status:'),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Available'),
                              value: 'available',
                              groupValue: _status,
                              onChanged: (value) {
                                setState(() => _status = value!);
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Not Available'),
                              value: 'not available',
                              groupValue: _status,
                              onChanged: (value) {
                                setState(() => _status = value!);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  CustomButton(
                    text: widget.internship == null ? 'Create' : 'Update',
                    onPressed: _isLoading
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              Navigator.pop(
                                context,
                                {
                                  'title': _titleController.text,
                                  'description': _descriptionController.text,
                                  'status': _status,
                                },
                              );
                            }
                          },
                    isLoading: _isLoading,
                    icon: widget.internship == null
                        ? FontAwesomeIcons.plus
                        : FontAwesomeIcons.save,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
