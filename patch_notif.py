with open("lib/views/screens/notifications_page.dart", "r", encoding="utf-8") as f:
    text = f.read()

text = text.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:online_ezzy/core/api_service.dart';")

text = text.replace("class NotificationsPage extends StatelessWidget {", "class NotificationsPage extends StatefulWidget {\n  const NotificationsPage({super.key});\n\n  @override\n  State<NotificationsPage> createState() => _NotificationsPageState();\n}\n\nclass _NotificationsPageState extends State<NotificationsPage> {")

text = text.replace("  const NotificationsPage({super.key});", "")

old_body = """        body: ListView(
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
        ),"""

new_body = """        body: FutureBuilder<List<dynamic>>(
          future: ApiService.getNotifications(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return Center(child: Text('لا توجد إشعارات حالياً'.tr, style: TextStyle(color: Colors.grey)));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildNotificationItem(
                    title: item['title']?.toString() ?? 'إشعار جديد',
                    description: item['description']?.toString() ?? '',
                    time: item['time']?.toString() ?? 'الآن',
                    icon: Icons.notifications_none,
                    color: const Color(0xFFE71D24),
                    isUnread: item['isUnread'] == true,
                  ),
                );
              },
            );
          },
        ),"""

text = text.replace(old_body, new_body)

with open("lib/views/screens/notifications_page.dart", "w", encoding="utf-8") as f:
    f.write(text)
