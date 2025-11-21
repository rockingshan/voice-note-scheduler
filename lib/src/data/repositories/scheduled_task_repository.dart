import '../../application/repositories/scheduled_task_repository.dart';
import '../../domain/entities/scheduled_task.dart';
import '../datasources/hive_scheduled_task_datasource.dart';

class ScheduledTaskRepositoryImpl implements ScheduledTaskRepository {
  final ScheduledTaskDatasource _datasource;

  ScheduledTaskRepositoryImpl(this._datasource);

  @override
  Future<List<ScheduledTask>> getTasks() async {
    return await _datasource.getAllTasks();
  }

  @override
  Future<ScheduledTask?> getTaskById(String id) async {
    return await _datasource.getTaskById(id);
  }

  @override
  Future<void> addTask(ScheduledTask task) async {
    await _datasource.createTask(task);
  }

  @override
  Future<void> updateTask(ScheduledTask task) async {
    await _datasource.updateTask(task);
  }

  @override
  Future<void> deleteTask(String id) async {
    await _datasource.deleteTask(id);
  }

  @override
  Future<List<ScheduledTask>> getTasksByStatus(TaskStatus status) async {
    final tasks = await _datasource.getAllTasks();
    return tasks.where((task) => task.status == status).toList();
  }

  @override
  Future<List<ScheduledTask>> getUpcomingTasks() async {
    final tasks = await _datasource.getAllTasks();
    final now = DateTime.now();
    return tasks
        .where((task) => 
            task.scheduledFor.isAfter(now) && 
            task.status != TaskStatus.completed && 
            task.status != TaskStatus.cancelled)
        .toList()
      ..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
  }

  @override
  Future<List<ScheduledTask>> getTasksForDateRange(DateTime start, DateTime end) async {
    final tasks = await _datasource.getAllTasks();
    return tasks
        .where((task) => 
            task.scheduledFor.isAfter(start) && 
            task.scheduledFor.isBefore(end))
        .toList()
      ..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
  }

  @override
  Stream<List<ScheduledTask>> watchTasks() {
    return _datasource.watchAllTasks();
  }

  @override
  Stream<ScheduledTask?> watchTaskById(String id) {
    return _datasource.watchTaskById(id);
  }
}