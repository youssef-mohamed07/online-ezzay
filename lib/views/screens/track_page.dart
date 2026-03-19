import 'package:online_ezzy/core/app_translations.dart';
import 'package:flutter/material.dart';

import 'package:online_ezzy/data/real_images.dart';

class TrackPage extends StatelessWidget {
  const TrackPage({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _TimelineItem('تم إنشاء الشحنة'.tr, '16 مارس 08:15'.tr, true),
      _TimelineItem('الفرز في ميناء الإسكندرية'.tr, '16 مارس 14:10'.tr, true),
      _TimelineItem('التخليص الجمركي'.tr, '17 مارس 06:40'.tr, true),
      _TimelineItem('خروج للتسليم النهائي'.tr, 'متوقع 18 مارس 13:30'.tr, false),
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
            SizedBox(height: 16),
            Text('تتبع الشحنة'.tr, style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 10),
            Text(
              'استخدم رقم الشحنة لمتابعة المسار وموعد الوصول ونقاط التحديث.'.tr,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'رقم الشحنة'.tr, hintText: 'ادخل رقم الشحنة (مثال: EZ-94012)'.tr, floatingLabelBehavior: FloatingLabelBehavior.auto,
                prefixIcon: Icon(Icons.search_rounded),
                suffixIcon: FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('تتبع'.tr),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                filled: true,
              ),
            ),
            SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الشحنة EZ-94012'.tr,
                        style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: 6),
                    Text(
                      'ميناء الإسكندرية    القاهرة مصر'.tr,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: 14),
                    const LinearProgressIndicator(
                      value: 0.68,
                      minHeight: 10,
                      valueColor: AlwaysStoppedAnimation(Color(0xFFE71D24)),
                    ),
                    SizedBox(height: 8),
                    Text('اكتمل 68%  موعد الوصول: 18 مارس 13:30'.tr),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text('الخط الزمني للمسار'.tr, style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
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
        SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 2),
                Text(item.subtitle),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
