import 'package:online_ezzy/core/app_translations.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: Text(
            'الإشعارات'.tr,
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildNotificationItem(
              title: 'تم توصيل الشحنة',
              description: 'شحنتك رقم 8742638 تم توصيلها بنجاح إلى العنوان المحدد.',
              time: 'منذ ساعتين',
              icon: Icons.check_circle_outline,
              color: Colors.green,
            ),
            SizedBox(height: 12),
            _buildNotificationItem(
              title: 'شحنة في الطريق',
              description: 'شحنتك رقم 6654429 غادرت المستودع وهي الآن في الطريق إليك.',
              time: 'منذ 5 ساعات',
              icon: Icons.local_shipping_outlined,
              color: const Color(0xFFE71D24),
              isUnread: true,
            ),
            SizedBox(height: 12),
            _buildNotificationItem(
              title: 'تحديث في المحفظة',
              description: 'تم إضافة رصيد مسترجع بقيمة 50 ريال إلى محفظتك.',
              time: 'أمس',
              icon: Icons.account_balance_wallet_outlined,
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String description,
    required String time,
    required IconData icon,
    required Color color,
    bool isUnread = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread ? Colors.red.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread ? Colors.red.withOpacity(0.2) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.5,
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
