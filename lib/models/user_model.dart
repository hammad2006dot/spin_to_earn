import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final int points;
  final int totalEarnings;
  final int todayEarning;
  final String? referredBy;
  final String myReferralCode;
  final String upiId;
  final DateTime lastLoginDate;
  final int spinsToday;
  final DateTime lastSpinDate;
  final bool referralCodeApply;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.points,
    required this.totalEarnings,
    required this.todayEarning,
    this.referredBy,
    required this.myReferralCode,
    required this.upiId,
    required this.lastLoginDate,
    required this.spinsToday,
    required this.lastSpinDate,
    this.referralCodeApply = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'points': points,
      'totalEarnings': totalEarnings,
      'todayEarning': todayEarning,
      'referredBy': referredBy,
      'myReferralCode': myReferralCode,
      'upiId': upiId,
      'lastLoginDate': lastLoginDate,
      'spinsToday': spinsToday,
      'lastSpinDate': lastSpinDate,
      'referralCodeApply': referralCodeApply,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      points: map['points'] ?? 0,
      totalEarnings: map['totalEarnings'] ?? 0,
      todayEarning: map['todayEarning'] ?? 0,
      referredBy: map['referredBy'],
      myReferralCode: map['myReferralCode'] ?? '',
      upiId: map['upiId'] ?? '',
      lastLoginDate: (map['lastLoginDate'] as Timestamp).toDate(),
      spinsToday: map['spinsToday'] ?? 0,
      lastSpinDate: (map['lastSpinDate'] as Timestamp).toDate(),
      referralCodeApply: map['referralCodeApply'] ?? false,
    );
  }
}
