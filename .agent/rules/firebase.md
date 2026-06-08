# Firebase Rules — CareHub Plus

## Access Pattern (strict layering)
```
Widget → BLoC → Repository → FirebaseService → Firebase SDK
```
Firebase SDK must NEVER be called outside of `lib/services/` or `lib/features/*/data/repositories/`.

## Repository Template
```dart
class FeatureRepository {
  FeatureRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<FeatureModel> fetchById(String id) async {
    try {
      final doc = await _firestore
          .collection('features')
          .doc(id)
          .get();
      if (!doc.exists) throw const AppException('Document not found');
      return FeatureModel.fromJson(doc.data()!..['id'] = doc.id);
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? 'Firebase error', code: e.code);
    }
  }

  Stream<List<FeatureModel>> watchAll(String userId) {
    return _firestore
        .collection('features')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FeatureModel.fromJson(doc.data()..['id'] = doc.id))
            .toList());
  }
}
```

## Firestore Naming Conventions
- Collections: `camelCase` plural (e.g., `appointments`, `userProfiles`)
- Document fields: `camelCase`
- Always include `createdAt` and `updatedAt` as `Timestamp`
- Always include `userId` for user-owned documents

## Auth Rules
- Auth state is managed by `AuthService` (`lib/services/auth_service.dart`)
- Never call `FirebaseAuth.instance` directly in BLoC or Widget
- Auth errors must be caught and converted to typed `AuthFailure`

## Offline & Error Handling
- All Firestore calls wrapped in try/catch converting `FirebaseException` → `AppException`
- Enable Firestore offline persistence in `main.dart`
- Loading states must be shown during ALL async calls — no silent loading

## Security
- Never store sensitive data in Firestore without field-level security rules
- Never log Firebase tokens or user emails
- Use Firebase Auth UID as document owner reference, never username or email
