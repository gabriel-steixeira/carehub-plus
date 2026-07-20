import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/task_category.dart';
import '../../data/models/task_frequency.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/tasks_repository.dart';

part 'tasks_event.dart';
part 'tasks_state.dart';

class TasksBloc extends Bloc<TasksEvent, TasksState> {
  TasksBloc({required TasksRepository repository})
      : _repository = repository,
        super(const TasksState()) {
    on<TasksLoadEvent>(_onLoad);
    on<TasksFilterChangedEvent>(_onFilterChanged);
    on<TasksCategoryFilterChangedEvent>(_onCategoryFilterChanged);
    on<TaskCreateEvent>(_onCreateTask);
    on<TaskToggleCompletionEvent>(_onToggleCompletion);
    on<TaskDeleteEvent>(_onDeleteTask);
  }

  final TasksRepository _repository;

  Future<void> _onLoad(
    TasksLoadEvent event,
    Emitter<TasksState> emit,
  ) async {
    emit(state.copyWith(status: TasksStatus.loading));
    try {
      final tasks = await _repository.fetchTasks(
        careRecipientId: event.careRecipientId,
      );
      emit(state.copyWith(
        status: TasksStatus.success,
        tasks: tasks,
        careRecipientId: event.careRecipientId,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TasksStatus.failure,
        errorMessage: e.toString(),
      ));
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
    emit(state.copyWith(selectedCategory: event.category));
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
        category: event.category,
        frequency: event.frequency,
        assignedToName: event.assignedToName,
      );

      final created = await _repository.addTask(newTask);
      final updatedList = List<TaskModel>.from(state.tasks)..insert(0, created);

      emit(state.copyWith(
        tasks: updatedList,
        isCreatingTask: false,
        createTaskSuccess: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isCreatingTask: false,
        errorMessage: e.toString(),
      ));
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
      final updatedList = state.tasks.where((t) => t.id != event.taskId).toList();
      emit(state.copyWith(tasks: updatedList));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }
}
