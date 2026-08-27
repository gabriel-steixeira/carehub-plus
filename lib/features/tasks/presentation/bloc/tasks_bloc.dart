import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../home/data/models/care_recipient_model.dart';
import '../../../home/data/models/caregiver_model.dart';
import '../../../home/data/repositories/home_repository.dart';
import '../../data/models/task_frequency.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/tasks_repository.dart';

part 'tasks_event.dart';
part 'tasks_state.dart';

class TasksBloc extends Bloc<TasksEvent, TasksState> {
  TasksBloc({
    required TasksRepository repository,
    HomeRepository? homeRepository,
  }) : _repository = repository,
       _homeRepository = homeRepository ?? HomeRepository(),
       super(TasksState(selectedDate: DateTime.now())) {
    on<TasksLoadEvent>(_onLoad);
    on<TasksFilterChangedEvent>(_onFilterChanged);
    on<TasksCategoryFilterChangedEvent>(_onCategoryFilterChanged);
    on<TasksProfileChangedEvent>(_onProfileChanged);
    on<TasksSearchQueryChangedEvent>(_onSearchQueryChanged);
    on<TasksDateChangedEvent>(_onDateChanged);
    on<TasksSortChangedEvent>(_onSortChanged);
    on<TaskCreateEvent>(_onCreateTask);
    on<TaskToggleCompletionEvent>(_onToggleCompletion);
    on<TaskDeleteEvent>(_onDeleteTask);
  }

  final TasksRepository _repository;
  final HomeRepository _homeRepository;

  Future<void> _onLoad(TasksLoadEvent event, Emitter<TasksState> emit) async {
    emit(state.copyWith(status: TasksStatus.loading));
    try {
      final caregiver = await _homeRepository.fetchCaregiver();
      final profiles = await _homeRepository.fetchCareRecipients();
      final tasks = await _repository.fetchTasks();

      emit(
        state.copyWith(
          status: TasksStatus.success,
          caregiver: caregiver,
          profiles: profiles,
          tasks: tasks,
          careRecipientId: event.careRecipientId,
          // Single-profile only: default to the first profile when none was
          // provided through navigation (there is no longer an "all" option).
          selectedProfileId:
              event.careRecipientId ??
              (profiles.isNotEmpty ? profiles.first.id : ''),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: TasksStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  void _onFilterChanged(
    TasksFilterChangedEvent event,
    Emitter<TasksState> emit,
  ) {
    emit(state.copyWith(activeFilterTab: event.filterTab));
  }

  void _onCategoryFilterChanged(
    TasksCategoryFilterChangedEvent event,
    Emitter<TasksState> emit,
  ) {
    emit(
      state.copyWith(
        selectedCategoryId: event.categoryId,
        clearSelectedCategory: event.categoryId == null,
      ),
    );
  }

  void _onProfileChanged(
    TasksProfileChangedEvent event,
    Emitter<TasksState> emit,
  ) {
    emit(state.copyWith(selectedProfileId: event.profileId));
  }

  void _onSearchQueryChanged(
    TasksSearchQueryChangedEvent event,
    Emitter<TasksState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onDateChanged(TasksDateChangedEvent event, Emitter<TasksState> emit) {
    emit(state.copyWith(selectedDate: event.selectedDate));
  }

  void _onSortChanged(TasksSortChangedEvent event, Emitter<TasksState> emit) {
    emit(state.copyWith(sortOption: event.sortOption));
  }

  Future<void> _onCreateTask(
    TaskCreateEvent event,
    Emitter<TasksState> emit,
  ) async {
    emit(state.copyWith(isCreatingTask: true, createTaskSuccess: false));
    try {
      final newTask = TaskModel(
        id: 'task_${DateTime.now().millisecondsSinceEpoch}',
        careRecipientId: event.careRecipientId,
        title: event.title,
        description: event.description,
        scheduledTime: event.scheduledTime,
        categoryId: event.categoryId,
        frequency: event.frequency,
        assignedToName: event.assignedToName,
        assignedToMemberId: event.assignedToMemberId,
        assignedToPhotoUrl: event.assignedToPhotoUrl,
      );

      final created = await _repository.addTask(newTask);
      final updatedList = List<TaskModel>.from(state.tasks)..insert(0, created);

      emit(
        state.copyWith(
          tasks: updatedList,
          isCreatingTask: false,
          createTaskSuccess: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isCreatingTask: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onToggleCompletion(
    TaskToggleCompletionEvent event,
    Emitter<TasksState> emit,
  ) async {
    try {
      final updated = await _repository.toggleTaskCompletion(
        event.taskId,
        note: event.note,
      );
      final updatedList = state.tasks.map((t) {
        return t.id == updated.id ? updated : t;
      }).toList();

      emit(state.copyWith(tasks: updatedList));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onDeleteTask(
    TaskDeleteEvent event,
    Emitter<TasksState> emit,
  ) async {
    try {
      await _repository.deleteTask(event.taskId);
      final updatedList = state.tasks
          .where((t) => t.id != event.taskId)
          .toList();
      emit(state.copyWith(tasks: updatedList));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }
}
