import '../entities/scheduled_task.dart';

abstract class ScheduledTaskRepository {
  Future<List<ScheduledTask>> getTasks();
  Future<ScheduledTask?> getTaskById(String id);
  Future<void> addTask(ScheduledTask task);
  Future<void> updateTask(ScheduledTask task);
  Future<void> deleteTask(String id);
  Future<List<ScheduledTask>> getTasksByStatus(TaskStatus status);
  Future<List<ScheduledTask>> getUpcomingTasks();
  Future<List<ScheduledTask>> getTasksForDateRange(DateTime start, DateTime end);
  Stream<List<ScheduledTask>> watchTasks();
  Stream<ScheduledTask?> watchTaskById(String id);
}