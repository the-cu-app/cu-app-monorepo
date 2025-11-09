/// Zelle recipient model
class ZelleRecipient {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImage;
  final bool isEnrolled;
  final bool isFavorite;
  final DateTime? lastPaymentDate;
  final double? lastPaymentAmount;

  ZelleRecipient({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImage,
    this.isEnrolled = false,
    this.isFavorite = false,
    this.lastPaymentDate,
    this.lastPaymentAmount,
  });

  factory ZelleRecipient.fromJson(Map<String, dynamic> json) {
    return ZelleRecipient(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      profileImage: json['profile_image'],
      isEnrolled: json['is_enrolled'] ?? false,
      isFavorite: json['is_favorite'] ?? false,
      lastPaymentDate: json['last_payment_date'] != null
          ? DateTime.parse(json['last_payment_date'])
          : null,
      lastPaymentAmount: json['last_payment_amount']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profile_image': profileImage,
      'is_enrolled': isEnrolled,
      'is_favorite': isFavorite,
      'last_payment_date': lastPaymentDate?.toIso8601String(),
      'last_payment_amount': lastPaymentAmount,
    };
  }
}

/// Zelle payment request model
class ZellePaymentRequest {
  final String id;
  final String requesterId;
  final String requesterName;
  final String requesterEmail;
  final String recipientId;
  final double amount;
  final String? memo;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String status; // pending, accepted, declined, expired

  ZellePaymentRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.requesterEmail,
    required this.recipientId,
    required this.amount,
    this.memo,
    required this.createdAt,
    this.expiresAt,
    required this.status,
  });

  factory ZellePaymentRequest.fromJson(Map<String, dynamic> json) {
    return ZellePaymentRequest(
      id: json['id'] ?? '',
      requesterId: json['requester_id'] ?? '',
      requesterName: json['requester_name'] ?? '',
      requesterEmail: json['requester_email'] ?? '',
      recipientId: json['recipient_id'] ?? '',
      amount: json['amount']?.toDouble() ?? 0.0,
      memo: json['memo'],
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requester_id': requesterId,
      'requester_name': requesterName,
      'requester_email': requesterEmail,
      'recipient_id': recipientId,
      'amount': amount,
      'memo': memo,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'status': status,
    };
  }
}

/// Zelle transaction model
class ZelleTransaction {
  final String id;
  final String senderId;
  final String senderName;
  final String recipientId;
  final String recipientName;
  final double amount;
  final String? memo;
  final DateTime timestamp;
  final String status; // completed, pending, failed
  final String type; // sent, received

  ZelleTransaction({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.recipientId,
    required this.recipientName,
    required this.amount,
    this.memo,
    required this.timestamp,
    required this.status,
    required this.type,
  });

  factory ZelleTransaction.fromJson(Map<String, dynamic> json) {
    return ZelleTransaction(
      id: json['id'] ?? '',
      senderId: json['sender_id'] ?? '',
      senderName: json['sender_name'] ?? '',
      recipientId: json['recipient_id'] ?? '',
      recipientName: json['recipient_name'] ?? '',
      amount: json['amount']?.toDouble() ?? 0.0,
      memo: json['memo'],
      timestamp: DateTime.parse(json['timestamp']),
      status: json['status'] ?? 'completed',
      type: json['type'] ?? 'sent',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_name': senderName,
      'recipient_id': recipientId,
      'recipient_name': recipientName,
      'amount': amount,
      'memo': memo,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'type': type,
    };
  }
}

/// Zelle recurring payment model
class ZelleRecurringPayment {
  final String id;
  final String recipientId;
  final String recipientName;
  final double amount;
  final String frequency; // weekly, monthly, biweekly
  final DateTime startDate;
  final DateTime? endDate;
  final String? memo;
  final bool isActive;
  final DateTime? lastExecutionDate;
  final DateTime? nextExecutionDate;

  ZelleRecurringPayment({
    required this.id,
    required this.recipientId,
    required this.recipientName,
    required this.amount,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.memo,
    this.isActive = true,
    this.lastExecutionDate,
    this.nextExecutionDate,
  });

  factory ZelleRecurringPayment.fromJson(Map<String, dynamic> json) {
    return ZelleRecurringPayment(
      id: json['id'] ?? '',
      recipientId: json['recipient_id'] ?? '',
      recipientName: json['recipient_name'] ?? '',
      amount: json['amount']?.toDouble() ?? 0.0,
      frequency: json['frequency'] ?? 'monthly',
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      memo: json['memo'],
      isActive: json['is_active'] ?? true,
      lastExecutionDate: json['last_execution_date'] != null
          ? DateTime.parse(json['last_execution_date'])
          : null,
      nextExecutionDate: json['next_execution_date'] != null
          ? DateTime.parse(json['next_execution_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipient_id': recipientId,
      'recipient_name': recipientName,
      'amount': amount,
      'frequency': frequency,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'memo': memo,
      'is_active': isActive,
      'last_execution_date': lastExecutionDate?.toIso8601String(),
      'next_execution_date': nextExecutionDate?.toIso8601String(),
    };
  }
}