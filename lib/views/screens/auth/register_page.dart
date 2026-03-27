import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_ezzy/core/app_translations.dart';
import '../../../providers/auth_provider.dart';

import 'auth_layout.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Using email as username for now as the API takes username, email, password
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الرجاء تعبئة الحقول الأساسية'.tr)),
      );
      return;
    }

    final success = await authProvider.register(name, email, password);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إنشاء الحساب بنجاح'.tr)),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الإنشاء. حاول مجدداً'.tr)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFE71D24);
    const bgColor = Color(0xFFF8F9FA);
    
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
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
            Text(
              'إنشاء حساب',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'أنشئ حسابك واكمل عملية الشراء'.tr,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 24),
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
                  _buildTextField(
                    controller: _nameController,
                    hint: 'الاسم الكامل',
                  ),
                  SizedBox(height: 16),
                  _buildLabel('البريد الإلكتروني'),
                  _buildTextField(
                    controller: _emailController,
                    hint: 'example@email.com',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 16),
                  _buildLabel('رقم الهاتف'.tr),
                  _buildTextField(
                    controller: _phoneController,
                    hint: '5xxxxxxxx',
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 16),
                  _buildLabel('عنوان الشارع / الحي'.tr),
                  _buildTextField(
                    hint: 'أدخل عنوانك'.tr,
                    suffixIcon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black45),
                  ),
                  SizedBox(height: 16),
                  _buildLabel('المدينة'.tr),
                  _buildTextField(
                    hint: 'أدخل عنوانك'.tr, // To match mockup
                    suffixIcon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black45),
                  ),
                  SizedBox(height: 16),
                  _buildLabel('إنشاء كلمة مرور'.tr),
                  _buildTextField(
                    controller: _passwordController,
                    hint: '••••••••',
                    obscureText: true,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'يجب أن تحتوي كلمة المرور على 8 أحرف على الأقل'.tr,
                    style: TextStyle(fontSize: 11, color: Colors.black38),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  FilledButton(
                    onPressed: authProvider.isLoading ? null : _handleRegister,
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
                    child: authProvider.isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                      'إنشاء الحساب و الانتقال للدفع'.tr,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            Text(
              'لديك حساب بالفعل؟'.tr,
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
              child: Text(
                'سجل الدخول'.tr,
                style: TextStyle(
                  color: red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 32), // Add extra space for bottom nav
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
    TextEditingController? controller,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
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
