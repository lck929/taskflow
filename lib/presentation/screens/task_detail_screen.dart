import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskflow/domain/models/task_priority.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/task_provider.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  bool _isUpdating = false;
  String? _actionError;

  Future<void> _toggleCompletion() async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
      _actionError = null;
    });

    try {
      await ref.read(taskProvider.notifier).toggleTaskCompletion(widget.taskId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task status updated successfully')),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _actionError = _friendlyError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _refreshTask() async {
    try {
      await ref.read(taskProvider.notifier).refreshTasks();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to refresh task: $error')));
    }
  }

  String _friendlyError(Object error) {
    if (error is StateError) {
      return error.message;
    }

    if (error is ArgumentError) {
      return error.message?.toString() ?? 'Invalid task operation';
    }

    return 'Unable to update the task. Please try again.';
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'No due date';
    }

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

    return '${months[date.month - 1]} '
        '${date.day}, ${date.year}';
  }

  String _priorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskAsync = ref.watch(taskDetailProvider(widget.taskId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            tooltip: 'Refresh task',
            onPressed: _isUpdating ? null : _refreshTask,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: SafeArea(
        child: taskAsync.when(
          skipLoadingOnRefresh: false,
          skipLoadingOnReload: false,

          loading: () => const Center(child: CircularProgressIndicator()),

          error: (error, stackTrace) {
            return _buildErrorState(context, message: error.toString());
          },

          data: (task) {
            if (task == null) {
              return _buildNotFoundState(context);
            }

            return _buildTaskContent(context, task);
          },
        ),
      ),
    );
  }

  Widget _buildTaskContent(BuildContext context, TaskModel task) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final priorityColor = AppTheme.getPriorityColor(task.priority.name);

    final isOverdue = task.isOverdue;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),

                const SizedBox(height: 10),

                SelectableText(
                  'Task ID: ${task.id}',
                  style: theme.textTheme.bodySmall,
                ),

                const SizedBox(height: 20),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _DetailBadge(
                      label: _priorityLabel(task.priority),
                      icon: Icons.flag_outlined,
                      color: priorityColor,
                    ),

                    _DetailBadge(
                      label: task.isCompleted ? 'Completed' : 'Active',
                      icon: task.isCompleted
                          ? Icons.check_circle_outline
                          : Icons.radio_button_unchecked,
                      color: task.isCompleted
                          ? AppTheme.completedColor
                          : colorScheme.primary,
                    ),

                    if (isOverdue)
                      const _DetailBadge(
                        label: 'Overdue',
                        icon: Icons.warning_amber_rounded,
                        color: AppTheme.overdueColor,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Description', style: theme.textTheme.titleMedium),

                const SizedBox(height: 12),

                Text(
                  task.description.trim().isEmpty
                      ? 'No description provided.'
                      : task.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: task.description.trim().isEmpty
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Task Information', style: theme.textTheme.titleMedium),

                const SizedBox(height: 20),

                _DetailRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Assigned To',
                  value: task.assignee,
                ),

                const Divider(height: 28),

                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Due Date',
                  value: _formatDate(task.dueDate),
                  valueColor: isOverdue ? colorScheme.error : null,
                ),

                const Divider(height: 28),

                _DetailRow(
                  icon: Icons.flag_outlined,
                  label: 'Priority',
                  value: _priorityLabel(task.priority),
                  valueColor: priorityColor,
                ),

                const Divider(height: 28),

                _DetailRow(
                  icon: Icons.check_circle_outline,
                  label: 'Status',
                  value: task.isCompleted ? 'Completed' : 'Active',
                  valueColor: task.isCompleted ? AppTheme.completedColor : null,
                ),

                const Divider(height: 28),

                _DetailRow(
                  icon: Icons.access_time_rounded,
                  label: 'Created On',
                  value: _formatDate(task.createdAt),
                ),
              ],
            ),
          ),
        ),
        if (_actionError != null) ...[
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: colorScheme.onErrorContainer,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    _actionError!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: _isUpdating ? null : _toggleCompletion,

            icon: _isUpdating
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : Icon(
                    task.isCompleted
                        ? Icons.restart_alt_rounded
                        : Icons.check_circle_outline_rounded,
                  ),

            label: Text(
              _isUpdating
                  ? 'Updating Task...'
                  : task.isCompleted
                  ? 'Mark as Active'
                  : 'Mark as Complete',
            ),
          ),
        ),

        const SizedBox(height: 12),

        OutlinedButton(
          onPressed: _isUpdating ? null : () => Navigator.of(context).pop(),
          child: const Text('Back to Tasks'),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, {required String message}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: colorScheme.error,
            ),

            const SizedBox(height: 16),

            Text('Unable to Load Task', style: theme.textTheme.titleLarge),

            const SizedBox(height: 10),

            Text(
              message,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _refreshTask,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 56),

            const SizedBox(height: 16),

            Text('Task Not Found', style: theme.textTheme.titleLarge),

            const SizedBox(height: 8),

            const Text(
              'This task may have been deleted.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Back to Tasks'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall),

              const SizedBox(height: 5),

              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _DetailBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),

          const SizedBox(width: 6),

          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
