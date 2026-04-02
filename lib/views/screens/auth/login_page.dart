import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_ezzy/core/app_translations.dart';
import '../../../providers/auth_provider.dart';
import '../shell_page.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الرجاء إدخال البريد الإلكتروني وكلمة المرور'.tr)),
      );
      return;
    }

    final success = await authProvider.login(username, password);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const ShellPage()),
        (route) => false,
      );
    } else {
      final errorMsg = authProvider.lastError ?? 'فشل تسجيل الدخول، تأكد من بياناتك'.tr;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFE71D24);
    const bgColor = Color(0xFFF8F9FA);
    const darkText = Color(0xFF1E293B);
    const grayText = Color(0xFF94A3B8);

    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'تسجيل الدخول',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              Text(
                'تسجيل الدخول',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'سجل دخولك لبدء استخدام خدمات الشحن وإدارة\nطلباتك بسهولة'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
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
                    _buildLabel('البريد الالكتروني / رقم الهاتف'.tr),
                    _buildTextField(
                      controller: _usernameController,
                      hint: 'أدخل البريد الالكتروني أو رقم الهاتف'.tr,
                    ),
                    SizedBox(height: 16),
                    _buildLabel('كلمة المرور'),
                    _buildTextField(
                      controller: _passwordController,
                      hint: '••••••••',
                      obscureText: true,
                    ),
                    SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                                builder: (_) => const ForgotPasswordPage()),
                          );
                        },
                        child: Text(
                          'نسيت كلمة المرور؟'.tr,
                          style: TextStyle(
                            color: red,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    FilledButton(
                      onPressed: authProvider.isLoading ? null : _handleLogin,
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
                              'تسجيل الدخول',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                    SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute<void>(
                              builder: (_) => const ShellPage()),
                          (route) => false,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: red,
                        side: const BorderSide(color: red, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'تخطي التسجيل و الدخول ك ضيف'.tr,
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'ليس لديك حساب؟ '.tr,
                          style: TextStyle(
                              color: darkText.withOpacity(0.8),
                              fontWeight: FontWeight.bold),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegisterPage(),
                              ),
                            );
                          },
                          child: Text(
                            'إنشاء حساب جديد'.tr,
                            style: TextStyle(
                              color: red,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.star_border_rounded,
                            color: red, size: 24),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ملحوظة يمكنك انشاء حسابك بعد اختيار الخدمات و اكمال\nعملية الدفع'.tr,
                            style: TextStyle(
                              fontSize: 11,
                              color: darkText.withOpacity(0.6),
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
            fontFamily: 'Cairo',
          ),
          children: const [
            TextSpan(
              text: ' *',
              style: TextStyle(color: Color(0xFFE71D24)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF5F6F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

