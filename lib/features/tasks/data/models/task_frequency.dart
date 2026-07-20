/// Enum for task recurrence/frequency.
enum TaskFrequency {
  once('Única', 'once'),
  daily('Diária', 'daily'),
  weekly('Semanal', 'weekly');

  const TaskFrequency(this.label, this.value);

  final String label;
  final String value;

  static TaskFrequency fromValue(String value) {
    return TaskFrequency.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TaskFrequency.once,
    );
  }
}
