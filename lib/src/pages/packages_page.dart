import 'package:flutter/material.dart';
import 'custom_shipment_page.dart';

class PackagesPage extends StatelessWidget {
  const PackagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: const Text(
            'طلب توصيل',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'اختر الباقة المناسبة لك',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'اختر الباقة المناسبة لتوصيل طرودك',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 32),
              _buildPackageCard(
                imageUrl: 'lib/assets/images/home/اطلب توصيل.png',
                title: 'باقة 3 طرود',
                subtitle: 'مثالية للشحنات الصغيرة والبسيطة',
                features: [
                  'مرونة كاملة في عدد الطرود',
                  'تتبع الشحنة لحظة بلحظة',
                  'دعم فني مخصص على مدار الساعة',
                ],
              ),
              const SizedBox(height: 20),
              _buildPackageCard(
                imageUrl: 'lib/assets/images/home/تتبع شحنتك.png',
                title: 'باقة من 4 إلى 24 طرد',
                subtitle: 'أفضل خيار للشحنات المتوسطة.',
                features: [
                  'تكلفة أقل لكل طرد',
                  'تتبع كامل للشحنات',
                  'إدارة الشحنات بسهولة',
                ],
              ),
              const SizedBox(height: 20),
              _buildPackageCard(
                imageUrl: 'lib/assets/images/home/العناوين.png',
                title: 'باقة مخصصة',
                subtitle: 'تحكم كامل في عدد الطرود والتكلفة.',
                features: [
                  'تحديد عدد الطرود بحرية',
                  'حساب التكلفة تلقائيا',
                  'إحصائيات الشحنة',
                ],
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CustomShipmentPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackageCard({
    required String imageUrl,
    required String title,
    required String subtitle,
    required List<String> features,
    VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image Header
          Container(
            height: 180,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Image.asset(imageUrl, fit: BoxFit.contain),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Features list
                ...features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: Color(0xFFE71D24),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF334155),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onPressed ?? () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE71D24),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'احصل علي الباقة',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
