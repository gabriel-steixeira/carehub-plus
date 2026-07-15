/// Enum representing the type of care recipient.
enum CareRecipientType {
  child('Criança', 'child'),
  elderly('Idoso', 'elderly'),
  pet('Pet', 'pet'),
  other('Outro', 'other');

  const CareRecipientType(this.label, this.value);

  /// Display label in Portuguese.
  final String label;

  /// Firestore string value.
  final String value;

  /// Creates a [CareRecipientType] from a Firestore string value.
  static CareRecipientType fromValue(String value) {
    return CareRecipientType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CareRecipientType.other,
    );
  }
}
