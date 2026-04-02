import 'package:online_ezzy/core/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_ezzy/providers/auth_provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.userData != null) {
        final firstName = auth.userData!['first_name'] ?? '';
        final lastName = auth.userData!['last_name'] ?? '';
        _fullNameController.text = '$firstName $lastName'.trim();
        
        _emailController.text = auth.userData!['email'] ?? '';
        
        // Sometimes WooCommerce stores phone in billing
        final billing = auth.userData!['billing'];
        if (billing != null && billing is Map) {
          _phoneController.text = billing['phone'] ?? '';
        }
      }
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.userData == null || auth.userData!['id'] == null) return;
    
    final userId = auth.userData!['id'].toString();
    
    final nameParts = _fullNameController.text.trim().split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    
    final data = {
      'first_name': firstName,
      'last_name': lastName,
      'email': _emailController.text.trim(),
      'billing': {
        'first_name': firstName,
        'last_name': lastName,
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
      }
    };
    
    final success = await auth.updateCustomerDetails(userId, data);
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث البيانات بنجاح')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.lastError ?? 'حدث خطأ أثناء تحديث البيانات')),
      );
    }
  }

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
            'تعديل البيانات',
            style: TextStyle(color: Color(0xFF2C3E50), fontSize: 20, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: auth.userData != null && auth.userData!['avatar_url'] != null
                            ? NetworkImage(auth.userData!['avatar_url'])
                            : null,
                        child: auth.userData == null || auth.userData!['avatar_url'] == null
                            ? const Icon(Icons.person, size: 55, color: Colors.white)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.red,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            onPressed: () {},
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildTextField('الاسم الكامل', _fullNameController),
                const SizedBox(height: 16),
                _buildTextField('البريد الإلكتروني', _emailController, TextInputType.emailAddress),
                const SizedBox(height: 16),
                _buildTextField('رقم الهاتف'.tr, _phoneController, TextInputType.phone),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('حفظ التعديلات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            );
          }
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, [TextInputType? keyboardType]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
