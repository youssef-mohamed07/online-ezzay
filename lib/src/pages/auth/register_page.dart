import 'package:flutter/material.dart';

import 'auth_layout.dart';
import 'login_page.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFE71D24);
    const bgColor = Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'إنشاء حساب',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            const Text(
              'إنشاء حساب',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'أنشئ حسابك واكمل عملية الشراء',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLabel('الاسم الكامل'),
                  _buildTextField(hint: 'الاسم الكامل'),
                  const SizedBox(height: 16),
                  _buildLabel('البريد الإلكتروني'),
                  _buildTextField(
                    hint: 'example@email.com',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('رقم الهاتف'),
                  _buildTextField(
                    hint: '5xxxxxxxx',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('عنوان الشارع / الحي'),
                  _buildTextField(
                    hint: 'أدخل عنوانك',
                    suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black45),
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('المدينة'),
                  _buildTextField(
                    hint: 'أدخل عنوانك', // To match mockup
                    suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black45),
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('إنشاء كلمة مرور'),
                  _buildTextField(
                    hint: 'اختر المدينة', // To match mockup "اختار المدينة" text exactly, wait they misspelled it in the design? Yes.
                    obscureText: true,
                    suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black45),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'يجب أن تحتوي كلمة المرور على 8 أحرف على الأقل',
                    style: TextStyle(fontSize: 11, color: Colors.black38),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم إنشاء الحساب بنجاح')),
                      );
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(builder: (_) => const LoginPage()),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                      shadowColor: red.withOpacity(0.4),
                    ),
                    child: const Text(
                      'إنشاء الحساب و الانتقال للدفع',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'لديك حساب بالفعل؟',
              style: TextStyle(
                color: Colors.black45,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(builder: (_) => const LoginPage()),
                );
              },
              child: const Text(
                'سجل الدخول',
                style: TextStyle(
                  color: red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 32), // Add extra space for bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            fontFamily: 'Cairo', // Assuming an Arabic font is used
          ),
          children: const [
            TextSpan(
              text: ' *',
              style: TextStyle(color: Color(0xFFE71D24)), // Red asterisk
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      obscureText: obscureText,
      keyboardType: keyboardType,
      textAlign: TextAlign.right, // Center or right depending on requirements, right aligns with mockup
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF5F6F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
