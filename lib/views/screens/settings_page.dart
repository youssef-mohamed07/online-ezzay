import 'package:online_ezzy/core/app_translations.dart';
import 'package:flutter/material.dart';

import 'change_password_page.dart';
import 'privacy_policy_page.dart';
import 'terms_of_service_page.dart';
import 'contact_us_page.dart';
import 'about_app_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'الإعدادات'.tr,
            style: TextStyle(
              color: Color(0xFF2C3E50),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader('إعدادات التطبيق'.tr),
            _buildSwitchTile('الإشعارات'.tr, _notificationsEnabled, (val) {
              setState(() => _notificationsEnabled = val);
            }),
            _buildComingSoonTile('تغيير اللغة'.tr, 'قريباً'.tr, Icons.language),

            SizedBox(height: 24),
            _buildSectionHeader('المزيد'.tr),
            _buildListTile(
              'تغيير كلمة المرور'.tr,
              null,
              Icons.lock_outline,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
                );
              },
            ),
            _buildListTile(
              'سياسة الخصوصية'.tr,
              null,
              Icons.privacy_tip_outlined,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                );
              },
            ),
            _buildListTile(
              'شروط الخدمة'.tr,
              null,
              Icons.description_outlined,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TermsOfServicePage()),
                );
              },
            ),
            _buildListTile(
              'تواصل معنا'.tr,
              null,
              Icons.contact_support_outlined,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ContactUsPage()),
                );
              },
            ),
            _buildListTile(
              'حول التطبيق'.tr,
              'الإصدار 1.0.0'.tr,
              Icons.info_outline,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutAppPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        value: value,
        activeColor: Colors.red,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildComingSoonTile(String title, String badgeText, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        enabled: false,
        leading: Icon(icon, color: Colors.grey),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        subtitle: Text(
          'ستتوفر الميزة في تحديث قادم'.tr,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            badgeText,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(
    String title,
    String? trailingText,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: trailingText != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    trailingText,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_back_ios, size: 14, color: Colors.grey),
                ],
              )
            : Icon(Icons.arrow_back_ios, size: 14, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
