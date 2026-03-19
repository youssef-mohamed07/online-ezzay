import 'package:online_ezzy/core/app_translations.dart';
import 'package:flutter/material.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

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
            'تواصل معنا'.tr,
            style: TextStyle(color: Color(0xFF2C3E50), fontSize: 20, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('نحن هنا لمساعدتك!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
            SizedBox(height: 8),
            Text('يمكنك التواصل معنا عبر الطرق التالية أو عبر إرسال رسالة مباشرة من التطبيق.', style: TextStyle(color: Colors.black54, fontSize: 14)),
            SizedBox(height: 32),
            _buildContactMethod(Icons.phone_in_talk_outlined, 'رقم الهاتف'.tr, '+966 9200xxxxx'),
            SizedBox(height: 16),
            _buildContactMethod(Icons.email_outlined, 'البريد الإلكتروني', 'support@onlineezzay.com'),
            SizedBox(height: 16),
            _buildContactMethod(Icons.location_on_outlined, 'العنوان الرئيسي', 'المملكة العربية السعودية، الرياض'),
            SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.chat_bubble_outline, color: Colors.white),
              label: Text('بدء محادثة مباشرة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactMethod(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.red.withOpacity(0.1),
            radius: 24,
            child: Icon(icon, color: Colors.red),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 13, decoration: TextDirection.ltr == TextDirection.ltr ? null : null, fontFeatures: [FontFeature.tabularFigures()])), // tabular for numbers
              ],
            ),
          ),
        ],
      ),
    );
  }
}
