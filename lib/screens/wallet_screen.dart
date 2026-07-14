import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/database_service.dart';
import '../services/ad_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  BannerAd? _bannerAd;
  final _amountController = TextEditingController();
  final _upiController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() {}),
        onAdFailedToLoad: (ad, err) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _amountController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  void _showWithdrawDialog() {
    final user = Provider.of<UserProvider>(context, listen: false).user!;
    _upiController.text = user.upiId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Money'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _upiController,
              decoration: const InputDecoration(labelText: 'UPI ID'),
            ),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (in points)'),
            ),
            const Text('Min withdrawal: 100,000 points (₹100)'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = int.tryParse(_amountController.text) ?? 0;
              if (amount < 100000) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Min withdrawal is 100,000 points')));
                return;
              }
              if (amount > user.points) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient balance')));
                return;
              }
              if (_upiController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter UPI ID')));
                return;
              }

              await DatabaseService().requestWithdrawal(user.uid, _upiController.text, amount);
              if (mounted) {
                Provider.of<UserProvider>(context, listen: false).fetchUser(user.uid);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal request submitted!')));
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: Column(
        children: [
          if (_bannerAd != null)
            SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              width: _bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          const SizedBox(height: 20),
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Text('Current Balance', style: TextStyle(fontSize: 18)),
                  Text('${user.points} Points', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
                  Text('≈ ₹${(user.points / 1000).toStringAsFixed(2)}', style: const TextStyle(fontSize: 20)),
                ],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _showWithdrawDialog,
            child: const Text('Withdraw Funds'),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
