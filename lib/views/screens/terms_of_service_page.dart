import 'package:online_ezzy/core/app_translations.dart';
import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

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
            'شروط الخدمة'.tr,
            style: TextStyle(color: Color(0xFF2C3E50), fontSize: 20, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('المقدمة والشروط العامة'.tr, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              SizedBox(height: 8),
              Text('باستخدامك لتطبيق أونلاين إيزي، فإنك توافق على جميع الشروط والأحكام الموضحة هنا. يُرجى قراءة هذه الشروط بعناية قبل استخدام التطبيق.'.tr, style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black54)),
              SizedBox(height: 24),
              Text('الالتزامات والمسؤوليات'.tr, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              SizedBox(height: 8),
              Text('يجب على المستخدم تقديم معلومات صحيحة ودقيقة عند إنشاء الحساب والالتزام بكافة القوانين المحلية عند إرسال الشحنات والطرود.'.tr, style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black54)),
              SizedBox(height: 24),
              Text('التعديلات على الشروط'.tr, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              SizedBox(height: 8),
              Text('يحتفظ تطبيق أونلاين إيزي بالحق في تعديل هذه الشروط في أي وقت، وسيتم إشعار المستخدمين بأي تغييرات جوهرية في حينه.'.tr, style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}
