part of 'tasks_bloc.dart';

enum TasksStatus { initial, loading, success, failure }

class TasksState extends Equatable {
  const TasksState({
    this.status = TasksStatus.initial,
    this.tasks = const [],
    this.activeFilterTab = 'all', // 'all', 'today', 'completed', 'overdue'
    this.selectedCategory,
    this.careRecipientId,
    this.isCreatingTask = false,
    this.createTaskSuccess = false,
    this.errorMessage,
  });

  final TasksStatus status;
  final List<TaskModel> tasks;
  final String activeFilterTab;
  final TaskCategory? selectedCategory;
  final String? careRecipientId;
  final bool isCreatingTask;
  final bool createTaskSuccess;
  final String? errorMessage;

  /// Computed list of filtered tasks according to tab and category
  List<TaskModel> get filteredTasks {
    return tasks.where((t) {
      // Category filter
      if (selectedCategory != null && t.category != selectedCategory) {
        return false;
      }

      // Tab filter
      final now = DateTime.now();
      switch (activeFilterTab) {
        case 'today':
          return t.scheduledTime.year == now.year &&
              t.scheduledTime.month == now.month &&
              t.scheduledTime.day == now.day;
        case 'completed':
          return t.isCompleted;
        case 'overdue':
          return t.isOverdue;
        case 'all':
        default:
          return true;
      }
    }).toList();
  }

  TasksState copyWith({
    TasksStatus? status,
    List<TaskModel>? tasks,
    String? activeFilterTab,
    TaskCategory? selectedCategory,
    String? careRecipientId,
    bool? isCreatingTask,
    bool? createTaskSuccess,
    String? errorMessage,
  }) {
    return TasksState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      activeFilterTab: activeFilterTab ?? this.activeFilterTab,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      careRecipientId: careRecipientId ?? this.careRecipientId,
      isCreatingTask: isCreatingTask ?? this.isCreatingTask,
      createTaskSuccess: createTaskSuccess ?? this.createTaskSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        tasks,
        activeFilterTab,
        selectedCategory,
        careRecipientId,
        isCreatingTask,
        createTaskSuccess,
        errorMessage,
      ];
}
