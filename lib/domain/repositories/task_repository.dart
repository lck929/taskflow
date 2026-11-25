import 'package:taskflow/domain/models/task_priority.dart';

abstract class TaskRepository {
  Future<List<TaskModel>> getAllTasks();
  Future<TaskModel?> getTaskById(String taskId);
  Future<void> addTask(TaskModel task);
  Future<void> updateTask(TaskModel task);
  Future<TaskModel> toggleTaskCompletion(String taskId);
  Future<void> deleteTask(String taskId);
}
