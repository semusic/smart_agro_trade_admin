import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import '../models/models.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- User Management ---
  Stream<List<AppUser>> getUsers({bool? pendingOnly}) {
    Query query = _db.collection('users');
    if (pendingOnly == true) {
      query = query.where('isApproved', isEqualTo: false).where('isRejected', isEqualTo: false);
    }
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList());
  }

  Future<void> approveUser(String uid) async {
    await _db.collection('users').doc(uid).update({'isApproved': true});
  }

  Future<void> rejectUser(String uid) async {
    // Setting isRejected to true instead of deleting
    await _db.collection('users').doc(uid).update({
      'isApproved': false,
      'isRejected': true,
    });
  }

  Future<void> toggleUserBlock(String uid, bool block) async {
    await _db.collection('users').doc(uid).update({'isBlocked': block});
  }

  // --- Listing Management ---
  Stream<List<Listing>> getListings() {
    return _db.collection('listings').orderBy('createdAt', descending: true).snapshots().map(
        (snapshot) => snapshot.docs.map((doc) => Listing.fromFirestore(doc)).toList());
  }

  Future<void> flagListing(String listingId, String reason) async {
    await _db.runTransaction((transaction) async {
      transaction.update(_db.collection('listings').doc(listingId), {'isFlagged': true});
      transaction.set(_db.collection('flags').doc(), {
        'type': 'listing',
        'targetId': listingId,
        'reason': reason,
        'adminId': _auth.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> disableListing(String listingId) async {
    await _db.collection('listings').doc(listingId).update({'status': 'disabled'});
  }

  // --- Dispute Management ---
  Stream<List<Dispute>> getDisputes() {
    return _db.collection('disputes').orderBy('createdAt', descending: true).snapshots().map(
        (snapshot) => snapshot.docs.map((doc) => Dispute.fromFirestore(doc)).toList());
  }

  Future<void> updateDisputeStatus(String disputeId, String status) async {
    await _db.collection('disputes').doc(disputeId).update({'status': status});
  }

  Future<void> addAdminReply(String disputeId, String reply) async {
    await _db.collection('disputes').doc(disputeId).update({'adminReply': reply});
  }

  // --- Bidding Management ---
  Stream<List<Bid>> getBids() {
    return _db.collection('bids').orderBy('createdAt', descending: true).snapshots().map(
        (snapshot) => snapshot.docs.map((doc) => Bid.fromFirestore(doc)).toList());
  }

  Future<void> flagBid(String bidId, String reason) async {
    await _db.runTransaction((transaction) async {
      transaction.update(_db.collection('bids').doc(bidId), {'isFlagged': true});
      transaction.set(_db.collection('flags').doc(), {
        'type': 'bid',
        'targetId': bidId,
        'reason': reason,
        'adminId': _auth.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // --- Flags Management ---
  Stream<List<SystemFlag>> getFlags() {
    return _db.collection('flags').orderBy('createdAt', descending: true).snapshots().map(
        (snapshot) => snapshot.docs.map((doc) => SystemFlag.fromFirestore(doc)).toList());
  }

  // --- AI Config Management ---
  Stream<AiConfig> getAiConfig() {
    return _db.collection('ai_config').doc('tomato_model').snapshots().map((doc) {
      if (!doc.exists) {
        return AiConfig(
          modelVersion: 'v1.0',
          apiBaseUrl: 'https://api.example.com',
          confidenceThreshold: 0.75,
          updatedAt: DateTime.now(),
        );
      }
      return AiConfig.fromFirestore(doc);
    });
  }

  Future<void> updateAiConfig(String version, String url, double threshold) async {
    await _db.collection('ai_config').doc('tomato_model').set({
      'modelVersion': version,
      'apiBaseUrl': url,
      'confidenceThreshold': threshold,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // --- Export Reports ---
  Future<void> exportToCsv(String collectionName) async {
    QuerySnapshot snapshot = await _db.collection(collectionName).get();
    List<List<dynamic>> rows = [];
    
    if (snapshot.docs.isEmpty) return;
    
    // Header
    Map<String, dynamic> firstDoc = snapshot.docs.first.data() as Map<String, dynamic>;
    rows.add(firstDoc.keys.toList());
    
    // Data
    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      rows.add(data.values.map((v) {
        if (v is Timestamp) return v.toDate().toIso8601String();
        return v;
      }).toList());
    }

    String csvContent = const ListToCsvConverter().convert(rows);
    final bytes = utf8.encode(csvContent);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "$collectionName-report.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // --- Dashboard Stats ---
  Future<Map<String, dynamic>> getDashboardStats() async {
    final users = await _db.collection('users').get();
    final listings = await _db.collection('listings').get();
    final disputes = await _db.collection('disputes').get();
    final bids = await _db.collection('bids').get();

    int approved = 0;
    int pending = 0;
    for (var doc in users.docs) {
      final data = doc.data();
      if (data['isApproved'] == true) {
        approved++;
      } else if (data['isRejected'] != true) {
        pending++;
      }
    }

    int active = 0;
    int sold = 0;
    for (var doc in listings.docs) {
      final data = doc.data();
      if (data['status'] == 'active') {
        active++;
      } else if (data['status'] == 'sold') {
        sold++;
      }
    }

    int openDisputes = 0;
    for (var doc in disputes.docs) {
      final data = doc.data();
      if (data['status'] == 'open') {
        openDisputes++;
      }
    }

    return {
      'totalUsers': users.size,
      'approvedUsers': approved,
      'pendingApprovals': pending,
      'activeListings': active,
      'soldListings': sold,
      'openDisputes': openDisputes,
      'totalBids': bids.size,
    };
  }
}
