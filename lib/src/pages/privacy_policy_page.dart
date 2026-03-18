import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'سياسة الخصوصية',
            style: TextStyle(color: Color(0xFF2C3E50), fontSize: 20, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('المقدمة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              SizedBox(height: 8),
              Text('نحن في أونلاين إيزي نحرص على حماية خصوصيتك ومعلوماتك الشخصية. هذه السياسة تشرح كيف نجمع، ونستخدم، ونحمي بياناتك حين استخدامك لخدماتنا وموقعنا.', style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black54)),
              SizedBox(height: 24),
              Text('جمع المعلومات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              SizedBox(height: 8),
              Text('قد نقوم بجمع معلوماتك الشخصية مثل الاسم، والعنوان، ورقم الهاتف، والبريد الإلكتروني وذلك بغرض تقديم خدماتنا بأفضل شكل ممكن، وعند إنشاء حساب أو تسجيل الدخول.', style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black54)),
              SizedBox(height: 24),
              Text('استخدام المعلومات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              SizedBox(height: 8),
              Text('تستخدم المعلومات فقط لتحسين تجربتك، معالجة الطلبات، التواصل معك حول الشحنات، وتقديم دعم ومساعدة أفضل لك بشكل مستمر.', style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}
