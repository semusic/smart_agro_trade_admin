import 'package:cloud_firestore/cloud_firestore.dart';

DateTime parseDateTime(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  } else if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role;
  final bool isApproved;
  final bool isBlocked;
  final bool isRejected;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.isApproved,
    required this.isBlocked,
    this.isRejected = false,
    required this.createdAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppUser(
      uid: doc.id,
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      role: data['role']?.toString() ?? 'buyer',
      isApproved: data['isApproved'] == true,
      isBlocked: data['isBlocked'] == true,
      isRejected: data['isRejected'] == true,
      createdAt: parseDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'isApproved': isApproved,
      'isBlocked': isBlocked,
      'isRejected': isRejected,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class Listing {
  final String id;
  final String cropName;
  final String farmerName;
  final String location;
  final double price;
  final String status;
  final bool isFlagged;
  final DateTime createdAt;

  Listing({
    required this.id,
    required this.cropName,
    required this.farmerName,
    required this.location,
    required this.price,
    required this.status,
    required this.isFlagged,
    required this.createdAt,
  });

  factory Listing.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Listing(
      id: doc.id,
      cropName: data['cropName']?.toString() ?? '',
      farmerName: data['farmerName']?.toString() ?? '',
      location: data['location']?.toString() ?? '',
      price: (data['price'] ?? 0).toDouble(),
      status: data['status']?.toString() ?? 'active',
      isFlagged: data['isFlagged'] == true,
      createdAt: parseDateTime(data['createdAt']),
    );
  }
}

class Dispute {
  final String id;
  final String orderId;
  final String listingId;
  final String buyerId;
  final String farmerId;
  final String message;
  final String status;
  final String? adminReply;
  final DateTime createdAt;

  Dispute({
    required this.id,
    required this.orderId,
    required this.listingId,
    required this.buyerId,
    required this.farmerId,
    required this.message,
    required this.status,
    this.adminReply,
    required this.createdAt,
  });

  factory Dispute.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Dispute(
      id: doc.id,
      orderId: data['orderId']?.toString() ?? '',
      listingId: data['listingId']?.toString() ?? '',
      buyerId: data['buyerId']?.toString() ?? '',
      farmerId: data['farmerId']?.toString() ?? '',
      message: data['message']?.toString() ?? '',
      status: data['status']?.toString() ?? 'open',
      adminReply: data['adminReply']?.toString(),
      createdAt: parseDateTime(data['createdAt']),
    );
  }
}

class Bid {
  final String id;
  final String listingId;
  final String buyerName;
  final String buyerId;
  final double amount;
  final String status;
  final bool isFlagged;
  final DateTime createdAt;

  Bid({
    required this.id,
    required this.listingId,
    required this.buyerName,
    required this.buyerId,
    required this.amount,
    required this.status,
    required this.isFlagged,
    required this.createdAt,
  });

  factory Bid.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Bid(
      id: doc.id,
      listingId: data['listingId']?.toString() ?? '',
      buyerName: data['buyerName']?.toString() ?? '',
      buyerId: data['buyerId']?.toString() ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      status: data['status']?.toString() ?? 'pending',
      isFlagged: data['isFlagged'] == true,
      createdAt: parseDateTime(data['createdAt']),
    );
  }
}

class SystemFlag {
  final String id;
  final String type; // user, listing, bid
  final String targetId;
  final String reason;
  final String adminId;
  final DateTime createdAt;

  SystemFlag({
    required this.id,
    required this.type,
    required this.targetId,
    required this.reason,
    required this.adminId,
    required this.createdAt,
  });

  factory SystemFlag.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SystemFlag(
      id: doc.id,
      type: data['type']?.toString() ?? '',
      targetId: data['targetId']?.toString() ?? '',
      reason: data['reason']?.toString() ?? '',
      adminId: data['adminId']?.toString() ?? '',
      createdAt: parseDateTime(data['createdAt']),
    );
  }
}

class AiConfig {
  final String modelVersion;
  final String apiBaseUrl;
  final double confidenceThreshold;
  final DateTime updatedAt;

  AiConfig({
    required this.modelVersion,
    required this.apiBaseUrl,
    required this.confidenceThreshold,
    required this.updatedAt,
  });

  factory AiConfig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AiConfig(
      modelVersion: data['modelVersion']?.toString() ?? 'v1.0',
      apiBaseUrl: data['apiBaseUrl']?.toString() ?? '',
      confidenceThreshold: (data['confidenceThreshold'] ?? 0.75).toDouble(),
      updatedAt: parseDateTime(data['updatedAt']),
    );
  }
}
