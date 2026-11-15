import 'package:flutter/material.dart';

enum WithdrawalStatus {
  notEligible,
  eligible,
  pendingReview,
  approved,
  rejected,
  paid,
}

extension WithdrawalStatusExtension on WithdrawalStatus {
  String get displayName {
    switch (this) {
      case WithdrawalStatus.notEligible:
        return 'Not Eligible';
      case WithdrawalStatus.eligible:
        return 'Eligible';
      case WithdrawalStatus.pendingReview:
        return 'Pending Review';
      case WithdrawalStatus.approved:
        return 'Approved';
      case WithdrawalStatus.rejected:
        return 'Rejected';
      case WithdrawalStatus.paid:
        return 'Paid';
    }
  }

  Color get color {
    switch (this) {
      case WithdrawalStatus.notEligible:
        return const Color(0xFF64748B);
      case WithdrawalStatus.eligible:
        return const Color(0xFF38BDF8);
      case WithdrawalStatus.pendingReview:
        return const Color(0xFFF59E0B);
      case WithdrawalStatus.approved:
        return const Color(0xFF10B981);
      case WithdrawalStatus.rejected:
        return const Color(0xFFF43F5E);
      case WithdrawalStatus.paid:
        return const Color(0xFF34D399);
    }
  }

  static WithdrawalStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'eligible':
        return WithdrawalStatus.eligible;
      case 'pending review':
      case 'pendingreview':
      case 'pending':
        return WithdrawalStatus.pendingReview;
      case 'approved':
        return WithdrawalStatus.approved;
      case 'rejected':
        return WithdrawalStatus.rejected;
      case 'paid':
        return WithdrawalStatus.paid;
      case 'not eligible':
      case 'noteligible':
      default:
        return WithdrawalStatus.notEligible;
    }
  }
}

class WithdrawalRequest {
  final String id;
  final String userId;
  final String fullName;
  final String upiId;
  final int amount; // Gold Coins = INR
  final int coinsReserved;
  final String monthYear; // YYYY-MM
  final WithdrawalStatus status;
  final String? notes;
  final String? rejectionReason;
  final String? paymentRef;
  final DateTime submittedAt;
  final DateTime? reviewedAt;

  WithdrawalRequest({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.upiId,
    required this.amount,
    required this.coinsReserved,
    required this.monthYear,
    this.status = WithdrawalStatus.pendingReview,
    this.notes,
    this.rejectionReason,
    this.paymentRef,
    required this.submittedAt,
    this.reviewedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'upi_id': upiId,
      'amount': amount,
      'coins_reserved': coinsReserved,
      'month_year': monthYear,
      'status': status.displayName,
      'notes': notes,
      'rejection_reason': rejectionReason,
      'payment_ref': paymentRef,
      'submitted_at': submittedAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
    };
  }

  factory WithdrawalRequest.fromMap(Map<String, dynamic> map) {
    return WithdrawalRequest(
      id: map['id'] as String,
      userId: map['user_id'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      upiId: map['upi_id'] as String? ?? '',
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      coinsReserved: (map['coins_reserved'] as num?)?.toInt() ?? 0,
      monthYear: map['month_year'] as String? ?? '',
      status: WithdrawalStatusExtension.fromString(map['status'] as String?),
      notes: map['notes'] as String?,
      rejectionReason: map['rejection_reason'] as String?,
      paymentRef: map['payment_ref'] as String?,
      submittedAt: DateTime.tryParse(map['submitted_at'] as String? ?? '') ?? DateTime.now(),
      reviewedAt: map['reviewed_at'] != null ? DateTime.tryParse(map['reviewed_at'] as String) : null,
    );
  }
}
