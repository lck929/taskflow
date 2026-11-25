import 'package:hive_ce_flutter/hive_ce_flutter.dart';

class HiveService {
  HiveService._();

  static const String taskBoxName = 'tasks';

  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isBoxOpen(taskBoxName)) {
      await Hive.openBox<Map>(taskBoxName);
    }
  }

  static Box<Map> get taskBox {
    if (!Hive.isBoxOpen(taskBoxName)) {
      throw StateError(
        'Hive task box is not initialized. '
        'Call HiveService.init() first.',
      );
    }

    return Hive.box<Map>(taskBoxName);
  }

  static Future<void> saveTask(
    String taskId,
    Map<String, dynamic> taskData,
  ) async {
    await taskBox.put(taskId, taskData);
  }

  static List<Map<String, dynamic>> getAllTasks() {
    return taskBox.values.map((data) {
      return Map<String, dynamic>.from(data);
    }).toList();
  }

  static Map<String, dynamic>? getTaskById(String taskId) {
    final data = taskBox.get(taskId);

    if (data == null) return null;

    return Map<String, dynamic>.from(data);
  }

  static Future<void> deleteTask(String taskId) async {
    await taskBox.delete(taskId);
  }

  static Future<void> clearTasks() async {
    await taskBox.clear();
  }

  static Future<void> close() async {
    if (Hive.isBoxOpen(taskBoxName)) {
      await taskBox.close();
    }
  }
}
