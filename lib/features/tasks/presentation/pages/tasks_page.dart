import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_bottom_navigation.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../data/models/task_category.dart';
import '../../data/repositories/tasks_repository.dart';
import '../bloc/tasks_bloc.dart';
import '../widgets/create_task_bottom_sheet.dart';
import '../widgets/task_card.dart';
import '../widgets/task_detail_modal.dart';

/// Main Tasks Page for managing care routines.
class TasksPage extends StatelessWidget {
  const TasksPage({super.key, this.careRecipientId});

  final String? careRecipientId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TasksBloc(
        repository: TasksRepository(),
      )..add(TasksLoadEvent(careRecipientId: careRecipientId)),
      child: const TasksView(),
    );
  }
}

class TasksView extends StatelessWidget {
  const TasksView({super.key});

  void _onBottomNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
        break;
      case 1:
        // Already on Tasks
        break;
      case 2:
        context.push(AppRoutes.coraChat);
        break;
      case 3:
        context.push(AppRoutes.chat);
        break;
      case 4:
        context.push(AppRoutes.sos);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Tarefas de Cuidado',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: AppColors.primary, size: 28),
            onPressed: () {
              final state = context.read<TasksBloc>().state;
              CreateTaskBottomSheet.show(
                context,
                careRecipientId: state.careRecipientId ?? 'recipient_lucia',
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<TasksBloc, TasksState>(
          builder: (context, state) {
            if (state.status == TasksStatus.loading) {
              return const AppLoading();
            }

            if (state.status == TasksStatus.failure) {
              return AppErrorView(
                message: state.errorMessage ??
                    'Erro ao carregar as tarefas de cuidado.',
                onRetry: () {
                  context.read<TasksBloc>().add(
                        TasksLoadEvent(
                            careRecipientId: state.careRecipientId),
                      );
                },
              );
            }

            final filteredTasks = state.filteredTasks;

            return Column(
              children: [
                // Filter Tabs (Todas, Hoje, Concluídas, Atrasadas)
                _buildTabFilters(context, state.activeFilterTab),
                const SizedBox(height: AppSpacing.xs),

                // Category Chips Filter
                _buildCategoryFilters(context, state.selectedCategory),
                const SizedBox(height: AppSpacing.sm),

                // Task List
                Expanded(
                  child: filteredTasks.isEmpty
                      ? _buildEmptyState(context, state)
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          itemCount: filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];
                            return TaskCard(
                              task: task,
                              onToggleCompletion: () {
                                context.read<TasksBloc>().add(
                                      TaskToggleCompletionEvent(
                                          taskId: task.id),
                                    );
                              },
                              onTapDetail: () {
                                TaskDetailModal.show(context, task);
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final state = context.read<TasksBloc>().state;
          CreateTaskBottomSheet.show(
            context,
            careRecipientId: state.careRecipientId ?? 'recipient_lucia',
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Nova Tarefa',
          style: AppTypography.labelLarge.copyWith(color: Colors.white),
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 1,
        onTap: (index) => _onBottomNavTap(context, index),
      ),
    );
  }

  Widget _buildTabFilters(BuildContext context, String currentTab) {
    final tabs = [
      {'id': 'all', 'label': 'Todas'},
      {'id': 'today', 'label': 'Hoje'},
      {'id': 'completed', 'label': 'Concluídas'},
      {'id': 'overdue', 'label': 'Atrasadas'},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: tabs.map((t) {
          final isSelected = t['id'] == currentTab;
          return GestureDetector(
            onTap: () {
              context.read<TasksBloc>().add(
                    TasksFilterChangedEvent(filterTab: t['id']!),
                  );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              child: Text(
                t['label']!,
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryFilters(
      BuildContext context, TaskCategory? selectedCategory) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          // All categories chip
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: ChoiceChip(
              label: const Text('Todas Categorias'),
              selected: selectedCategory == null,
              selectedColor: AppColors.primaryLight.withValues(alpha: 0.3),
              labelStyle: AppTypography.labelSmall.copyWith(
                color: selectedCategory == null
                    ? AppColors.primaryDark
                    : AppColors.textSecondary,
                fontWeight: selectedCategory == null ? FontWeight.bold : null,
              ),
              onSelected: (_) {
                context.read<TasksBloc>().add(
                      const TasksCategoryFilterChangedEvent(category: null),
                    );
              },
            ),
          ),
          ...TaskCategory.values.map((cat) {
            final isSelected = selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cat.icon,
                        size: 12,
                        color: isSelected ? Colors.white : cat.color),
                    const SizedBox(width: 4),
                    Text(cat.label),
                  ],
                ),
                selected: isSelected,
                selectedColor: cat.color,
                labelStyle: AppTypography.labelSmall.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : null,
                ),
                onSelected: (_) {
                  context.read<TasksBloc>().add(
                        TasksCategoryFilterChangedEvent(
                            category: isSelected ? null : cat),
                      );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, TasksState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.task_alt_rounded,
              size: 64,
              color: AppColors.primaryLight,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Nenhuma tarefa encontrada',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Não há tarefas correspondentes aos filtros selecionados.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
