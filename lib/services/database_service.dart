import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  Future<void> createUser(User user) async {
    final referralCode = _generateReferralCode();
    final newUser = UserModel(
      uid: user.uid,
      name: user.displayName ?? 'No Name',
      email: user.email ?? '',
      points: 0,
      totalEarnings: 0,
      todayEarning: 0,
      myReferralCode: referralCode,
      upiId: '',
      lastLoginDate: DateTime.now(),
      spinsToday: 0,
      lastSpinDate: DateTime.now().subtract(const Duration(days: 1)),
      referredBy: null,
      referralCodeApply: false,
    );

    await _db.collection('users').doc(user.uid).set(newUser.toMap());
    await _db.collection('referralCoders').doc(referralCode).set({'uid': user.uid});
  }

  String _generateReferralCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ123456789';
    return List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  Future<void> updateLastLogin(String uid, {int? dailyBonus}) async {
    final Map<String, dynamic> data = {
      'lastLoginDate': FieldValue.serverTimestamp(),
      'todayEarning': dailyBonus ?? 0,
    };
    if (dailyBonus != null) {
      data['points'] = FieldValue.increment(dailyBonus);
      data['totalEarnings'] = FieldValue.increment(dailyBonus);
    }
    await _db.collection('users').doc(uid).update(data);
  }

  Future<void> updatePoints(String uid, int pointsToAdd, {bool isDailyBonus = false}) async {
    final updateData = {
      'points': FieldValue.increment(pointsToAdd),
      'totalEarnings': FieldValue.increment(pointsToAdd),
    };
    if (isDailyBonus) {
      // Logic for daily bonus handled in provider
    } else {
      updateData['todayEarning'] = FieldValue.increment(pointsToAdd);
    }
    await _db.collection('users').doc(uid).update(updateData);
  }

  Future<void> updateSpinCount(String uid, int newCount) async {
    await _db.collection('users').doc(uid).update({
      'spinsToday': newCount,
      'lastSpinDate': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUpiId(String uid, String upiId) async {
    await _db.collection('users').doc(uid).update({'upiId': upiId});
  }

  Future<bool> applyReferralCode(String uid, String referralCode) async {
    final userDoc = await _db.collection('users').doc(uid).get();
    final userData = UserModel.fromMap(userDoc.data()!);

    if (userData.referralCodeApply) return false;
    if (userData.myReferralCode == referralCode) return false;

    final refDoc = await _db.collection('referralCoders').doc(referralCode).get();
    if (!refDoc.exists) return false;

    final referrerUid = refDoc.data()!['uid'];

    // Update current user
    await _db.collection('users').doc(uid).update({
      'referredBy': referralCode,
      'referralCodeApply': true,
      'points': FieldValue.increment(2000),
      'totalEarnings': FieldValue.increment(2000),
    });

    // Update referrer
    await _db.collection('users').doc(referrerUid).update({
      'points': FieldValue.increment(2000),
      'totalEarnings': FieldValue.increment(2000),
    });

    return true;
  }

  Future<void> requestWithdrawal(String uid, String upiId, int amount) async {
    await _db.collection('withdrawRequests').add({
      'uid': uid,
      'upiId': upiId,
      'amount': amount.toString(),
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _db.collection('users').doc(uid).update({
      'points': FieldValue.increment(-amount),
    });
  }
}
