import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'nexyplanet@gmail.com',
      queryParameters: {
        'subject': 'Feedback or Bug Report',
      },
    );

    try {
      if (!await launchUrl(emailLaunchUri)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to open email client')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to open email client')),
        );
      }
    }
  }

  Widget _buildSettingItem({
    required String title,
    required IconData icon,
    Widget? trailing,
    bool showDivider = true,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.blue),
          title: Text(title),
          trailing: trailing ?? const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
        if (showDivider) const Divider(height: 1, indent: 56),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text('General',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                )),
          ),
          _buildSettingItem(
            icon: Icons.dark_mode,
            title: 'Appearance',
            trailing: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Follow System', style: TextStyle(color: Colors.grey)),
                SizedBox(width: 4),
                // Icon(Icons.chevron_right),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 24, bottom: 8),
            child: Text('About',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                )),
          ),
          _buildSettingItem(
            icon: Icons.info_outline,
            title: 'Version',
            trailing: const Text('1.0.0', style: TextStyle(color: Colors.grey)),
          ),
          _buildSettingItem(
            icon: Icons.mail_outline,
            title: 'Contact Us',
            onTap: () => _launchEmail(context),
          ),
          // _buildSettingItem(
          //   icon: Icons.privacy_tip_outlined,
          //   title: 'Privacy Policy',
          //   showDivider: false,
          // ),
        ],
      ),
    );
  }
}
