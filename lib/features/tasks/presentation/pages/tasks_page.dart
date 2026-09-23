import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/categories/data/repositories/care_categories_repository.dart';
import '../../../../features/categories/domain/entities/care_category_entity.dart';
import '../../../../features/categories/presentation/bloc/care_categories_bloc.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_bottom_navigation.dart';
import '../../../../shared/widgets/app_empty_view.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_page_frame.dart';
import '../../../../shared/widgets/app_responsive_body.dart';
import '../../../../shared/widgets/app_search_field.dart';
import '../../../../shared/widgets/category_chip_selector.dart';
import '../../../../shared/widgets/manage_categories_bottom_sheet.dart';
import '../../../dashboard/presentation/widgets/active_profile_chip.dart';
import '../../../network/data/repositories/network_repository.dart';
import '../../../network/presentation/bloc/network_bloc.dart';
import '../../../sos/presentation/models/sos_request_args.dart';
import '../../data/repositories/tasks_repository.dart';
import '../bloc/tasks_bloc.dart';
import '../widgets/create_task_bottom_sheet.dart';
import '../widgets/task_card.dart';
import '../widgets/task_detail_modal.dart';
import '../widgets/task_sos_swipe_action.dart';
import '../widgets/tasks_date_navigation_bar.dart';
import '../widgets/tasks_header_section.dart';
import '../widgets/tasks_sort_dropdown.dart';

/// Tela principal de Tarefas de cuidado.
class TasksPage extends StatelessWidget {
  const TasksPage({
    super.key,
    this.careRecipientId,
    this.isSosSelectionMode = false,
  });

  final String? careRecipientId;

  /// Quando verdadeiro, a tela devolve uma tarefa ao SOS em vez de abrir outro
  /// fluxo. As ações críticas ficam visíveis nos cards.
  final bool isSosSelectionMode;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              TasksBloc(repository: TasksRepository())
                ..add(TasksLoadEvent(careRecipientId: careRecipientId)),
        ),
        BlocProvider(
          create: (context) =>
              NetworkBloc(repository: NetworkRepository())
                ..add(const NetworkLoadEvent()),
        ),
        BlocProvider(
          create: (context) =>
              CareCategoriesBloc(repository: CareCategoriesRepository())
                ..add(const CareCategoriesLoadEvent()),
        ),
      ],
      child: TasksView(isSosSelectionMode: isSosSelectionMode),
    );
  }
}

class TasksView extends StatefulWidget {
  const TasksView({super.key, required this.isSosSelectionMode});

  final bool isSosSelectionMode;

  @override
  State<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<TasksView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onBottomNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
      case 1:
        // Já estamos em Tarefas.
        break;
      case 2:
        context.push(AppRoutes.coraChat);
      case 3:
        context.push(AppRoutes.chat);
      case 4:
        context.push(AppRoutes.sos);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame(
        child: Column(
          children: [
            BlocSelector<TasksBloc, TasksState, String?>(
              selector: (state) => state.caregiver?.photoUrl,
              builder: (context, photoUrl) => AppHeader(photoUrl: photoUrl),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: AppColors.splashGradient,
                ),
                child: BlocBuilder<TasksBloc, TasksState>(
                  builder: (context, state) {
                    if (state.status == TasksStatus.loading &&
                        state.tasks.isEmpty) {
                      return const AppLoading();
                    }

                    if (state.status == TasksStatus.failure &&
                        state.tasks.isEmpty) {
                      return AppErrorView(
                        message:
                            state.errorMessage ??
                            'Erro ao carregar as tarefas de cuidado.',
                        onRetry: () => context.read<TasksBloc>().add(
                          TasksLoadEvent(
                            careRecipientId: state.careRecipientId,
                          ),
                        ),
                      );
                    }

                    return _TasksContent(
                      state: state,
                      searchController: _searchController,
                      isSosSelectionMode: widget.isSosSelectionMode,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.isSosSelectionMode
          ? null
          : AppBottomNavigation(
              currentIndex: 1,
              onTap: (index) => _onBottomNavTap(context, index),
            ),
    );
  }
}

class _TasksContent extends StatelessWidget {
  const _TasksContent({
    required this.state,
    required this.searchController,
    required this.isSosSelectionMode,
  });

  final TasksState state;
  final TextEditingController searchController;
  final bool isSosSelectionMode;

  @override
  Widget build(BuildContext context) {
    final filteredTasks = state.filteredTasks;
    final visibleTasks = isSosSelectionMode
        ? filteredTasks.where((task) => !task.isCompleted).toList()
        : filteredTasks;
    final selectedDate = state.selectedDate ?? DateTime.now();

    return AppResponsiveBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSosSelectionMode) ...[
            _SosTaskSelectionHeader(onCancel: () => context.pop()),
            const SizedBox(height: AppSpacing.md),
          ] else ...[
            Builder(
              builder: (context) {
                final profile = state.profiles.isEmpty
                    ? null
                    : state.profiles
                              .where((p) => p.id == state.selectedProfileId)
                              .firstOrNull ??
                          state.profiles.first;
                if (profile == null) return const SizedBox.shrink();
                return Column(
                  children: [
                    ActiveProfileChip(
                      profile: profile,
                      onChangeTap: () => context.go(AppRoutes.home),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                );
              },
            ),
          ],
          AppSearchField(
            hintText: 'Buscar tarefas...',
            controller: searchController,
            onChanged: (query) => context.read<TasksBloc>().add(
              TasksSearchQueryChangedEvent(query: query),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!isSosSelectionMode) ...[
            TasksHeaderSection(
              pendingCount: state.pendingCount,
              completedCount: state.completedCount,
              onCreateTask: () => CreateTaskBottomSheet.show(
                context,
                careRecipientId:
                    state.careRecipientId ?? state.selectedProfileId,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          TasksDateNavigationBar(
            selectedDate: selectedDate,
            onDateChanged: (date) => context.read<TasksBloc>().add(
              TasksDateChangedEvent(selectedDate: date),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          BlocBuilder<CareCategoriesBloc, CareCategoriesState>(
            builder: (context, categoriesState) {
              return CategoryChipSelector(
                categories: categoriesState.categories,
                selectedCategoryId: state.selectedCategoryId,
                onCategorySelected: (categoryId) =>
                    context.read<TasksBloc>().add(
                      TasksCategoryFilterChangedEvent(categoryId: categoryId),
                    ),
                onManageCategories: () =>
                    ManageCategoriesBottomSheet.show(context),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          TasksSortDropdown(
            sortOption: state.sortOption,
            onSortSelected: (option) => context.read<TasksBloc>().add(
              TasksSortChangedEvent(sortOption: option),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (visibleTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              child: AppEmptyView(
                message: isSosSelectionMode
                    ? 'Nenhuma tarefa em aberto para este cuidado.'
                    : 'Nenhuma tarefa para a data ou filtros selecionados.',
                icon: Icons.task_alt_rounded,
              ),
            )
          else
            BlocBuilder<CareCategoriesBloc, CareCategoriesState>(
              builder: (context, categoriesState) {
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visibleTasks.length,
                  itemBuilder: (context, index) {
                    final task = visibleTasks[index];
                    final category = categoriesState.categories.firstWhere(
                      (item) => item.id == task.categoryId,
                      orElse: () => categoriesState.categories.isNotEmpty
                          ? categoriesState.categories.last
                          : const _FallbackCategory(),
                    );
                    final taskCard = TaskCard(
                      task: task,
                      category: category,
                      onToggleCompletion: () => context.read<TasksBloc>().add(
                        TaskToggleCompletionEvent(taskId: task.id),
                      ),
                      onTapDetail: () =>
                          TaskDetailModal.show(context, task, category),
                      onRequestSos: isSosSelectionMode
                          ? () => context.pop(task.id)
                          : null,
                    );

                    if (isSosSelectionMode) return taskCard;

                    return TaskSosSwipeAction(
                      taskId: task.id,
                      onRequestSos: () => context.push(
                        AppRoutes.sos,
                        extra: SosRequestArgs(
                          careRecipientId: task.careRecipientId,
                          taskId: task.id,
                        ),
                      ),
                      child: taskCard,
                    );
                  },
                );
              },
            ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

/// Contexto leve que explica a escolha sem competir com os cards.
class _SosTaskSelectionHeader extends StatelessWidget {
  const _SosTaskSelectionHeader({required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppBackButton(
          onPressed: onCancel,
          tooltip: 'Cancelar escolha de tarefa para SOS',
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Escolha uma tarefa para SOS',
                style: AppTypography.averiaTitleLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Toque em SOS na tarefa para a qual você precisa de ajuda.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Categoria neutra usada apenas quando a lista de categorias ainda não
/// carregou — nunca persistida, só evita um crash visual momentâneo.
class _FallbackCategory extends CareCategoryEntity {
  const _FallbackCategory()
    : super(id: 'other', label: 'Outro', iconKey: 'other', colorKey: 'grey');
}
