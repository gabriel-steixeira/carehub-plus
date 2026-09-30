import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../services/selected_profile_service.dart';
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

      // Resolve o perfil na ordem: id de navegação → perfil salvo pela seleção
      // do usuário → primeiro da lista. Evita que Tarefas "troque" de assistido
      // quando aberta sem um id (ex.: vinda do SOS pela navegação inferior).
      final resolvedProfileId = await _resolveSelectedProfileId(
        event.careRecipientId,
        profiles,
      );

      emit(
        state.copyWith(
          status: TasksStatus.success,
          caregiver: caregiver,
          profiles: profiles,
          tasks: tasks,
          careRecipientId: resolvedProfileId,
          selectedProfileId: resolvedProfileId,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: TasksStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  /// Resolve o perfil a exibir: id recebido por navegação, depois o perfil
  /// salvo pela seleção do usuário e, por fim, o primeiro da lista.
  Future<String> _resolveSelectedProfileId(
    String? navigationId,
    List<CareRecipientModel> profiles,
  ) async {
    bool existsInList(String id) => profiles.any((p) => p.id == id);

    if (navigationId != null &&
        navigationId.isNotEmpty &&
        existsInList(navigationId)) {
      return navigationId;
    }

    try {
      final service = await SelectedProfileService.create();
      final savedId = service.getSelectedProfileId();
      if (savedId != null && existsInList(savedId)) {
        return savedId;
      }
    } catch (_) {
      // Falha ao ler a seleção não impede o carregamento das tarefas.
    }

    return profiles.isNotEmpty ? profiles.first.id : '';
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
        caregiverId:
            '', // Será sobrescrito pelo addTask com o UID do usuário logado
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
