import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/scheduled_task.dart';
import '../../core/constants/app_constants.dart';

abstract class ScheduledTaskDatasource {
  Future<List<ScheduledTask>> getAllTasks();
  Future<ScheduledTask?> getTaskById(String id);
  Future<void> createTask(ScheduledTask task);
  Future<void> updateTask(ScheduledTask task);
  Future<void> deleteTask(String id);
  Stream<List<ScheduledTask>> watchAllTasks();
  Stream<ScheduledTask?> watchTaskById(String id);
}

class HiveScheduledTaskDatasource implements ScheduledTaskDatasource {
  late final Box<ScheduledTask> _tasksBox;

  HiveScheduledTaskDatasource() {
    _initializeBox();
  }

  void _initializeBox() {
    _tasksBox = Hive.box<ScheduledTask>('tasks_box');
  }

  @override
  Future<List<ScheduledTask>> getAllTasks() async {
    return _tasksBox.values.toList();
  }

  @override
  Future<ScheduledTask?> getTaskById(String id) async {
    return _tasksBox.get(id);
  }

  @override
  Future<void> createTask(ScheduledTask task) async {
    await _tasksBox.put(task.id, task);
  }

  @override
  Future<void> updateTask(ScheduledTask task) async {
    await _tasksBox.put(task.id, task);
  }

  @override
  Future<void> deleteTask(String id) async {
    await _tasksBox.delete(id);
  }

  @override
  Stream<List<ScheduledTask>> watchAllTasks() {
    return _tasksBox.watch().map((event) => _tasksBox.values.toList());
  }

  @override
  Stream<ScheduledTask?> watchTaskById(String id) {
    return _tasksBox.watch().map((event) => _tasksBox.get(id));
  }
}