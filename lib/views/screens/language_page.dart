import 'package:online_ezzy/core/app_translations.dart';
import 'package:flutter/material.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  String _selectedLanguage = 'ar';

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
            'اللغة'.tr,
            style: TextStyle(color: Color(0xFF2C3E50), fontSize: 20, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildLanguageOption('العربية'.tr, 'ar'),
            _buildLanguageOption('English', 'en'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String title, String value) {
    bool isSelected = _selectedLanguage == value;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? Colors.red : Colors.transparent, width: 2),
      ),
      child: ListTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? Colors.red : Colors.black87)),
        trailing: isSelected ? Icon(Icons.check_circle, color: Colors.red) : null,
        onTap: () {
          setState(() {
            _selectedLanguage = value;
          });
        },
      ),
    );
  }
}
