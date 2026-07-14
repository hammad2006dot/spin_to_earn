import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/ad_service.dart';
import 'spin_screen.dart';
import 'wallet_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  InterstitialAd? _interstitialAd;
  int _tabSwitchCount = 0;

  final List<Widget> _screens = [
    const SpinScreen(),
    const WalletScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadInterstitialAd();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Provider.of<UserProvider>(context, listen: false).fetchUser(user.uid);
      }
    });
  }

  void _loadInterstitialAd() {
    AdService.loadInterstitialAd(onAdLoaded: (ad) {
      _interstitialAd = ad;
    });
  }

  void _showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _loadInterstitialAd();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _tabSwitchCount++;
          });
          if (_tabSwitchCount % 3 == 0) { // Show ad every 3 tab switches
            _showInterstitialAd();
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.refresh), label: 'Spin'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
