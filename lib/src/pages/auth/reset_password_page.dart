import 'package:flutter/material.dart';

import 'auth_layout.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFE71D24);

    return AuthLayout(
      headerTitle: 'كلمة مرور جديدة',
      showBackButton: true,
      title: 'تعيين كلمة مرور جديدة',
      subtitle: 'اختر كلمة مرور قوية لحماية حسابك.',
      centered: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthTextField(
            label: 'كلمة المرور الجديدة',
            hint: '••••••••',
            obscureText: true,
          ),
          const SizedBox(height: 12),
          const AuthTextField(
            label: 'تأكيد كلمة المرور',
            hint: '••••••••',
            obscureText: true,
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تحديث كلمة المرور بنجاح')),
              );
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text('حفظ كلمة المرور'),
          ),
        ],
      ),
    );
  }
}
