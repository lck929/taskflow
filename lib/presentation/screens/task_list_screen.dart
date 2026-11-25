import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taskflow/domain/models/task_priority.dart';
import 'package:taskflow/presentation/screens/add_task_screen.dart';
import 'package:taskflow/presentation/screens/task_detail_screen.dart';

import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/task_filters.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  Future<void> _refreshTasks() async {
    try {
      await ref.read(taskProvider.notifier).refreshTasks();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to refresh tasks: $error'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () {
              _refreshTasks();
            },
          ),
        ),
      );
    }
  }

  Future<void> _openTaskDetail(TaskModel task) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(taskId: task.id),
      ),
    );
  }

  Future<void> _openAddTask() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (context) => const AddTaskScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final tasksAsync = ref.watch(filteredTasksProvider);
    final filters = ref.watch(taskFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            tooltip: 'Refresh tasks',
            onPressed: _refreshTasks,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddTask,
        tooltip: 'Add new task',
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Task'),
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshTasks,
          child: tasksAsync.when(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,

            loading: () => _buildScrollableState(child: const _LoadingState()),

            error: (error, stackTrace) {
              return _buildScrollableState(
                child: _ErrorState(
                  message: error.toString(),
                  onRetry: _refreshTasks,
                ),
              );
            },
            data: (tasks) {
              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: tasks.isEmpty ? 3 : tasks.length + 2,

                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _buildHeader(context),
                    );
                  }

                  if (index == 1) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const TaskFiltersWidget(),

                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Your Tasks',
                                style: theme.textTheme.titleLarge,
                              ),
                            ),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${tasks.length} tasks',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                      ],
                    );
                  }

                  if (tasks.isEmpty) {
                    return _EmptyState(
                      hasFilters:
                          filters.assignee != TaskAssigneeFilter.all ||
                          filters.status != TaskStatusFilter.all,
                      onAddTask: _openAddTask,
                      onClearFilters: () {
                        ref.read(taskFilterProvider.notifier).clearFilters();
                      },
                    );
                  }
                  final task = tasks[index - 2];

                  return TaskCard(
                    key: ValueKey(task.id),
                    task: task,
                    onTap: () => _openTaskDetail(task),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableState({required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: constraints.maxHeight,
              child: Center(child: child),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stay Organized', style: theme.textTheme.headlineMedium),

              const SizedBox(height: 4),

              Text(
                'Manage your tasks and stay productive.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.task_alt_rounded,
            size: 28,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),

          const SizedBox(height: 20),

          Text(
            'Loading your tasks...',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 56, color: colorScheme.error),

          const SizedBox(height: 16),

          Text(
            'Something went wrong',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            message,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onAddTask;
  final VoidCallback onClearFilters;

  const _EmptyState({
    required this.hasFilters,
    required this.onAddTask,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasFilters
                  ? Icons.filter_alt_off_rounded
                  : Icons.assignment_outlined,
              color: colorScheme.onPrimaryContainer,
              size: 42,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            hasFilters ? 'No Matching Tasks' : 'No Tasks Yet',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            hasFilters
                ? 'No tasks match your selected filters. '
                      'Try adjusting or clearing them.'
                : 'Start organizing your work by '
                      'creating your first task.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          if (hasFilters)
            OutlinedButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Clear Filters'),
            )
          else
            FilledButton.icon(
              onPressed: onAddTask,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Task'),
            ),
        ],
      ),
    );
  }
}
