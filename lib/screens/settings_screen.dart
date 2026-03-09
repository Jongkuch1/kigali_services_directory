import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_colors.dart';
import '../providers/auth_provider.dart' as ap;
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _locationNotif = true;
  bool _pushNotif = true;
  String _language = 'English';

  static const _languages = ['English', 'French', 'Kinyarwanda'];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _locationNotif = prefs.getBool('locationNotif') ?? true;
      _pushNotif = prefs.getBool('pushNotif') ?? true;
      _language = prefs.getString('language') ?? 'English';
    });
  }

  Future<void> _setLocationNotif(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('locationNotif', val);
    setState(() => _locationNotif = val);
    if (val) {
      await NotificationService().enableLocationNotifications();
    } else {
      await NotificationService().disableLocationNotifications();
    }
  }

  Future<void> _setPushNotif(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pushNotif', val);
    setState(() => _pushNotif = val);
    if (val) {
      await NotificationService().enablePushNotifications();
    } else {
      await NotificationService().disablePushNotifications();
    }
  }

  Future<void> _showLanguagePicker() async {
    final picked = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kNavyLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Select Language',
            style: TextStyle(color: kWhite, fontWeight: FontWeight.w700)),
        content: RadioGroup<String>(
          groupValue: _language,
          onChanged: (v) {
            if (v != null) Navigator.pop(context, v);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _languages
                .map((lang) => RadioListTile<String>(
                      value: lang,
                      title: Text(lang,
                          style: const TextStyle(color: kWhite, fontSize: 14)),
                      activeColor: kGold,
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: kGray)),
          ),
        ],
      ),
    );
    if (picked != null && picked != _language) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', picked);
      setState(() => _language = picked);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Language set to $picked')),
        );
      }
    }
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kNavyLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Privacy & Security',
            style: TextStyle(color: kWhite, fontWeight: FontWeight.w700)),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Data Collection',
                  style: TextStyle(
                      color: kGold,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              SizedBox(height: 4),
              Text(
                'We collect only the data necessary to provide the Kigali City Services directory. '
                'This includes your email address, display name, and any listings or reviews you submit.',
                style: TextStyle(color: kGray, fontSize: 12),
              ),
              SizedBox(height: 12),
              Text('Location Data',
                  style: TextStyle(
                      color: kGold,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              SizedBox(height: 4),
              Text(
                'Location access is used only to show services near you on the map. '
                'It is never stored or shared with third parties.',
                style: TextStyle(color: kGray, fontSize: 12),
              ),
              SizedBox(height: 12),
              Text('Your Rights',
                  style: TextStyle(
                      color: kGold,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              SizedBox(height: 4),
              Text(
                'You can delete your account and all associated data at any time by contacting support. '
                'Listings you created will also be removed.',
                style: TextStyle(color: kGray, fontSize: 12),
              ),
              SizedBox(height: 12),
              Text('Security',
                  style: TextStyle(
                      color: kGold,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              SizedBox(height: 4),
              Text(
                'All data is stored securely using Firebase (Google Cloud). '
                'Passwords are managed by Firebase Authentication and are never stored in plain text.',
                style: TextStyle(color: kGray, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: kGold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<ap.AuthProvider>();
    final user = auth.userProfile;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // Profile card
        Container(
          padding: const EdgeInsets.all(18),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: kGold,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  user?.name.isNotEmpty == true
                      ? user!.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: kNavy,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'User',
                      style: const TextStyle(
                        color: kWhite,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? auth.firebaseUser?.email ?? '',
                      style: const TextStyle(color: kGray, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    if (auth.firebaseUser?.emailVerified == true)
                      Row(
                        children: const [
                          Icon(Icons.check_circle, color: kGreen, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'Email Verified',
                            style: TextStyle(color: kGreen, fontSize: 11),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Notification toggles
        _ToggleRow(
          label: 'Location-Based Notifications',
          subtitle: 'Get alerts for services near you',
          value: _locationNotif,
          onChanged: _setLocationNotif,
        ),
        const SizedBox(height: 8),
        _ToggleRow(
          label: 'Push Notifications',
          subtitle: 'Receive app push notifications',
          value: _pushNotif,
          onChanged: _setPushNotif,
        ),
        const SizedBox(height: 8),
        // Static settings items
        _SettingsRow(
          icon: Icons.language_outlined,
          label: 'Language',
          subtitle: _language,
          onTap: _showLanguagePicker,
        ),
        _SettingsRow(
          icon: Icons.security_outlined,
          label: 'Privacy & Security',
          onTap: _showPrivacyDialog,
        ),
        _SettingsRow(
          icon: Icons.info_outline,
          label: 'About Kigali City Services',
          onTap: () => showAboutDialog(
            context: context,
            applicationName: 'Kigali City Services',
            applicationVersion: '1.0.0',
            applicationLegalese: '© 2026 Kigali City Services',
          ),
        ),
        const SizedBox(height: 8),
        // Sign out
        GestureDetector(
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: kNavyLight,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Text('Sign Out',
                    style: TextStyle(
                        color: kWhite, fontWeight: FontWeight.w700)),
                content: const Text(
                  'Are you sure you want to sign out?',
                  style: TextStyle(color: kGray),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel',
                        style: TextStyle(color: kGray)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Sign Out',
                        style: TextStyle(color: kRed)),
                  ),
                ],
              ),
            );
            if (confirmed == true && context.mounted) {
              context.read<ap.AuthProvider>().signOut();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kRed.withValues(alpha: 0.6)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout, color: kRed, size: 18),
                SizedBox(width: 8),
                Text(
                  'Sign Out',
                  style: TextStyle(
                    color: kRed,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: kWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(color: kGray, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: kGold,
            inactiveTrackColor: kBorder,
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: kGray, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(color: kWhite, fontSize: 14)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: const TextStyle(color: kGold, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: kGray, size: 18),
          ],
        ),
      ),
    );
  }
}