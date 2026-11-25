import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../providers/task_provider.dart';

class TaskFiltersWidget extends ConsumerWidget {
  const TaskFiltersWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filters = ref.watch(taskFilterProvider);

    final filterNotifier = ref.read(taskFilterProvider.notifier);

    final hasActiveFilters =
        filters.assignee != TaskAssigneeFilter.all ||
        filters.status != TaskStatusFilter.all;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune_rounded, size: 20, color: colorScheme.primary),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    'Filter Tasks',
                    style: theme.textTheme.titleMedium,
                  ),
                ),

                if (hasActiveFilters)
                  TextButton.icon(
                    onPressed: filterNotifier.clearFilters,
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: const Text('Clear'),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              'Assignee',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TaskAssigneeFilter.values.map((assignee) {
                final isSelected = filters.assignee == assignee;

                return ChoiceChip(
                  label: Text(_assigneeLabel(assignee)),
                  selected: isSelected,
                  showCheckmark: false,
                  avatar: isSelected
                      ? const Icon(Icons.check_rounded, size: 16)
                      : null,
                  onSelected: (_) {
                    filterNotifier.setAssignee(assignee);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            Text(
              'Status',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TaskStatusFilter.values.map((status) {
                final isSelected = filters.status == status;

                return ChoiceChip(
                  label: Text(_statusLabel(status)),
                  selected: isSelected,
                  showCheckmark: false,
                  avatar: isSelected
                      ? const Icon(Icons.check_rounded, size: 16)
                      : null,
                  onSelected: (_) {
                    filterNotifier.setStatus(status);
                  },
                );
              }).toList(),
            ),

            if (hasActiveFilters) ...[
              const SizedBox(height: 16),

              Divider(color: colorScheme.outlineVariant),

              const SizedBox(height: 8),

              Row(
                children: [
                  Icon(
                    Icons.filter_alt_outlined,
                    size: 16,
                    color: colorScheme.primary,
                  ),

                  const SizedBox(width: 6),

                  Expanded(
                    child: Text(
                      _filterSummary(filters),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _assigneeLabel(TaskAssigneeFilter value) {
    switch (value) {
      case TaskAssigneeFilter.all:
        return 'All';
      case TaskAssigneeFilter.aarav:
        return 'Aarav';
      case TaskAssigneeFilter.priya:
        return 'Priya';
      case TaskAssigneeFilter.rohan:
        return 'Rohan';
    }
  }

  String _statusLabel(TaskStatusFilter value) {
    switch (value) {
      case TaskStatusFilter.all:
        return 'All';
      case TaskStatusFilter.active:
        return 'Active';
      case TaskStatusFilter.completed:
        return 'Completed';
    }
  }

  String _filterSummary(TaskFilters filters) {
    final assignee = _assigneeLabel(filters.assignee);
    final status = _statusLabel(filters.status);

    if (filters.assignee == TaskAssigneeFilter.all) {
      return 'Showing $status tasks';
    }

    if (filters.status == TaskStatusFilter.all) {
      return 'Showing all tasks assigned to $assignee';
    }

    return 'Showing $status tasks assigned to $assignee';
  }
}
