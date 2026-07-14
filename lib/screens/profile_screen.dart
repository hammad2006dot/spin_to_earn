import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/ad_service.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  BannerAd? _bannerAd;
  final _upiController = TextEditingController();
  final _referralController = TextEditingController();

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
    _upiController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    _upiController.text = user.upiId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthService>(context, listen: false).signOut();
              userProvider.clearUser();
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_bannerAd != null)
              SizedBox(
                height: _bannerAd!.size.height.toDouble(),
                width: _bannerAd!.size.width.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            const SizedBox(height: 20),
            const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
            const SizedBox(height: 10),
            Text(user.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(user.email, style: const TextStyle(color: Colors.grey)),
            const Divider(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('UPI ID', style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _upiController,
                          decoration: const InputDecoration(hintText: 'Enter UPI ID'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.save),
                        onPressed: () async {
                          await userProvider.updateUpi(_upiController.text);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UPI ID updated')));
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text('Your Referral Code', style: TextStyle(fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(user.myReferralCode, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: user.myReferralCode));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied!')));
                          },
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (!user.referralCodeApply) ...[
                    const Text('Have a Referral Code?', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _referralController,
                            decoration: const InputDecoration(hintText: 'Enter code'),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final success = await DatabaseService().applyReferralCode(user.uid, _referralController.text);
                            if (success) {
                              await userProvider.fetchUser(user.uid);
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referral applied! ₹2 added')));
                            } else {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid code or already applied')));
                            }
                          },
                          child: const Text('Apply'),
                        )
                      ],
                    ),
                  ] else ...[
                    const Text('Referral Applied ✓', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
