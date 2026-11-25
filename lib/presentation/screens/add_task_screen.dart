import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taskflow/domain/models/task_priority.dart';

import '../providers/task_provider.dart';
import '../widgets/priority_selector.dart';

class AddTaskScreen extends ConsumerStatefulWidget {
  const AddTaskScreen({super.key});

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _selectedDueDate;

  TaskPriority? _selectedPriority = TaskPriority.medium;

  String? _selectedAssignee = 'Aarav';

  bool _isSubmitting = false;

  String? _submissionError;

  static const List<String> _assignees = ['Aarav', 'Priya', 'Rohan'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final now = DateTime.now();

    final initialDate = _selectedDueDate ?? now;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select Task Due Date',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );

    if (selectedDate != null && mounted) {
      setState(() {
        _selectedDueDate = selectedDate;
      });
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  String _generateTaskId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;

    final uniquePart = UniqueKey().toString().replaceAll(
      RegExp(r'[^a-zA-Z0-9]'),
      '',
    );

    return 'task_${timestamp}_$uniquePart';
  }

  Future<void> _createTask() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedPriority == null) {
      setState(() {
        _submissionError = 'Please select a priority';
      });
      return;
    }
    if (_selectedAssignee == null) {
      setState(() {
        _submissionError = 'Please select an assignee';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });

    try {
      final task = TaskModel(
        id: _generateTaskId(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dueDate: _selectedDueDate,
        priority: _selectedPriority!,
        assignee: _selectedAssignee!,
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      await ref.read(taskProvider.notifier).addTask(task);

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _submissionError = _friendlyError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _friendlyError(Object error) {
    if (error is ArgumentError) {
      return error.message?.toString() ?? 'Invalid task information.';
    }

    if (error is StateError) {
      return error.message;
    }

    return 'Unable to save the task. '
        'Please try again. Details: $error';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Task')),

      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Text('Create New Task', style: theme.textTheme.headlineMedium),

              const SizedBox(height: 6),

              Text(
                'Fill in the details to create a task.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 24),

              TextFormField(
                controller: _titleController,
                enabled: !_isSubmitting,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Task Title *',
                  hintText: 'Enter task title',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (value) {
                  final title = value?.trim() ?? '';

                  if (title.isEmpty) {
                    return 'Please enter a task title';
                  }

                  if (title.length < 3) {
                    return 'Title must contain at least 3 characters';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                enabled: !_isSubmitting,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                minLines: 3,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter task description',
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Due Date (Optional)',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              InkWell(
                onTap: _isSubmitting ? null : _selectDueDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    suffixIcon: _selectedDueDate != null
                        ? IconButton(
                            tooltip: 'Clear due date',
                            onPressed: _isSubmitting
                                ? null
                                : () {
                                    setState(() {
                                      _selectedDueDate = null;
                                    });
                                  },
                            icon: const Icon(Icons.close_rounded),
                          )
                        : const Icon(Icons.arrow_drop_down_rounded),
                  ),
                  child: Text(
                    _selectedDueDate == null
                        ? 'Select due date'
                        : _formatDate(_selectedDueDate!),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _selectedDueDate == null
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              PrioritySelector(
                initialValue: _selectedPriority,
                enabled: !_isSubmitting,
                isRequired: true,
                onChanged: (priority) {
                  setState(() {
                    _selectedPriority = priority;
                    _submissionError = null;
                  });
                },
              ),

              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _selectedAssignee,
                decoration: const InputDecoration(
                  labelText: 'Assign To *',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                items: _assignees.map((assignee) {
                  return DropdownMenuItem<String>(
                    value: assignee,
                    child: Text(assignee),
                  );
                }).toList(),
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        setState(() {
                          _selectedAssignee = value;
                          _submissionError = null;
                        });
                      },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an assignee';
                  }

                  return null;
                },
              ),
              if (_submissionError != null) ...[
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: colorScheme.onErrorContainer,
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          _submissionError!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _createTask,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    _isSubmitting ? 'Creating Task...' : 'Create Task',
                  ),
                ),
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
