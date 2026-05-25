import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService(this._db);

  static FirestoreService get instance => FirestoreService(FirebaseFirestore.instance);

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

  Future<void> upsertProfile({
    required String uid,
    required List<String> focusAreas,
  }) async {
    final ref = _userDoc(uid);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final now = FieldValue.serverTimestamp();

      final payload = <String, dynamic>{
        'focusAreas': focusAreas,
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
    await _dailyCollection(uid).doc(dayId).set(
      <String, dynamic>{
        'completedAt': FieldValue.serverTimestamp(),
        'itemCount': itemCount,
      },
      SetOptions(merge: true),
    );
  }
}

