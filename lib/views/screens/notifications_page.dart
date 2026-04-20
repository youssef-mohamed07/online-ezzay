import 'package:online_ezzy/core/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:online_ezzy/core/api_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<dynamic>> _notificationsFuture;
  final Set<String> _readOverrides = <String>{};
  final Set<String> _markingAsRead = <String>{};

  @override
  void initState() {
    super.initState();
    _notificationsFuture = ApiService.getNotifications();
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _notificationsFuture = ApiService.getNotifications();
    });
    await _notificationsFuture;
  }

  Future<void> _markAsRead(String id) async {
    if (id.isEmpty || _markingAsRead.contains(id)) return;

    setState(() {
      _markingAsRead.add(id);
    });

    final success = await ApiService.markNotificationAsRead(id);
    if (!mounted) return;

    setState(() {
      _markingAsRead.remove(id);
      if (success) {
        _readOverrides.add(id);
      }
    });

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحديث الإشعار'.tr)),
      );
    }
  }

  String _friendlyError(Object? error) {
    final message = (error?.toString() ?? '').toLowerCase();
    if (message.contains('401') ||
        message.contains('403') ||
        message.contains('invalid_username') ||
        message.contains('invalid token') ||
        message.contains('jwt')) {
      return 'لم نتمكن من تحميل الإشعارات. تأكد من تسجيل الدخول ثم اسحب للتحديث.'.tr;
    }
    return 'تعذر تحميل الإشعارات الآن. اسحب للتحديث.'.tr;
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
        body: FutureBuilder<List<dynamic>>(
          future: _notificationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return RefreshIndicator(
                onRefresh: _refreshNotifications,
                child: ListView(
                  children: [
                    const SizedBox(height: 130),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _friendlyError(snapshot.error),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refreshNotifications,
                child: ListView(
                  children: [
                    const SizedBox(height: 150),
                    Center(
                      child: Text(
                        'لا توجد إشعارات حالياً'.tr,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: _refreshNotifications,
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final rawItem = items[index];
                  final item = rawItem is Map
                      ? Map<String, dynamic>.from(rawItem)
                      : <String, dynamic>{};
                  final id =
                      (item['id'] ?? item['notification_id'] ?? '').toString();
                  final isUnreadRemote = item['isUnread'] == true ||
                      item['is_unread'] == true ||
                      item['read'] == false;
                  final isUnread =
                      !_readOverrides.contains(id) && isUnreadRemote;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildNotificationItem(
                      title: item['title']?.toString() ?? 'إشعار جديد'.tr,
                      description: item['description']?.toString() ?? '',
                      time: item['time']?.toString() ?? 'الآن'.tr,
                      icon: Icons.notifications_none,
                      color: const Color(0xFFE71D24),
                      isUnread: isUnread,
                      isUpdating: _markingAsRead.contains(id),
                      onTap: isUnread ? () => _markAsRead(id) : null,
                    ),
                  );
                },
              ),
            );
          },
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
    bool isUpdating = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread ? Colors.red.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isUnread ? Colors.red.withOpacity(0.2) : Colors.grey.shade200,
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
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      isUpdating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
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
                  if (isUnread)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'اضغط للتحديد كمقروء'.tr,
                        style: const TextStyle(
                          color: Color(0xFFE71D24),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
