import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  final DatabaseService _dbService = DatabaseService();

  UserModel? get user => _user;

  Future<void> fetchUser(String uid) async {
    _user = await _dbService.getUser(uid);
    if (_user != null) {
      await _checkDailyBonus();
      await _checkDailySpinReset();
    }
    notifyListeners();
  }

  Future<void> _checkDailyBonus() async {
    if (_user == null) return;

    final now = DateTime.now();
    final lastLogin = _user!.lastLoginDate;

    if (now.day != lastLogin.day || now.month != lastLogin.month || now.year != lastLogin.year) {
      // Different day
      final bonus = (Random().nextInt(2001) + 1000); // 1000 to 3000 points
      await _dbService.updateLastLogin(_user!.uid, dailyBonus: bonus);
      
      // Refresh user
      _user = await _dbService.getUser(_user!.uid);
    }
  }

  Future<void> _checkDailySpinReset() async {
    if (_user == null) return;

    final now = DateTime.now();
    final lastSpin = _user!.lastSpinDate;

    if (now.day != lastSpin.day || now.month != lastSpin.month || now.year != lastSpin.year) {
      await _dbService.updateSpinCount(_user!.uid, 0);
      _user = await _dbService.getUser(_user!.uid);
    }
  }

  Future<void> addPoints(int points) async {
    if (_user == null) return;
    await _dbService.updatePoints(_user!.uid, points);
    await fetchUser(_user!.uid);
  }

  Future<void> incrementSpin() async {
    if (_user == null) return;
    await _dbService.updateSpinCount(_user!.uid, _user!.spinsToday + 1);
    await fetchUser(_user!.uid);
  }

  Future<void> updateUpi(String upiId) async {
    if (_user == null) return;
    await _dbService.updateUpiId(_user!.uid, upiId);
    await fetchUser(_user!.uid);
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
