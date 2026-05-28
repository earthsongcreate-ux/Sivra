import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/daily_completion.dart';
import '../models/daily_pack.dart';
import '../models/user_profile.dart';

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService(this._db);

  static FirestoreService get instance =>
      FirestoreService(FirebaseFirestore.instance);

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _db.collection('users').doc(uid);
  }

  CollectionReference<Map<String, dynamic>> _dailyCollection(String uid) {
    return _userDoc(uid).collection('daily');
  }

  Future<UserProfile?> getProfile(String uid) async {
    final snap = await _userDoc(uid).get();
    if (!snap.exists) {
      return null;
    }

    final data = snap.data();
    if (data == null) {
      return null;
    }

    return UserProfile.fromMap(uid: uid, data: data);
  }

  Future<DailyCompletion?> getDailyCompletion({
    required String uid,
    required String dayId,
  }) async {
    final snap = await _dailyCollection(uid).doc(dayId).get();
    final data = snap.data();
    if (!snap.exists || data == null) {
      return null;
    }

    return DailyCompletion.fromMap(dayId: dayId, data: data);
  }

  Future<DailyPack?> getDailyPack({
    required String uid,
    required String dayId,
  }) async {
    final snap = await _dailyCollection(uid).doc(dayId).get();
    final data = snap.data();
    if (!snap.exists || data == null) {
      return null;
    }

    return DailyPack.fromMap(dayId: dayId, data: data);
  }

  Future<List<DailyPack>> getRecentDailyPacks({
    required String uid,
    int limit = 14,
  }) async {
    final snap = await _dailyCollection(
      uid,
    ).orderBy('dayId', descending: true).limit(limit).get();

    return snap.docs
        .map((doc) => DailyPack.fromMap(dayId: doc.id, data: doc.data()))
        .toList();
  }

  Future<void> createDailyPack({
    required String uid,
    required DailyPack pack,
  }) async {
    await _dailyCollection(
      uid,
    ).doc(pack.dayId).set(pack.toCreateMap(), SetOptions(merge: true));
  }

  Future<void> logEvent({
    required String uid,
    required String name,
    Map<String, dynamic> properties = const <String, dynamic>{},
  }) async {
    await _userDoc(uid).collection('events').add(<String, dynamic>{
      'name': name,
      'properties': properties,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> upsertProfile({
    required String uid,
    required List<String> focusAreas,
    List<String> thinkingRoles = const <String>[],
    String? aiFluencyLevel,
    String? onboardingObstacle,
    String? routineTarget,
    int onboardingVersion = 3,
  }) async {
    final ref = _userDoc(uid);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final now = FieldValue.serverTimestamp();

      final payload = <String, dynamic>{
        'focusAreas': focusAreas,
        'onboarding': <String, dynamic>{
          'version': onboardingVersion,
          if (thinkingRoles.isNotEmpty) 'thinkingRoles': thinkingRoles,
          if (aiFluencyLevel != null) 'aiFluencyLevel': aiFluencyLevel,
          if (onboardingObstacle != null) 'obstacle': onboardingObstacle,
          if (routineTarget != null) 'routineTarget': routineTarget,
          'completedAt': now,
        },
        'updatedAt': now,
      };

      if (!snap.exists) {
        payload['createdAt'] = now;
      }

      tx.set(ref, payload, SetOptions(merge: true));
    });
  }

  Future<void> markDailyCompleted({
    required String uid,
    required String dayId,
    required int itemCount,
  }) async {
    await _dailyCollection(uid).doc(dayId).set(<String, dynamic>{
      'completedAt': FieldValue.serverTimestamp(),
      'itemCount': itemCount,
    }, SetOptions(merge: true));
  }

  Future<void> markDailyItemCompleted({
    required String uid,
    required String dayId,
    required String itemId,
    String? answer,
  }) async {
    final payload = <String, dynamic>{
      'completedItemIds': FieldValue.arrayUnion(<String>[itemId]),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final trimmedAnswer = answer?.trim();
    if (trimmedAnswer != null && trimmedAnswer.isNotEmpty) {
      payload['answersByItemId'] = <String, dynamic>{itemId: trimmedAnswer};
    }

    await _dailyCollection(
      uid,
    ).doc(dayId).set(payload, SetOptions(merge: true));
  }
}
