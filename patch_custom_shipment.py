import re

with open('lib/views/screens/custom_shipment_page.dart', 'r') as f:
    text = f.read()

new_btn = """        // زر الإضافة للسلة ثابت بالأسفل
        bottomSheet: Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[50],
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () async {
                bool hasUnconfirmed = parcels.any((p) => !p.isConfirmed);
                if (hasUnconfirmed) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء تأكيد جميع الطرود أولاً')));
                  return;
                }
                if (parcels.isEmpty) return;

                final data = {
                  'total': grandTotal,
                  'parcels': parcels.map((p) => {
                    'length': p.lengthController.text,
                    'width': p.widthController.text,
                    'height': p.heightController.text,
                    'volume': p.volume,
                  }).toList(),
                };
                
                showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                final res = await ApiService.requestShipment(data);
                if (mounted) Navigator.pop(context); // loading

                if (res != null) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال طلب الشحنة بنجاح')));
                  if (mounted) Navigator.pop(context);
                } else {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل في إرسال طلب الشحنة')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'طلب شحنة: \\$${grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),"""

text = re.sub(r'        // زر الإضافة للسلة ثابت بالأسفل.*?        bottomNavigationBar:', new_btn + '\n        // لمحاكاة شريط التنقل السفلي الموجود في الصورة\n        bottomNavigationBar:', text, flags=re.DOTALL)
text = text.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:online_ezzy/core/api_service.dart';")

with open('lib/views/screens/custom_shipment_page.dart', 'w') as f:
    f.write(text)
