import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_bottom_navigation.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../home/presentation/widgets/add_profile_bottom_sheet.dart';
import '../../data/models/task_category.dart';
import '../../data/repositories/tasks_repository.dart';
import '../bloc/tasks_bloc.dart';
import '../widgets/create_task_bottom_sheet.dart';
import '../widgets/task_card.dart';
import '../widgets/task_detail_modal.dart';

/// Main Tasks Page for managing care routines. Redesigned to match Figma layout.
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

class TasksView extends StatefulWidget {
  const TasksView({super.key});

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

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day-$month-$year';
  }

  String _getDateTitle(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Hoje';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Ontem';
    }
    final tomorrow = now.add(const Duration(days: 1));
    if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return 'Amanhã';
    }
    const days = [
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
      'Domingo'
    ];
    return days[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Header area background
      body: BlocBuilder<TasksBloc, TasksState>(
        builder: (context, state) {
          if (state.status == TasksStatus.loading && state.tasks.isEmpty) {
            return const AppLoading();
          }

          if (state.status == TasksStatus.failure && state.tasks.isEmpty) {
            return AppErrorView(
              message: state.errorMessage ??
                  'Erro ao carregar as tarefas de cuidado.',
              onRetry: () {
                context.read<TasksBloc>().add(
                      TasksLoadEvent(careRecipientId: state.careRecipientId),
                    );
              },
            );
          }

          final filteredTasks = state.filteredTasks;
          final selectedDate = state.selectedDate ?? DateTime.now();

          return Column(
            children: [
              // 1. Top App Header
              AppHeader(photoUrl: state.caregiver?.photoUrl),

              // 2. Main Body with Splash Gradient
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: AppColors.splashGradient,
                  ),
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 2.1 Profile Filter Chips Section
                          _buildProfileFilterSection(context, state),
                          const SizedBox(height: AppSpacing.md),

                          // 2.2 Search Bar
                          _buildSearchBar(context),
                          const SizedBox(height: AppSpacing.lg),

                          // 2.3 Title & "+ Nova" Button Row
                          _buildTitleRow(context, state),
                          const SizedBox(height: AppSpacing.md),

                          // 2.4 Date Navigation Bar
                          _buildDateNavigationBar(context, selectedDate),
                          const SizedBox(height: AppSpacing.md),

                          // 2.5 Category Filters & Sorting Row
                          _buildCategoryFiltersRow(
                            context,
                            state.selectedCategory,
                            state.sortOption,
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // 2.6 Task List
                          if (filteredTasks.isEmpty)
                            _buildEmptyState(context, state)
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredTasks.length,
                              itemBuilder: (context, index) {
                                final task = filteredTasks[index];
                                return TaskCard(
                                  task: task,
                                  onToggleCompletion: () {
                                    context.read<TasksBloc>().add(
                                          TaskToggleCompletionEvent(
                                            taskId: task.id,
                                          ),
                                        );
                                  },
                                  onTapDetail: () {
                                    TaskDetailModal.show(context, task);
                                  },
                                );
                              },
                            ),

                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 1,
        onTap: (index) => _onBottomNavTap(context, index),
      ),
    );
  }

  /// Profile Filter Section ("Filtrar por perfil")
  Widget _buildProfileFilterSection(BuildContext context, TasksState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: 6),
          child: Text(
            'Filtrar por perfil',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              // "Todos" Chip
              _buildProfileChip(
                context: context,
                label: 'Todos',
                isSelected: state.selectedProfileId == 'all',
                onTap: () {
                  context.read<TasksBloc>().add(
                        const TasksProfileChangedEvent(profileId: 'all'),
                      );
                },
              ),
              const SizedBox(width: AppSpacing.xs),

              // Profiles Chips
              ...state.profiles.map((profile) {
                final isSelected = state.selectedProfileId == profile.id;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: _buildProfileChip(
                    context: context,
                    label: profile.name,
                    photoUrl: profile.photoUrl,
                    type: profile.type,
                    isSelected: isSelected,
                    onTap: () {
                      context.read<TasksBloc>().add(
                            TasksProfileChangedEvent(profileId: profile.id),
                          );
                    },
                  ),
                );
              }),

              // "+" Add Profile Button
              GestureDetector(
                onTap: () => AddProfileBottomSheet.show(context),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    String? photoUrl,
    String? type,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (photoUrl != null || type != null) ...[
              CircleAvatar(
                radius: 10,
                backgroundColor: isSelected
                    ? Colors.white.withValues(alpha: 0.3)
                    : AppColors.surfaceVariant,
                backgroundImage:
                    photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                    ? Icon(
                        type == 'pet' ? Icons.pets : Icons.person_outline,
                        size: 12,
                        color: isSelected ? Colors.white : AppColors.primary,
                      )
                    : null,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Search Bar
  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (query) {
          context
              .read<TasksBloc>()
              .add(TasksSearchQueryChangedEvent(query: query));
        },
        decoration: InputDecoration(
          icon: const Icon(Icons.search, color: AppColors.textSecondary),
          hintText: 'Buscar tarefas...',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  /// Title Row with Title, Subtitle and "+ Nova" Button
  Widget _buildTitleRow(BuildContext context, TasksState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tarefas',
              style: AppTypography.displayLarge.copyWith(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${state.pendingCount} pendentes, ${state.completedCount} concluídas',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),

        // "+ Nova" Pill Button
        GestureDetector(
          onTap: () {
            CreateTaskBottomSheet.show(
              context,
              careRecipientId: state.careRecipientId ?? 'recipient_lucia',
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, color: Colors.white, size: 18),
                const SizedBox(width: 4),
                Text(
                  'Nova',
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Date Navigation Bar (< Hoje 30-04-2026 >)
  Widget _buildDateNavigationBar(BuildContext context, DateTime selectedDate) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(
            Icons.chevron_left,
            color: AppColors.textPrimary,
            size: 28,
          ),
          onPressed: () {
            context.read<TasksBloc>().add(
                  TasksDateChangedEvent(
                    selectedDate:
                        selectedDate.subtract(const Duration(days: 1)),
                  ),
                );
          },
        ),
        Column(
          children: [
            Text(
              _getDateTitle(selectedDate),
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              _formatDate(selectedDate),
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(
            Icons.chevron_right,
            color: AppColors.textPrimary,
            size: 28,
          ),
          onPressed: () {
            context.read<TasksBloc>().add(
                  TasksDateChangedEvent(
                    selectedDate: selectedDate.add(const Duration(days: 1)),
                  ),
                );
          },
        ),
      ],
    );
  }

  /// Category Filters Row & Sort Dropdown
  Widget _buildCategoryFiltersRow(
    BuildContext context,
    TaskCategory? selectedCategory,
    String sortOption,
  ) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              // "Todos" Category Chip
              _buildCategoryChip(
                label: 'Todos',
                isSelected: selectedCategory == null,
                onTap: () {
                  context.read<TasksBloc>().add(
                        const TasksCategoryFilterChangedEvent(category: null),
                      );
                },
              ),
              const SizedBox(width: AppSpacing.xs),

              // Categories Chips
              ...TaskCategory.values.map((cat) {
                final isSelected = selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: _buildCategoryChip(
                    label: cat.label,
                    icon: cat.icon,
                    isSelected: isSelected,
                    onTap: () {
                      context.read<TasksBloc>().add(
                            TasksCategoryFilterChangedEvent(
                              category: isSelected ? null : cat,
                            ),
                          );
                    },
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Sort Dropdown ("Ordenar por: Horário v")
        Align(
          alignment: Alignment.centerRight,
          child: PopupMenuButton<String>(
            initialValue: sortOption,
            onSelected: (option) {
              context
                  .read<TasksBloc>()
                  .add(TasksSortChangedEvent(sortOption: option));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border:
                    Border.all(color: AppColors.border.withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.filter_list,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Ordenar por: ${sortOption == 'time' ? 'Horário' : sortOption == 'category' ? 'Categoria' : 'Status'}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'time',
                child: Text('Horário'),
              ),
              PopupMenuItem(
                value: 'category',
                child: Text('Categoria'),
              ),
              PopupMenuItem(
                value: 'status',
                child: Text('Status'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, TasksState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      margin: const EdgeInsets.only(top: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.task_alt_rounded,
            size: 54,
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
            'Não há tarefas para a data ou filtros selecionados.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
