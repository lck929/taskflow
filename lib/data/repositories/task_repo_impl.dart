import 'package:taskflow/core/db/hive_service.dart';
import 'package:taskflow/domain/models/task_priority.dart';
import 'package:taskflow/domain/repositories/task_repository.dart';

class TaskRepoImpl implements TaskRepository{
  const TaskRepoImpl();
  @override
  Future<void> addTask(TaskModel task) async {
    final title = task.title.trim();
    if (title.isEmpty) {
      throw ArgumentError('Task title cannot be empty');
    }
    if (task.id.trim().isEmpty) {
      throw ArgumentError('Task ID cannot be empty');
    }
    final existingTask = await getTaskById(task.id);
    if (existingTask != null) {
      throw StateError(
        'A task with ID ${task.id} already exists',
      );
    }
    try {
      await HiveService.saveTask(
        task.id,
        task.toJson(),
      );
    } catch (e) {
      throw Exception('Failed to add task: $e');
    }  }

  @override
  Future<void> deleteTask(String taskId) async {
    final existingTask = await getTaskById(taskId);
    if (existingTask == null) {
      throw StateError(
        'Task with ID $taskId not found',
      );
    }
    try {
      await HiveService.deleteTask(taskId);
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  @override
  Future<List<TaskModel>> getAllTasks() async {
    try {
      final storedTasks = HiveService.getAllTasks();
      final tasks = storedTasks
          .map((json) => TaskModel.fromJson(json))
          .toList();
      tasks.sort(
            (a, b) => b.createdAt.compareTo(a.createdAt),
      );
      return tasks;
    } catch (e) {
      throw Exception('Failed to load tasks: $e');
    }
  }

  @override
  Future<TaskModel?> getTaskById(String taskId) async {
    try {
      final taskData = HiveService.getTaskById(taskId);
      if (taskData == null) {
        return null;
      }
      return TaskModel.fromJson(taskData);
    } catch (e) {
      throw Exception('Failed to retrieve task: $e');
    }
  }

  @override
  Future<TaskModel> toggleTaskCompletion(String taskId) async {
    final existingTask = await getTaskById(taskId);
    if (existingTask == null) {
      throw StateError(
        'Task with ID $taskId not found',
      );
    }
    final updatedTask = existingTask.copyWith(
      isCompleted: !existingTask.isCompleted,
    );
    await updateTask(updatedTask);
    return updatedTask;
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    if (task.title.trim().isEmpty) {
      throw ArgumentError('Task title cannot be empty');
    }
    final existingTask = await getTaskById(task.id);
    if (existingTask == null) {
      throw StateError(
        'Task with ID ${task.id} not found',
      );
    }
    try {
      await HiveService.saveTask(
        task.id,
        task.toJson(),
      );
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }
}