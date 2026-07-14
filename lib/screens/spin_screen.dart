import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/ad_service.dart';

class SpinScreen extends StatefulWidget {
  const SpinScreen({super.key});

  @override
  State<SpinScreen> createState() => _SpinScreenState();
}

class _SpinScreenState extends State<SpinScreen> {
  final StreamController<int> _selected = StreamController<int>();
  bool _isSpinning = false;
  RewardedAd? _rewardedAd;
  final List<int> _items = [10, 25, 50, 100, 10, 25, 50, 100];

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();
  }

  void _loadRewardedAd() {
    AdService.loadRewardedAd(onAdLoaded: (ad) {
      setState(() => _rewardedAd = ad);
    });
  }

  @override
  void dispose() {
    _selected.close();
    _rewardedAd?.dispose();
    super.dispose();
  }

  int _lastIndex = 0;

  void _handleSpin() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user!.spinsToday >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daily spin limit (5) reached!')),
      );
      return;
    }

    setState(() {
      _isSpinning = true;
      _lastIndex = Random().nextInt(_items.length);
    });
    _selected.add(_lastIndex);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Spin & Earn')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Points: ${user.points}'),
                Text('Spins left: ${5 - user.spinsToday}'),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FortuneWheel(
                selected: _selected.stream,
                items: [
                  for (var item in _items) FortuneItem(child: Text('$item')),
                ],
                onAnimationEnd: () {
                  setState(() => _isSpinning = false);
                  _onSpinFinished();
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSpinning || user.spinsToday >= 5 ? null : _handleSpin,
            style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
            child: const Text('SPIN NOW'),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  void _onSpinFinished() {
    final points = _items[_lastIndex];
    if (_rewardedAd != null) {
      _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
        _givePoints(points);
        _loadRewardedAd();
      });
    } else {
      // If ad not loaded, give points anyway but load next one
      _givePoints(points);
      _loadRewardedAd();
    }
  }

  void _givePoints(int points) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.addPoints(points);
    await userProvider.incrementSpin();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You won $points points!')),
      );
    }
  }
}
