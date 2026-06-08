# Flutter BLoC Rules — CareHub Plus

## BLoC Structure (use this template, always)

### event.dart
```dart
part of '[feature]_bloc.dart';

abstract class [Feature]Event extends Equatable {
  const [Feature]Event();
  @override
  List<Object?> get props => [];
}

class [Feature]LoadEvent extends [Feature]Event {
  const [Feature]LoadEvent();
}

class [Feature]UpdateEvent extends [Feature]Event {
  const [Feature]UpdateEvent({required this.data});
  final SomeEntity data;
  @override
  List<Object?> get props => [data];
}
```

### state.dart
```dart
part of '[feature]_bloc.dart';

enum [Feature]Status { initial, loading, success, failure }

class [Feature]State extends Equatable {
  const [Feature]State({
    this.status = [Feature]Status.initial,
    this.data,
    this.errorMessage,
  });
  final [Feature]Status status;
  final SomeEntity? data;
  final String? errorMessage;

  [Feature]State copyWith({
    [Feature]Status? status,
    SomeEntity? data,
    String? errorMessage,
  }) => [Feature]State(
    status: status ?? this.status,
    data: data ?? this.data,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [status, data, errorMessage];
}
```

### bloc.dart
```dart
class [Feature]Bloc extends Bloc<[Feature]Event, [Feature]State> {
  [Feature]Bloc({required [Feature]Repository repository})
    : _repository = repository,
      super(const [Feature]State()) {
    on<[Feature]LoadEvent>(_onLoad);
  }

  final [Feature]Repository _repository;

  Future<void> _onLoad(
    [Feature]LoadEvent event,
    Emitter<[Feature]State> emit,
  ) async {
    emit(state.copyWith(status: [Feature]Status.loading));
    try {
      final data = await _repository.fetchData();
      emit(state.copyWith(status: [Feature]Status.success, data: data));
    } catch (e) {
      emit(state.copyWith(
        status: [Feature]Status.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
```

## BLoC in Widgets
```dart
// CORRECT — page provides BLoC, inner widgets just consume
class FeaturePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FeatureBloc(repository: context.read())
        ..add(const FeatureLoadEvent()),
      child: const FeatureView(),
    );
  }
}

class FeatureView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeatureBloc, FeatureState>(
      builder: (context, state) {
        return switch (state.status) {
          FeatureStatus.loading => const AppLoading(),
          FeatureStatus.failure => AppErrorView(
              message: state.errorMessage ?? 'Erro inesperado',
              onRetry: () => context.read<FeatureBloc>().add(const FeatureLoadEvent()),
            ),
          FeatureStatus.success => FeatureContent(data: state.data!),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }
}
```

## Rules
- Always use `BlocBuilder` for UI rebuild, `BlocListener` for side effects (navigation, dialogs, toasts)
- Use `BlocConsumer` only when you need BOTH rebuild and side effects on the same widget
- Never use `context.read<Bloc>()` inside `build()` — use it only in event handlers (`onPressed`, etc.)
- Use `context.watch<Bloc>()` only in simple cases; prefer `BlocBuilder` for clarity
- Every BLoC must receive its Repository via constructor injection (never `context.read` inside BLoC)
- Use `Equatable` on all Events and States — always
