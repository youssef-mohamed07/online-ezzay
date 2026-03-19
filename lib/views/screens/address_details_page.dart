import 'package:flutter/material.dart';

class AddressDetailsPage extends StatefulWidget {
  final String title;

  const AddressDetailsPage({Key? key, required this.title}) : super(key: key);

  @override
  State<AddressDetailsPage> createState() => _AddressDetailsPageState();
}

class _AddressDetailsPageState extends State<AddressDetailsPage> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
            widget.title,
            style: const TextStyle(
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
                    'https://images.pexels.com/photos/196667/pexels-photo-196667.jpeg?auto=compress&cs=tinysrgb&w=600',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // الكارت الذي يحتوي على الـ PageView
              Container(
                height: 480, // ارتفاع ثابت ليستوعب الكارت
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (int index) {
                    setState(() {
                      _currentPageIndex = index;
                    });
                  },
                  children: [
                    _buildPackageDetailsCard(
                      title: 'الحزمة التجريبية',
                      price: '2.5\$',
                      subtitle: 'لكل شحنة',
                      features: [
                        'تتيح لك الشراء حتى 3 طرود فقط',
                        'استخدام لمرة واحدة، ينتهي بعد إتمام 3 طلبات',
                        'استلام طلباتك وتجهيزها بعناية',
                        'إشعارات فورية بحالة الشحنات',
                        'تتبع الشحنات خطوة بخطوة',
                        'دعم سريع عبر واتساب على مدار الساعة',
                        'تخزين مجاني لمدة 3 أشهر لاختيار وقت الشحن الأنسب',
                      ],
                    ),
                    _buildPackageDetailsCard(
                      title: 'الباقة المتقدمة',
                      price: '10\$',
                      subtitle: 'شهرياً',
                      features: [
                        'عدد غير محدود من الطرود',
                        'تجميع الطرود لتوفير تكلفة الشحن',
                        'تخزين مجاني لمدة 6 أشهر',
                        'أولوية في الدعم الفني',
                      ],
                    ),
                    _buildPackageDetailsCard(
                      title: 'الباقة الاحترافية',
                      price: '25\$',
                      subtitle: 'شهرياً',
                      features: [
                        'جميع مميزات الباقة المتقدمة',
                        'تصوير مجاني للشحنات',
                        'إعادة تغليف مجانية',
                        'دعم مخصص VIP',
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              // مؤشرات الـ PageView (Dots)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPageIndex == index ? 8 : 6,
                    height: _currentPageIndex == index ? 8 : 6,
                    decoration: BoxDecoration(
                      color: _currentPageIndex == index ? Colors.red : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackageDetailsCard({
    required String title,
    required String price,
    required String subtitle,
    required List<String> features,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: features
                  .map((feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                feature,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF1E3A5F),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // احصل على الباقة
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'احصل علي الباقة',
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
    );
  }
}
