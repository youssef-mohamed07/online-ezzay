import 'package:online_ezzy/core/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:online_ezzy/core/api_service.dart';

import 'contact_us_page.dart';

class CnAddressPage extends StatefulWidget {
  const CnAddressPage({Key? key}) : super(key: key);

  @override
  State<CnAddressPage> createState() => _CnAddressPageState();
}

class _CnAddressPageState extends State<CnAddressPage> {
  String? _weightVal;
  String? _insuranceVal;
  bool _isSubmitting = false;

  Future<void> _submitAddressRequest() async {
    if (_weightVal == null || _insuranceVal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('من فضلك اختر الوزن والتأمين أولاً')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final response = await ApiService.contactUs({
      'name': 'طلب عنوان صيني',
      'email': 'address.request@onlineezzy.app',
      'message':
          'طلب الحصول على عنوان صيني وإتمام الدفع.\nالوزن المتوقع: $_weightVal\nنوع التأمين: $_insuranceVal',
    });

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (response != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال الطلب بنجاح. تواصل معنا لإتمام الدفع.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تعذر إرسال الطلب الآن. يمكنك التواصل مباشرة لإتمام الدفع.',
          ),
        ),
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ContactUsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'عنوان الصيني',
            style: TextStyle(
              color: Color(0xFF1E3A5F),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // صورة العنوان
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    'https://images.pexels.com/photos/17233267/pexels-photo-17233267.jpeg?auto=compress&cs=tinysrgb&w=600',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 24),

              // الفورم - الخطوة 1
              _buildStepCard(
                stepNumber: '1',
                title: 'اختر وزن الشحنة المتوقع',
                child: _buildDropdown(
                  hint: 'أقل من 1 كجم',
                  value: _weightVal,
                  items: ['أقل من 1 كجم', 'من 1 إالي 5 كجم', 'أكثر من 5 كجم'],
                  onChanged: (val) => setState(() => _weightVal = val),
                ),
              ),

              SizedBox(height: 16),

              // الفورم - الخطوة 2
              _buildStepCard(
                stepNumber: '2',
                title: 'تأمين الشحنة',
                child: _buildDropdown(
                  hint: 'بدون تأمين',
                  value: _insuranceVal,
                  items: ['بدون تأمين', 'تأمين جزئي', 'تأمين شامل'],
                  onChanged: (val) => setState(() => _insuranceVal = val),
                ),
              ),

              SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitAddressRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'احصل على العنوان وادفع الآن'.tr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required String stepNumber,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    stepNumber,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(
            hint,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          value: value,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
