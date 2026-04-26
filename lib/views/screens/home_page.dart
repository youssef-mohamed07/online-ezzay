import 'package:online_ezzy/core/app_translations.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_ezzy/core/api_service.dart';
import 'package:online_ezzy/providers/auth_provider.dart';
import 'package:online_ezzy/providers/product_provider.dart';
import 'package:online_ezzy/providers/cart_provider.dart';
import 'package:online_ezzy/providers/dashboard_provider.dart';
import 'package:online_ezzy/providers/shipment_provider.dart';
import 'package:online_ezzy/data/real_images.dart';
import 'package:online_ezzy/widgets/cached_image.dart';
import 'packages_page.dart';
import 'cart_page.dart';
import 'track_page.dart';
import 'shipments_page.dart';
import 'shipment_details_page.dart';
import 'notifications_page.dart';
import 'profile_page.dart';
import 'dashboard_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const List<int> _addressCategoryIds = [69, 70, 77];

  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  int _bannerIndex = 0;
  late Future<int> _unreadNotificationsFuture;

  @override
  void initState() {
    super.initState();
    _unreadNotificationsFuture = ApiService.getUnreadNotificationsCount();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadData();
      _startBannerTimer();
    });
  }

  void _refreshUnreadNotificationsCount() {
    setState(() {
      _unreadNotificationsFuture = ApiService.getUnreadNotificationsCount();
    });
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_bannerController.hasClients) return;
      final dp = context.read<DashboardProvider>();
      final len = dp.sliders.isNotEmpty ? dp.sliders.length : 3;
      final next = (_bannerIndex + 1) % len;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
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

  void _openPage(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            SizedBox(height: 8), // Breathing room for header
            _TopHeader(
              notificationsFuture: _unreadNotificationsFuture,
              onTapProfile: () => _openPage(const ProfilePage()),
              onTapDashboard: () => _openPage(const DashboardPage()),
              onTapNotification: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NotificationsPage(),
                  ),
                );
                _refreshUnreadNotificationsCount();
              },
            ),
            SizedBox(height: 28),
            _TopActionsRow(
              onTapDelivery: () => _openPage(
                const PackagesPage(categoryId: 68, pageTitle: 'طلب توصيل'),
              ),
              onTapAddress: () => _openPage(
                const PackagesPage(
                  categoryIds: _addressCategoryIds,
                  pageTitle: 'العناوين',
                ),
              ),
              onTapTrack: () => _openPage(const ShipmentsPage()),
              onTapServices: () => _openPage(
                const PackagesPage(categoryId: 66, pageTitle: 'خدمات مالية'),
              ),
            ),
            SizedBox(height: 28),
            Consumer<DashboardProvider>(
              builder: (context, dashboard, _) {
                if (dashboard.isLoading && dashboard.sliders.isEmpty) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                List<String> images = [];
                try {
                  images = dashboard.sliders
                      .where((s) => s != null)
                      .map<String>((s) => s.toString())
                      .where((url) => url.trim().isNotEmpty)
                      .toList();
                } catch (e) {
                  print('Error processing sliders: $e');
                }

                if (images.isEmpty) {
                  images = [
                    RealImages.homeHero,
                    RealImages.trackHero,
                    RealImages.shipmentsHero,
                  ];
                }

                return _HeroSlider(
                  controller: _bannerController,
                  images: images,
                  index: _bannerIndex,
                  onPageChanged: (value) =>
                      setState(() => _bannerIndex = value),
                );
              },
            ),
            SizedBox(height: 28),
            _SectionTitle('تتبع الشحنة'.tr),
            SizedBox(height: 12),
            const _TrackingCard(),
            SizedBox(height: 24),
            _SectionTitle('الشحنات النشطة'),
            SizedBox(height: 12),
            Consumer<ShipmentProvider>(
              builder: (context, provider, _) {
                final active = provider.shipments.where((s) {
                  final status =
                      (s['current_status'] ??
                              s['status'] ??
                              s['shipment_status'] ??
                              '')
                          .toString()
                          .toLowerCase();
                  return !(status.contains('تم التسليم') ||
                      status.contains('delivered') ||
                      status.contains('completed'));
                }).toList();

                if (provider.isLoading && active.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (active.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'لا توجد شحنات نشطة حالياً',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  );
                }

                return Column(
                  children: [
                    ...active
                        .take(2)
                        .map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ActiveShipmentCard(shipment: s),
                          ),
                        ),
                  ],
                );
              },
            ),
            SizedBox(height: 24),
            _SectionTitle('طرود في المستودع'),
            SizedBox(height: 12),
            Consumer<ShipmentProvider>(
              builder: (context, provider, _) {
                final warehouseShipments = provider.shipments.where((s) {
                  final status =
                      (s['current_status'] ??
                              s['status'] ??
                              s['shipment_status'] ??
                              '')
                          .toString()
                          .toLowerCase();
                  return status.contains('warehouse') ||
                      status.contains('stored') ||
                      status.contains('في المستودع') ||
                      status.contains('في الصندوق') ||
                      status.contains('box');
                }).toList();

                if (provider.isLoading && warehouseShipments.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (warehouseShipments.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'لا توجد طرود في المستودع حالياً',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  );
                }

                return Column(
                  children: [
                    ...warehouseShipments.take(3).map((shipment) {
                      final code =
                          (shipment['tracking_number'] ??
                                  shipment['number'] ??
                                  shipment['id'] ??
                                  '-')
                              .toString();
                      final source =
                          (shipment['current_status'] ??
                                  shipment['status'] ??
                                  shipment['shipment_status'] ??
                                  '-')
                              .toString();
                      final weight =
                          (shipment['weight'] ??
                                  shipment['total_weight'] ??
                                  '-')
                              .toString();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _WarehousePreviewCard(
                          code: code,
                          source: source,
                          weight: weight,
                          onTap: () =>
                              _openPage(TrackPage(initialTrackingNumber: code)),
                        ),
                      );
                    }),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _WarehouseOrderCard(
                        onTap: () => _openPage(
                          const PackagesPage(
                            categoryId: 68,
                            pageTitle: 'طلب توصيل',
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionTitle('العناوين'),
                GestureDetector(
                  onTap: () => _openPage(
                    const PackagesPage(
                      categoryIds: _addressCategoryIds,
                      pageTitle: 'العناوين',
                    ),
                  ),
                  child: Text(
                    'الباقات',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE71D24),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _AddressCardsRow(),
            SizedBox(height: 48), // Bottom padding
          ],
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({
    required this.onTapNotification,
    required this.notificationsFuture,
    required this.onTapProfile,
    required this.onTapDashboard,
  });

  final Future<void> Function() onTapNotification;
  final Future<int> notificationsFuture;
  final VoidCallback onTapProfile;
  final VoidCallback onTapDashboard;

  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'صباح الخير';
    return 'مساء الخير';
  }

  String _activeShipmentsText(int count) {
    if (count <= 0) return 'ليس لديك شحنات نشطة';
    if (count == 1) return 'لديك شحنة نشطة واحدة';
    return 'لديك $count شحنات نشطة';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ShipmentProvider>(
      builder: (context, auth, shipmentProvider, _) {
        final userName = auth.displayName;
        final trimmedName = userName.trim();
        final avatarLetter = trimmedName.isNotEmpty
            ? trimmedName[0]
            : (auth.isAuthenticated ? 'م' : 'ض');
        final greeting = _timeGreeting();
        final activeShipmentsCount = shipmentProvider.shipments.where((s) {
          final status =
              (s['current_status'] ?? s['status'] ?? s['shipment_status'] ?? '')
                  .toString()
                  .toLowerCase();
          return status != 'تم التسليم' &&
              status != 'delivered' &&
              status != 'completed';
        }).length;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'مرحباً $userName',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _activeShipmentsText(activeShipmentsCount),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    onTapNotification();
                  },
                  child: FutureBuilder<int>(
                    future: notificationsFuture,
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            color: Color(0xFF1E293B),
                            size: 28,
                          ),
                          if (count > 0)
                            Positioned(
                              right: 2,
                              top: 2,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE71D24),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                SizedBox(width: 12),
                GestureDetector(
                  onTap: onTapDashboard,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(
                      Icons.dashboard_rounded,
                      color: Color(0xFF1E293B),
                      size: 22,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                GestureDetector(
                  onTap: onTapProfile,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFC0B6),
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Center(
                          child: Text(
                            avatarLetter,
                            style: const TextStyle(
                              color: Color(0xFFE71D24),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        Positioned(
                          left: -2,
                          bottom: -2,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 11,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _TopActionsRow extends StatelessWidget {
  const _TopActionsRow({
    required this.onTapDelivery,
    required this.onTapAddress,
    required this.onTapTrack,
    required this.onTapServices,
  });

  final VoidCallback onTapDelivery;
  final VoidCallback onTapAddress;
  final VoidCallback onTapTrack;
  final VoidCallback onTapServices;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ActionItem(
          title: 'اطلب توصيل',
          icon: Icons.inventory_2_rounded,
          iconColor: Colors.red.shade600,
          bgColor: Colors.red.shade50,
          onTap: onTapDelivery,
        ),
        _ActionItem(
          title: 'العناوين',
          icon: Icons.location_on_rounded,
          iconColor: Colors.blue.shade600,
          bgColor: Colors.blue.shade50,
          onTap: onTapAddress,
        ),
        _ActionItem(
          title: 'تتبع شحنتك',
          icon: Icons.local_shipping_rounded,
          iconColor: Colors.green.shade600,
          bgColor: Colors.green.shade50,
          onTap: onTapTrack,
        ),
        _ActionItem(
          title: 'خدمات مالية',
          icon: Icons.account_balance_wallet_rounded,
          iconColor: Colors.orange.shade600,
          bgColor: Colors.orange.shade50,
          onTap: onTapServices,
        ),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSlider extends StatelessWidget {
  const _HeroSlider({
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
          height: 160,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: PageView.builder(
              controller: controller,
              onPageChanged: onPageChanged,
              itemCount: images.length,
              itemBuilder: (context, i) {
                return CachedImage(
                  imageUrl: images[i],
                  fit: BoxFit.cover,
                  width: double.infinity,
                );
              },
            ),
          ),
        ),
        SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(images.length, (i) {
            final active = i == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.right,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w900,
        color: Color(0xFF1E293B),
      ),
    );
  }
}

class _TrackingCard extends StatefulWidget {
  const _TrackingCard();

  @override
  State<_TrackingCard> createState() => _TrackingCardState();
}

class _TrackingCardState extends State<_TrackingCard> {
  late final TextEditingController _trackingController;

  @override
  void initState() {
    super.initState();
    _trackingController = TextEditingController();
  }

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  void _openTracking() {
    final number = _trackingController.text.trim();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            TrackPage(initialTrackingNumber: number.isEmpty ? null : number),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _trackingController,
                onSubmitted: (_) => _openTracking(),
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: 'أدخل رقم التتبع',
                  hintStyle: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          ElevatedButton(
            onPressed: _openTracking,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE71D24),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
              elevation: 0,
            ),
            child: Text(
              'تتبع'.tr,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveShipmentCard extends StatelessWidget {
  final Map<String, dynamic> shipment;
  const _ActiveShipmentCard({required this.shipment});

  @override
  Widget build(BuildContext context) {
    final status =
        (shipment['current_status'] ??
                shipment['status'] ??
                shipment['shipment_status'] ??
                '')
            .toString()
            .tr;
    final trackingNumber =
        (shipment['tracking_number'] ??
                shipment['number'] ??
                shipment['id'] ??
                '-')
            .toString();
    final title = (shipment['title'] ?? shipment['name'] ?? 'شحنة').toString();
    final weight = (shipment['weight'] ?? shipment['total_weight'] ?? '0')
        .toString();
    final date =
        (shipment['date_added'] ??
                shipment['date'] ??
                shipment['created_at'] ??
                '')
            .toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF1F1), Color(0xFFFFE4E4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    color: Color(0xFFE71D24),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'رقم التتبع: #$trackingNumber',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE71D24).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE71D24),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: const TextStyle(
                          color: Color(0xFFE71D24),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(height: 1, color: const Color(0xFFF1F5F9)),

          // Timeline Section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: _buildTimelineStep(
                    'في المستودع'.tr,
                    isActive:
                        status == 'في المستودع' ||
                        status == 'في الطريق' ||
                        status == 'تم التسليم',
                    isCompleted:
                        status == 'في الطريق' || status == 'تم التسليم',
                  ),
                ),
                _buildTimelineLine(
                  isCompleted: status == 'في الطريق' || status == 'تم التسليم',
                ),
                Expanded(
                  child: _buildTimelineStep(
                    'في الطريق'.tr,
                    isActive: status == 'في الطريق' || status == 'تم التسليم',
                    isCompleted: status == 'تم التسليم',
                  ),
                ),
                _buildTimelineLine(isCompleted: status == 'تم التسليم'),
                Expanded(
                  child: _buildTimelineStep(
                    'تم التسليم'.tr,
                    isActive: status == 'تم التسليم',
                    isCompleted: status == 'تم التسليم',
                  ),
                ),
              ],
            ),
          ),

          // Actions Section
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ShipmentDetailsPage(
                            trackingNumber: trackingNumber,
                            status: status,
                            weight: weight,
                            date: date,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'عرض التفاصيل',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              TrackPage(initialTrackingNumber: trackingNumber),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE71D24),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'تتبع',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
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

  Widget _buildTimelineStep(
    String label, {
    required bool isActive,
    required bool isCompleted,
  }) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFFE71D24)
                : (isActive
                      ? const Color(0xFFE71D24).withValues(alpha: 0.1)
                      : const Color(0xFFF1F5F9)),
            shape: BoxShape.circle,
            border: Border.all(
              color: isCompleted || isActive
                  ? const Color(0xFFE71D24)
                  : const Color(0xFFE2E8F0),
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : (isActive
                      ? Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE71D24),
                            shape: BoxShape.circle,
                          ),
                        )
                      : Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFCBD5E1),
                            shape: BoxShape.circle,
                          ),
                        )),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive || isCompleted
                ? FontWeight.w800
                : FontWeight.w600,
            color: isActive || isCompleted
                ? const Color(0xFF1E293B)
                : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineLine({required bool isCompleted}) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 3,
        margin: const EdgeInsets.only(bottom: 28),
        decoration: BoxDecoration(
          color: isCompleted
              ? const Color(0xFFE71D24)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _WarehouseOrderCard extends StatelessWidget {
  const _WarehouseOrderCard({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اطلب إرسال طردك',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: onTap ?? () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE71D24),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'اطلب توصيل الآن',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5E6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              size: 36,
              color: Color(0xFFC68A5A),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarehousePreviewCard extends StatelessWidget {
  const _WarehousePreviewCard({
    required this.code,
    required this.source,
    required this.weight,
    this.onTap,
  });

  final String code;
  final String source;
  final String weight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5E6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: Color(0xFFC68A5A),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'طرد #$code',
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      source,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F9EE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'جاهز للشحن',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'الوزن: $weight',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFE71D24),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                child: const Text('جدولة الشحن'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddressCardsRow extends StatefulWidget {
  @override
  State<_AddressCardsRow> createState() => _AddressCardsRowState();
}

class _AddressCardsRowState extends State<_AddressCardsRow> {
  static const List<int> _addressCategoryIds = [69, 70, 77];

  static const List<Map<String, String>> _mockAddressItems = [
    {'name': 'عنوان أمريكا', 'price': '4.99', 'note': 'تفعيل خلال 24 ساعة'},
    {'name': 'عنوان الصين', 'price': '3.49', 'note': 'يشمل خدمات التجميع'},
    {'name': 'عنوان أوروبا', 'price': '5.25', 'note': 'خيارات شحن أسرع'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(
        context,
        listen: false,
      ).loadProductsByCategories(_addressCategoryIds);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        if (productProvider.isLoading) {
          return const SizedBox(
            height: 154,
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFFE71D24)),
            ),
          );
        }

        List<dynamic> items = productProvider.deliveryProducts;

        if (items.isEmpty) {
          return SizedBox(
            height: 165,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _mockAddressItems.length,
              itemBuilder: (context, index) {
                final item = _mockAddressItems[index];
                return _MockAddressCard(
                  name: item['name']!,
                  price: item['price']!,
                  note: item['note']!,
                );
              },
            ),
          );
        }

        return SizedBox(
          height: 165,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final prod = items[index];
              final productId = int.tryParse(prod['id'].toString()) ?? 0;
              final String name = prod['name']?.toString() ?? 'عنوان';
              final String price = prod['price']?.toString() ?? '0';

              return Container(
                width: 155,
                margin: const EdgeInsets.only(left: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.place_rounded,
                          color: Color(0xFFE71D24),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Color(0xFF1E293B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$price دولار\nتعرف على تفاصيل العنوان',
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: Consumer<CartProvider>(
                        builder: (context, cartProvider, child) {
                          final cartItem = cartProvider.cartItems.firstWhere(
                            (item) =>
                                item['id'].toString() == productId.toString(),
                            orElse: () => null,
                          );

                          final isInCart = cartItem != null;
                          final isAddingThis = cartProvider.isAddingProduct(
                            productId,
                          );
                          return ElevatedButton(
                            onPressed: isAddingThis
                                ? null
                                : () async {
                                    if (isInCart) {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const CartPage(),
                                        ),
                                      );
                                      return;
                                    }
                                    await cartProvider.addToCart(productId, 1);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isInCart
                                  ? const Color(0xFFF1F5F9)
                                  : const Color(0xFFE71D24),
                              foregroundColor: isInCart
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              side: isInCart
                                  ? const BorderSide(color: Color(0xFFE2E8F0))
                                  : BorderSide.none,
                              padding: const EdgeInsets.symmetric(vertical: 0),
                              minimumSize: const Size(double.infinity, 36),
                              elevation: 0,
                            ),
                            child: isAddingThis
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    isInCart ? 'اذهب للسلة' : 'اطلب الآن',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _MockAddressCard extends StatelessWidget {
  const _MockAddressCard({
    required this.name,
    required this.price,
    required this.note,
  });

  final String name;
  final String price;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 155,
      margin: const EdgeInsets.only(left: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Icon(
                Icons.place_rounded,
                color: Color(0xFFE71D24),
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            '$price دولار\n$note',
            textAlign: TextAlign.start,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE71D24),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 0),
                minimumSize: const Size(double.infinity, 36),
                elevation: 0,
              ),
              child: const Text(
                'اطلب الآن',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
