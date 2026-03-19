import 'package:online_ezzy/core/app_translations.dart';
import 'package:flutter/material.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

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
            'حول التطبيق'.tr,
            style: TextStyle(color: Color(0xFF2C3E50), fontSize: 20, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Icon(Icons.local_shipping_outlined, color: Colors.white, size: 50),
              ),
              SizedBox(height: 24),
              Text('أونلاين إيزي'.tr, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
              SizedBox(height: 8),
              Text('الإصدار 1.0.0'.tr, style: TextStyle(fontSize: 16, color: Colors.grey)),
              SizedBox(height: 32),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'أفضل تطبيق لتتبع وإدارة شحناتك وطردك بكل سهولة وأمان.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
