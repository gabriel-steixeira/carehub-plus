part of 'tasks_bloc.dart';

enum TasksStatus { initial, loading, success, failure }

class TasksState extends Equatable {
  const TasksState({
    this.status = TasksStatus.initial,
    this.tasks = const [],
    this.caregiver,
    this.profiles = const [],
    this.activeFilterTab = 'all', // 'all', 'today', 'completed', 'overdue'
    this.selectedProfileId = 'all',
    this.selectedCategoryId,
    this.careRecipientId,
    this.searchQuery = '',
    this.selectedDate,
    this.sortOption = 'time',
    this.isCreatingTask = false,
    this.createTaskSuccess = false,
    this.errorMessage,
  });

  final TasksStatus status;
  final List<TaskModel> tasks;
  final CaregiverModel? caregiver;
  final List<CareRecipientModel> profiles;
  final String activeFilterTab;
  final String selectedProfileId;
  final String? selectedCategoryId;
  final String? careRecipientId;
  final String searchQuery;
  final DateTime? selectedDate;
  final String sortOption;
  final bool isCreatingTask;
  final bool createTaskSuccess;
  final String? errorMessage;

  int get pendingCount => filteredTasks.where((t) => !t.isCompleted).length;
  int get completedCount => filteredTasks.where((t) => t.isCompleted).length;

  /// Computed list of filtered tasks according to profile, search, date, category and tab
  List<TaskModel> get filteredTasks {
    final list = tasks.where((t) {
      // Profile filter
      if (selectedProfileId != 'all' && selectedProfileId.isNotEmpty) {
        if (t.careRecipientId != selectedProfileId) {
          return false;
        }
      }

      // Search query
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchTitle = t.title.toLowerCase().contains(query);
        final matchDesc = t.description.toLowerCase().contains(query);
        final matchResp =
            t.assignedToName?.toLowerCase().contains(query) ?? false;
        if (!matchTitle && !matchDesc && !matchResp) {
          return false;
        }
      }

      // Category filter
      if (selectedCategoryId != null && t.categoryId != selectedCategoryId) {
        return false;
      }

      // Date filter
      if (selectedDate != null) {
        final d = selectedDate!;
        final st = t.scheduledTime;
        if (st.year != d.year || st.month != d.month || st.day != d.day) {
          return false;
        }
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

    // Sorting
    list.sort((a, b) {
      if (sortOption == 'category') {
        // Ordena pelo id da categoria — o rótulo exibido (`CareCategoryEntity`)
        // pertence à apresentação, e o BLoC nunca deve depender dela.
        return a.categoryId.compareTo(b.categoryId);
      } else if (sortOption == 'status') {
        return (a.isCompleted ? 1 : 0).compareTo(b.isCompleted ? 1 : 0);
      }
      return a.scheduledTime.compareTo(b.scheduledTime);
    });

    return list;
  }

  TasksState copyWith({
    TasksStatus? status,
    List<TaskModel>? tasks,
    CaregiverModel? caregiver,
    List<CareRecipientModel>? profiles,
    String? activeFilterTab,
    String? selectedProfileId,
    String? selectedCategoryId,
    bool clearSelectedCategory = false,
    String? careRecipientId,
    String? searchQuery,
    DateTime? selectedDate,
    String? sortOption,
    bool? isCreatingTask,
    bool? createTaskSuccess,
    String? errorMessage,
  }) {
    return TasksState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      caregiver: caregiver ?? this.caregiver,
      profiles: profiles ?? this.profiles,
      activeFilterTab: activeFilterTab ?? this.activeFilterTab,
      selectedProfileId: selectedProfileId ?? this.selectedProfileId,
      selectedCategoryId: clearSelectedCategory
          ? null
          : selectedCategoryId ?? this.selectedCategoryId,
      careRecipientId: careRecipientId ?? this.careRecipientId,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedDate: selectedDate ?? this.selectedDate,
      sortOption: sortOption ?? this.sortOption,
      isCreatingTask: isCreatingTask ?? this.isCreatingTask,
      createTaskSuccess: createTaskSuccess ?? this.createTaskSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        tasks,
        caregiver,
        profiles,
        activeFilterTab,
        selectedProfileId,
        selectedCategoryId,
        careRecipientId,
        searchQuery,
        selectedDate,
        sortOption,
        isCreatingTask,
        createTaskSuccess,
        errorMessage,
      ];
}
