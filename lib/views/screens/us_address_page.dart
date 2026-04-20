import 'package:online_ezzy/core/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:online_ezzy/core/api_service.dart';

import 'contact_us_page.dart';

class UsAddressPage extends StatefulWidget {
  const UsAddressPage({Key? key}) : super(key: key);

  @override
  State<UsAddressPage> createState() => _UsAddressPageState();
}

class _UsAddressPageState extends State<UsAddressPage> {
  String? _shipFrom;
  String? _deliverTo;
  String? _service;
  String _weightUnit = 'كجم'.tr;
  bool _isSubmitting = false;

  Future<void> _submitAddressRequest() async {
    if (_shipFrom == null || _deliverTo == null || _service == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('من فضلك أكمل بيانات الشحنة أولاً')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final response = await ApiService.contactUs({
      'name': 'طلب عنوان امريكي',
      'email': 'address.request@onlineezzy.app',
      'message':
          'طلب الحصول على عنوان امريكي وإتمام الدفع.\nالشحن من: $_shipFrom\nالتسليم إلى: $_deliverTo\nالخدمة: $_service\nوحدة الوزن: $_weightUnit',
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
            'عنوان الامريكي'.tr,
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
                    'https://images.pexels.com/photos/466685/pexels-photo-466685.jpeg?auto=compress&cs=tinysrgb&w=600',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 24),

              // الفورم
              Container(
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
                    _buildLabel('الشحن من'.tr),
                    _buildDropdown(
                      hint: 'الشحن من'.tr,
                      value: _shipFrom,
                      items: ['أمريكا'.tr, 'الصين'.tr, 'الإمارات'.tr],
                      onChanged: (val) => setState(() => _shipFrom = val),
                    ),
                    SizedBox(height: 16),

                    _buildLabel('التسليم الي'.tr),
                    _buildDropdown(
                      hint: 'التسليم الي'.tr,
                      value: _deliverTo,
                      items: ['السعودية'.tr, 'مصر'.tr, 'الأردن'.tr],
                      onChanged: (val) => setState(() => _deliverTo = val),
                    ),
                    SizedBox(height: 16),

                    _buildLabel('اختر الخدمة'.tr),
                    _buildDropdown(
                      hint: 'DHL',
                      value: _service,
                      items: ['DHL', 'Aramex', 'FedEx'],
                      onChanged: (val) => setState(() => _service = val),
                    ),
                    SizedBox(height: 16),

                    _buildLabel('وزن الحزمة'.tr),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Icon(
                                  Icons.unfold_more,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                Text(
                                  '1',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: _buildDropdown(
                            hint: 'كجم'.tr,
                            value: _weightUnit,
                            items: ['كجم'.tr, 'باوند'.tr],
                            onChanged: (val) =>
                                setState(() => _weightUnit = val ?? 'كجم'.tr),
                          ),
                        ),
                      ],
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
                  ],
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, right: 4.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E3A5F),
        ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(
            hint,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
          value: value,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.black),
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
