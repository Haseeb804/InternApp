import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:internship_portal/models/task.dart';
import 'package:internship_portal/widgets/common_widgets.dart';
import 'package:intl/intl.dart';

class TaskFormDialog extends StatefulWidget {
  final Task? task;
  final int internshipId;

  const TaskFormDialog({
    Key? key,
    this.task,
    required this.internshipId,
  }) : super(key: key);

  @override
  _TaskFormDialogState createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _dueDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _dueDate = widget.task!.dueDate;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
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
                widget.task == null ? 'Add Task' : 'Edit Task',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              CustomTextFormField(
                label: 'Title',
                controller: _titleController,
                prefixIcon: FontAwesomeIcons.tasks,
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
                      const Text('Due Date:'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _dueDate == null
                                  ? 'No due date set'
                                  : DateFormat('MMM dd, yyyy').format(_dueDate!),
                            ),
                          ),
                          IconButton(
                            icon: const FaIcon(FontAwesomeIcons.calendar),
                            onPressed: () => _selectDate(context),
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
                    text: widget.task == null ? 'Create' : 'Update',
                    onPressed: _isLoading
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              Navigator.pop(
                                context,
                                {
                                  'title': _titleController.text,
                                  'description': _descriptionController.text,
                                  'internship_id': widget.internshipId,
                                  'due_date': _dueDate?.toIso8601String(),
                                },
                              );
                            }
                          },
                    isLoading: _isLoading,
                    icon: widget.task == null
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
