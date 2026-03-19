import 'package:flutter/material.dart';

class POBoxPage extends StatelessWidget {
  const POBoxPage({super.key});

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
            'صندوق بريدي',
            style: TextStyle(color: Color(0xFF2C3E50), fontSize: 20, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildWhyPOBoxSection(),
              const SizedBox(height: 32),
              _buildWhatYouGetSection(),
              const SizedBox(height: 32),
              _buildPlansSection(),
              const SizedBox(height: 32),
              _buildFAQSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWhyPOBoxSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Text(
            'لماذا الصندوق البريدي',
            style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 20),
          _buildCheckItem('عنوان شارع حقيقي\n(ليس صندوق بريد تقليدي)'),
          _buildCheckItem('استقبال البريد والطرود من جميع\nشركات الشحن'),
          _buildCheckItem('إدارة البريد أونلاين عبر الموقع'),
          _buildCheckItem('حماية الخصوصية ومنع سرقة\nالبريد'),
          _buildCheckItem('أسعار واضحة وخطط مرنة بدون\nتعقيد'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('احصل علي الباقة', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.red, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatYouGetSection() {
    return Column(
      children: [
        const Text(
          'ماذا تحصل عليه',
          style: TextStyle(color: Color(0xFF2C3E50), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const WhatYouGetSlider(),
      ],
    );
  }

  Widget _buildPlansSection() {
    return Column(
      children: [
        const Text(
          'خطط الصندوق البريدي',
          style: TextStyle(color: Color(0xFF2C3E50), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const PlansSlider(),
      ],
    );
  }

  Widget _buildDot(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? Colors.red : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildFAQSection() {
    return Column(
      children: [
        const Text(
          'الأسئلة الشائعة',
          style: TextStyle(color: Color(0xFF2C3E50), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildFAQItem('هل العنوان حقيقي؟'),
              _buildFAQItem('هل أقدر أستخدمه لتسجيل شركة؟'),
              _buildFAQItem('هل أقدر أستلم من كل شركات الشحن؟'),
              _buildFAQItem('هل في عقد طويل المدى؟', isLast: true),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             _buildDot(false),
             _buildDot(false),
             _buildDot(true),
           ],
         )
      ],
    );
  }

  Widget _buildFAQItem(String title, {bool isLast = false}) {
    return Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: Column(
        children: [
          ExpansionTile(
            title: Text(
              title,
              style: const TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            iconColor: Colors.black87,
            collapsedIconColor: Colors.black87,
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text('هذا النص هو مثال لنص يمكن أن يستبدل في نفس المساحة، لقد تم توليد هذا النص من مولد النص العربى.', style: TextStyle(color: Colors.black54, fontSize: 13)),
              )
            ],
          ),
          if (!isLast)
            Divider(height: 1, color: Colors.grey.shade100, indent: 16, endIndent: 16),
        ],
      ),
    );
  }
}

class WhatYouGetSlider extends StatefulWidget {
  const WhatYouGetSlider({super.key});

  @override
  State<WhatYouGetSlider> createState() => _WhatYouGetSliderState();
}

class _WhatYouGetSliderState extends State<WhatYouGetSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _items = [
    {
      'icon': Icons.email,
      'title': 'استقبال البريد والطرود',
      'description': 'نستقبل بريدك باسمك أو باسم شركتك من\nجميع شركات الشحن المحلية والدولية.',
    },
    {
      'icon': Icons.camera_alt,
      'title': 'صور فورية',
      'description': 'تشاهد صورة واضحة لكل عنصر يتم استلامه\nقبل اتخاذ أي إجراء.',
    },
    {
      'icon': Icons.picture_as_pdf,
      'title': 'مسح ضوئي للمحتوى',
      'description': 'اطلب فتح البريد ومسح محتواه ضوئيًا وتحميله\nبصيغة PDF قابلة للبحث.',
    },
    {
      'icon': Icons.local_shipping,
      'title': 'إعادة توجيه الشحن',
      'description': 'أعد توجيه البريد لأي عنوان داخل بلدك أو دوليًا\nبأسعار تنافسية.',
    },
    {
      'icon': Icons.business,
      'title': 'عنوان احترافي للأعمال',
      'description': 'لتسجيل شركتك، المتاجر الإلكترونية، Google\nMaps، والفواتير.',
    },
    {
      'icon': Icons.delete_outline,
      'title': 'إتلاف أو إعادة تدوير',
      'description': 'أعد توجيه البريد لأي عنوان داخل بلدك أو دوليًا\nبأسعار تنافسية.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item['icon'], color: Colors.red, size: 36),
                    const SizedBox(height: 16),
                    Text(
                      item['title'],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item['description'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.5),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _items.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index ? Colors.red : Colors.grey.shade300,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PlansSlider extends StatefulWidget {
  const PlansSlider({super.key});

  @override
  State<PlansSlider> createState() => _PlansSliderState();
}

class _PlansSliderState extends State<PlansSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _plans = [
    {
      'title': 'الخطة الأساسية',
      'subtitle': '(للأفراد)',
      'features': [
        'استقبال المراسلات باسم شخصي',
        'استخدام العنوان لتسجيل النشاط',
        'عدد عناصر معقول شهرياً',
        'مستخدم واحد',
      ],
    },
    {
      'title': 'خطة الأعمال',
      'subtitle': '(للشركات الصغيرة)',
      'features': [
        'كل مميزات الخطة الأساسية',
        'استقبال المراسلات باسم الشركة',
        'استخدام العنوان لتسجيل النشاط',
        'عدد عناصر أكبر شهرياً',
        'مستخدمون متعددون',
      ],
    },
    {
      'title': 'الخطة المتقدمة',
      'subtitle': '(للشركات الكبيرة)',
      'features': [
        'كل مميزات خطة الأعمال',
        'استقبال المراسلات بلا حدود',
        'مسح ضوئي مجاني للمحتوى',
        'إعادة توجيه الشحن بخصم',
        'عدد مستخدمين غير محدود',
      ],
    },
  ];

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 380, // Adjust height as necessary
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _plans.length,
            itemBuilder: (context, index) {
              final plan = _plans[index];
              final features = plan['features'] as List<String>;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      plan['title'],
                      style: const TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan['subtitle'],
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Column(
                        children: features.map((f) => _buildCheckItem(f)).toList(),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('اشترك الآن', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _plans.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index ? Colors.red : Colors.grey.shade300,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
