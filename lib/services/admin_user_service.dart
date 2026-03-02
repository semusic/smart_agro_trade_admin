import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> pendingUsersStream() {
    return _db
        .collection('users')
        .where('approved', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> approveUser(String uid) async {
    await _db.collection('users').doc(uid).update({
      'approved': true,
      'approvedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectUser(String uid) async {
    // safest for now: just delete the profile doc
    await _db.collection('users').doc(uid).delete();

    // OPTIONAL (later): also delete firebase auth user via Admin SDK (server)
  }
}