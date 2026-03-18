import 'package:flutter/material.dart';

import '../data/real_images.dart';

class TrackPage extends StatelessWidget {
  const TrackPage({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _TimelineItem('تم إنشاء الشحنة', '16 مارس 08:15', true),
      _TimelineItem('الفرز في ميناء الإسكندرية', '16 مارس 14:10', true),
      _TimelineItem('التخليص الجمركي', '17 مارس 06:40', true),
      _TimelineItem('خروج للتسليم النهائي', 'متوقع 18 مارس 13:30', false),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 145,
                width: double.infinity,
                child: Image.network(
                  RealImages.trackHero,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('تتبع الشحنة', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text(
              'استخدم رقم الشحنة لمتابعة المسار وموعد الوصول ونقاط التحديث.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'رقم الشحنة', hintText: 'ادخل رقم الشحنة (مثال: EZ-94012)', floatingLabelBehavior: FloatingLabelBehavior.auto,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('تتبع'),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                filled: true,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الشحنة EZ-94012',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      'ميناء الإسكندرية    القاهرة مصر',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    const LinearProgressIndicator(
                      value: 0.68,
                      minHeight: 10,
                      valueColor: AlwaysStoppedAnimation(Color(0xFFE71D24)),
                    ),
                    const SizedBox(height: 8),
                    Text('اكتمل 68%  موعد الوصول: 18 مارس 13:30'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('الخط الزمني للمسار', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...steps.map((item) => _TimelineTile(item: item)),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem {
  const _TimelineItem(this.title, this.subtitle, this.isDone);
  final String title;
  final String subtitle;
  final bool isDone;
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.item});

  final _TimelineItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.isDone ? const Color(0xFFE71D24) : const Color(0xFF9AAEC1);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: item.isDone ? color : Colors.white,
                border: Border.all(color: color, width: 2),
                shape: BoxShape.circle,
              ),
            ),
            Container(width: 2, height: 54, color: const Color(0xFFD7E1EA)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(item.subtitle),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
