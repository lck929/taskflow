import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskflow/data/repositories/task_repo_impl.dart';
import 'package:taskflow/domain/models/task_priority.dart';
import '../../domain/repositories/task_repository.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return const TaskRepoImpl();
});

final taskProvider =
AsyncNotifierProvider<TaskNotifier, List<TaskModel>>(
  TaskNotifier.new,
);

class TaskNotifier extends AsyncNotifier<List<TaskModel>> {
  TaskRepository get _repository =>
      ref.read(taskRepositoryProvider);

  @override
  Future<List<TaskModel>> build() async {
    return _repository.getAllTasks();
  }

  Future<void> refreshTasks() async {
    await _executeAndReload(() async {});
  }

  Future<void> addTask(TaskModel task) async {
    await _executeAndReload(() {
      return _repository.addTask(task);
    });
  }

  Future<void> updateTask(TaskModel task) async {
    await _executeAndReload(() {
      return _repository.updateTask(task);
    });
  }

  Future<void> toggleTaskCompletion(
      String taskId,
      ) async {
    await _executeAndReload(() async {
      await _repository.toggleTaskCompletion(taskId);
    });
  }

  Future<void> deleteTask(String taskId) async {
    await _executeAndReload(() {
      return _repository.deleteTask(taskId);
    });
  }

  Future<void> _executeAndReload(
      Future<void> Function() operation,
      ) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await operation();
      return _repository.getAllTasks();
    });
    if (state case AsyncError(:final error, :final stackTrace)) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

enum TaskStatusFilter {
  all,
  active,
  completed,
}

enum TaskAssigneeFilter {
  all,
  aarav,
  priya,
  rohan,
}


class TaskFilters {
  final TaskAssigneeFilter assignee;
  final TaskStatusFilter status;

  const TaskFilters({
    this.assignee = TaskAssigneeFilter.all,
    this.status = TaskStatusFilter.all,
  });

  TaskFilters copyWith({
    TaskAssigneeFilter? assignee,
    TaskStatusFilter? status,
  }) {
    return TaskFilters(
      assignee: assignee ?? this.assignee,
      status: status ?? this.status,
    );
  }
}


final taskFilterProvider =
NotifierProvider<TaskFilterNotifier, TaskFilters>(
  TaskFilterNotifier.new,
);

class TaskFilterNotifier extends Notifier<TaskFilters> {
  @override
  TaskFilters build() {
    return const TaskFilters();
  }

  void setAssignee(TaskAssigneeFilter assignee) {
    state = state.copyWith(assignee: assignee);
  }

  void setStatus(TaskStatusFilter status) {
    state = state.copyWith(status: status);
  }

  void clearFilters() {
    state = const TaskFilters();
  }
}

final filteredTasksProvider =
Provider<AsyncValue<List<TaskModel>>>((ref) {
  final tasksAsync = ref.watch(taskProvider);
  final filters = ref.watch(taskFilterProvider);

  return tasksAsync.whenData((tasks) {
    return tasks.where((task) {
      final matchesAssignee = switch (filters.assignee) {
        TaskAssigneeFilter.all => true,
        TaskAssigneeFilter.aarav =>
        task.assignee == 'Aarav',
        TaskAssigneeFilter.priya =>
        task.assignee == 'Priya',
        TaskAssigneeFilter.rohan =>
        task.assignee == 'Rohan',
      };

      final matchesStatus = switch (filters.status) {
        TaskStatusFilter.all => true,
        TaskStatusFilter.active => !task.isCompleted,
        TaskStatusFilter.completed => task.isCompleted,
      };

      return matchesAssignee && matchesStatus;
    }).toList();
  });
});


final taskDetailProvider =
Provider.family<AsyncValue<TaskModel?>, String>(
      (ref, taskId) {
    final tasksAsync = ref.watch(taskProvider);

    return tasksAsync.whenData((tasks) {
      for (final task in tasks) {
        if (task.id == taskId) {
          return task;
        }
      }
      return null;
    });
  },
);
