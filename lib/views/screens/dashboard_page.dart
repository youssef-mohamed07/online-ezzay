import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_ezzy/core/app_translations.dart';
import 'package:online_ezzy/providers/auth_provider.dart';
import 'package:online_ezzy/providers/dashboard_provider.dart';
import 'package:online_ezzy/providers/shipment_provider.dart';
import 'package:online_ezzy/data/real_images.dart';

import 'cart_page.dart';
import 'contact_us_page.dart';
import 'packages_page.dart';
import 'shipments_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  int _bannerIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
      _startBannerTimer();
    });
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_bannerController.hasClients) return;
      final provider = context.read<DashboardProvider>();
      final slidersCount = provider.sliders.length;
      final count = slidersCount > 0 ? slidersCount : 3;
      final next = (_bannerIndex + 1) % count;

      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    final dashboardProvider = context.read<DashboardProvider>();
    final shipmentProvider = context.read<ShipmentProvider>();

    await Future.wait([
      dashboardProvider.loadData(),
      shipmentProvider.loadShipments(),
    ]);
  }

  bool _isDeliveredShipment(Map<String, dynamic> shipment) {
    final status =
      (shipment['current_status'] ?? shipment['status'] ?? shipment['shipment_status'] ?? '')
        .toString()
        .toLowerCase();
    return status.contains('تم التسليم') ||
        status.contains('delivered') ||
        status.contains('completed');
  }

  dynamic _valueByPath(Map<String, dynamic>? source, String path) {
    dynamic current = source;
    for (final segment in path.split('.')) {
      if (current is Map && current.containsKey(segment)) {
        current = current[segment];
      } else {
        return null;
      }
    }
    return current;
  }

  int? _firstInt(Map<String, dynamic>? source, List<String> keys) {
    for (final key in keys) {
      final value = _valueByPath(source, key);
      if (value is int) return value;
      if (value is double) return value.toInt();

      final parsed = int.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return null;
  }

  String _todayLabel() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '$day/$month/${now.year}';
  }

  void _openPage(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
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
            'لوحة التحكم'.tr,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
            ),
          ],
        ),
        body: Consumer3<AuthProvider, DashboardProvider, ShipmentProvider>(
          builder: (context, auth, dashboardProvider, shipmentProvider, _) {
            final dashboardData = dashboardProvider.dashboardData;
            final shipments = shipmentProvider.shipments;
            List<String> bannerImages = dashboardProvider.sliders
                .map((s) => (s['image'] ?? '').toString())
                .where((url) => url.trim().isNotEmpty)
                .toList();

            if (bannerImages.isEmpty) {
              bannerImages = [
                RealImages.homeHero,
                RealImages.trackHero,
                RealImages.shipmentsHero,
              ];
            }

            final deliveredFromShipments = shipments
                .where(_isDeliveredShipment)
                .length;
            final activeFromShipments = shipments
                .where((s) => !_isDeliveredShipment(s))
                .length;

            final totalShipments =
                _firstInt(dashboardData, [
                  'total_shipments',
                  'shipments_count',
                  'shipments.total',
                ]) ??
                shipments.length;

            final deliveredShipments =
                _firstInt(dashboardData, [
                  'delivered_shipments',
                  'delivered_count',
                  'shipments.delivered',
                ]) ??
                deliveredFromShipments;

            final activeShipments =
                _firstInt(dashboardData, [
                  'active_shipments',
                  'active_count',
                  'shipments.active',
                ]) ??
                activeFromShipments;

            final warehouseParcels =
                _firstInt(dashboardData, [
                  'warehouse_parcels_count',
                  'warehouse_count',
                  'warehouse.parcels_count',
                ]) ??
                0;

            final recentShipments = shipments.take(3).toList();

            return RefreshIndicator(
              onRefresh: _refreshData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _DashboardHeaderCard(
                    userName: auth.displayName,
                    dateLabel: _todayLabel(),
                  ),
                  const SizedBox(height: 16),
                  _DashboardBannerSlider(
                    controller: _bannerController,
                    images: bannerImages,
                    index: _bannerIndex,
                    onPageChanged: (value) {
                      setState(() => _bannerIndex = value);
                    },
                  ),
                  const SizedBox(height: 20),
                  _StatusChartCard(
                    active: activeShipments,
                    delivered: deliveredShipments,
                    warehouse: warehouseParcels,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'المؤشرات الرئيسية',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _MetricCard(
                        title: 'إجمالي الشحنات',
                        value: totalShipments.toString(),
                        icon: Icons.local_shipping_rounded,
                        color: const Color(0xFF2563EB),
                      ),
                      _MetricCard(
                        title: 'شحنات نشطة',
                        value: activeShipments.toString(),
                        icon: Icons.flash_on_rounded,
                        color: const Color(0xFFE71D24),
                      ),
                      _MetricCard(
                        title: 'تم التسليم',
                        value: deliveredShipments.toString(),
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF16A34A),
                      ),
                      _MetricCard(
                        title: 'طرود بالمستودع',
                        value: warehouseParcels.toString(),
                        icon: Icons.inventory_2_rounded,
                        color: const Color(0xFFF59E0B),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'اختصارات سريعة',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _QuickActionCard(
                        title: 'الشحنات',
                        icon: Icons.inventory_2_outlined,
                        color: const Color(0xFF1D4ED8),
                        onTap: () => _openPage(const ShipmentsPage()),
                      ),
                      _QuickActionCard(
                        title: 'طلب توصيل',
                        icon: Icons.add_box_rounded,
                        color: const Color(0xFFE71D24),
                        onTap: () => _openPage(const PackagesPage()),
                      ),
                      _QuickActionCard(
                        title: 'السلة',
                        icon: Icons.shopping_cart_outlined,
                        color: const Color(0xFF7C3AED),
                        onTap: () => _openPage(const CartPage()),
                      ),
                      _QuickActionCard(
                        title: 'تواصل معنا',
                        icon: Icons.support_agent_rounded,
                        color: const Color(0xFF0F766E),
                        onTap: () => _openPage(const ContactUsPage()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'آخر الشحنات',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _openPage(const ShipmentsPage()),
                        child: Text(
                          'عرض الكل'.tr,
                          style: const TextStyle(
                            color: Color(0xFFE71D24),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (dashboardProvider.isLoading && shipments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFE71D24),
                        ),
                      ),
                    )
                  else if (recentShipments.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'لا توجد شحنات لعرضها حالياً',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    )
                  else
                    ...recentShipments.map(
                      (shipment) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RecentShipmentCard(
                          trackingNumber:
                              (shipment['tracking_number'] ??
                                      shipment['number'] ??
                                      shipment['id'] ??
                                      '-')
                                  .toString(),
                          status:
                              (shipment['current_status'] ??
                                  shipment['status'] ??
                                      shipment['shipment_status'] ??
                                      'تم الطلب')
                                  .toString(),
                          delivered: _isDeliveredShipment(shipment),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashboardBannerSlider extends StatelessWidget {
  const _DashboardBannerSlider({
    required this.controller,
    required this.images,
    required this.index,
    required this.onPageChanged,
  });

  final PageController controller;
  final List<String> images;
  final int index;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 145,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: PageView.builder(
              controller: controller,
              onPageChanged: onPageChanged,
              itemCount: images.length,
              itemBuilder: (context, i) {
                return Image.network(
                  images[i],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFE2E8F0),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: Color(0xFF64748B),
                      size: 34,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(images.length, (i) {
            final active = i == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFE71D24)
                    : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _StatusChartCard extends StatelessWidget {
  const _StatusChartCard({
    required this.active,
    required this.delivered,
    required this.warehouse,
  });

  final int active;
  final int delivered;
  final int warehouse;

  @override
  Widget build(BuildContext context) {
    final values = [active, delivered, warehouse];
    final maxValue = values.fold<int>(
      1,
      (prev, cur) => cur > prev ? cur : prev,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'مخطط حالة الشحنات',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _ChartBar(
                  label: 'نشطة',
                  value: active,
                  maxValue: maxValue,
                  color: const Color(0xFFE71D24),
                ),
                _ChartBar(
                  label: 'تم التسليم',
                  value: delivered,
                  maxValue: maxValue,
                  color: const Color(0xFF16A34A),
                ),
                _ChartBar(
                  label: 'مستودع',
                  value: warehouse,
                  maxValue: maxValue,
                  color: const Color(0xFFF59E0B),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartBar extends StatelessWidget {
  const _ChartBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final String label;
  final int value;
  final int maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final normalized = maxValue <= 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);

    return SizedBox(
      width: 82,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const minBarHeight = 10.0;
                final trackHeight = constraints.maxHeight;
                final barHeight =
                    minBarHeight + ((trackHeight - minBarHeight) * normalized);

                return Container(
                  width: 28,
                  height: trackHeight,
                  alignment: Alignment.bottomCenter,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    width: 20,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHeaderCard extends StatelessWidget {
  const _DashboardHeaderCard({required this.userName, required this.dateLabel});

  final String userName;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFE71D24), Color(0xFFB91C1C)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE71D24).withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'أهلاً بك في الداشبورد',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              dateLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cardWidth = (MediaQuery.of(context).size.width - 42) / 2;
    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardWidth = (MediaQuery.of(context).size.width - 42) / 2;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        width: cardWidth,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentShipmentCard extends StatelessWidget {
  const _RecentShipmentCard({
    required this.trackingNumber,
    required this.status,
    required this.delivered,
  });

  final String trackingNumber;
  final String status;
  final bool delivered;

  @override
  Widget build(BuildContext context) {
    final statusColor = delivered
        ? const Color(0xFF16A34A)
        : const Color(0xFFF59E0B);
    final statusBg = delivered
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFFFEDD5);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'رقم التتبع: $trackingNumber',
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              delivered ? 'مكتملة' : 'قيد التنفيذ',
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
