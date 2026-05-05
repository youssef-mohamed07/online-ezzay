import 'package:online_ezzy/core/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_ezzy/core/api_service.dart';
import 'package:online_ezzy/core/image_url_utils.dart';
import 'package:online_ezzy/providers/shipment_provider.dart';
import 'package:online_ezzy/views/screens/notifications_page.dart';
import 'package:online_ezzy/views/screens/auth/login_page.dart';
import 'package:online_ezzy/widgets/cached_image.dart';

class ShipmentsPage extends StatefulWidget {
  const ShipmentsPage({super.key});

  @override
  State<ShipmentsPage> createState() => _ShipmentsPageState();
}

class _ShipmentsPageState extends State<ShipmentsPage> {
  String _selectedFilter = 'الكل'.tr;
  final TextEditingController _searchController = TextEditingController();
  late Future<int> _unreadNotificationsFuture;

  final List<String> _filters = [
    'الكل'.tr,
    'تم الطلب'.tr,
    'في الصندوق'.tr,
    'في الطريق'.tr,
    'تم التسليم'.tr,
  ];

  @override
  void initState() {
    super.initState();
    _unreadNotificationsFuture = ApiService.getUnreadNotificationsCount();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShipmentProvider>().loadShipments();
    });
  }

  void _refreshUnreadNotificationsCount() {
    setState(() {
      _unreadNotificationsFuture = ApiService.getUnreadNotificationsCount();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalizeStatus(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.contains('delivered') || value.contains('تم التسليم')) {
      return 'تم التسليم'.tr;
    }
    if (value.contains('transit') || value.contains('shipping') || value.contains('في الطريق')) {
      return 'في الطريق'.tr;
    }
    if (value.contains('warehouse') ||
        value.contains('stored') ||
        value.contains('في المستودع') ||
        value.contains('في الصندوق') ||
        value.contains('box')) {
      return 'في الصندوق'.tr;
    }
    if (value.contains('request') || value.contains('ordered') || value.contains('تم الطلب')) {
      return 'تم الطلب'.tr;
    }
    return raw.isEmpty ? 'تم الطلب'.tr : raw;
  }

  String _shipmentStatusRaw(Map<String, dynamic> shipment) {
    return (shipment['current_status'] ??
            shipment['status'] ??
            shipment['shipment_status'] ??
            '')
        .toString();
  }

  String _shipmentDateRaw(Map<String, dynamic> shipment) {
    return (shipment['date_added'] ?? shipment['date'] ?? shipment['created_at'] ?? '')
        .toString();
  }

  Color _statusColor(String status) {
    final value = status.toLowerCase();
    if (value.contains('تسليم')) return const Color(0xFF10B981);
    if (value.contains('طريق')) return const Color(0xFFF59E0B);
    if (value.contains('مستودع') || value.contains('صندوق')) {
      return const Color(0xFF3B82F6);
    }
    return const Color(0xFFE71D24);
  }

  int _statusStep(String status) {
    final value = status.toLowerCase();
    if (value.contains('تسليم')) return 3;
    if (value.contains('طريق')) return 2;
    return 1;
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
            'الشحنات',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: FutureBuilder<int>(
            future: _unreadNotificationsFuture,
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.notifications_none,
                      color: Color(0xFF475569),
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsPage(),
                        ),
                      );
                      _refreshUnreadNotificationsCount();
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE71D24),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.search, color: Color(0xFF475569)),
              onPressed: () {},
            ),
          ],
        ),
        body: Consumer<ShipmentProvider>(
          builder: (context, shipmentProvider, _) {
            final allShipments = shipmentProvider.shipments;
            final query = _searchController.text.trim().toLowerCase();

            final filtered = allShipments.where((shipment) {
              final tracking = (shipment['tracking_number'] ?? shipment['number'] ?? shipment['id'] ?? '').toString();
              final title = (shipment['title'] ?? shipment['name'] ?? '').toString();
              final status = _normalizeStatus(_shipmentStatusRaw(shipment));

              final filterMatches = _selectedFilter == 'الكل'.tr || status == _selectedFilter;
              final searchMatches =
                  query.isEmpty ||
                  tracking.toLowerCase().contains(query) ||
                  title.toLowerCase().contains(query);

              return filterMatches && searchMatches;
            }).toList();

            return Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: _filters.map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: ChoiceChip(
                            label: Text(
                              filter,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF64748B),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedFilter = filter);
                              }
                            },
                            showCheckmark: false,
                            selectedColor: const Color(0xFFE71D24),
                            backgroundColor: const Color(0xFFF1F5F9),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 8,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'ابحث برقم الشحنة'.tr,
                      hintStyle: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                Expanded(
                  child: shipmentProvider.isLoading && allShipments.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : shipmentProvider.requiresAuth
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.lock_outline,
                                      size: 64,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'يجب تسجيل الدخول'.tr,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'قم بتسجيل الدخول لعرض شحناتك'.tr,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF64748B),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 24),
                                    ElevatedButton(
                                      onPressed: () {
                                        // Navigate to login page
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const LoginPage(),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFFE71D24),
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 32,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        'تسجيل الدخول'.tr,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: shipmentProvider.loadShipments,
                              child: filtered.isEmpty
                                  ? ListView(
                                      children: [
                                        const SizedBox(height: 80),
                                        Center(
                                          child: Column(
                                            children: [
                                              Text(
                                                'لا توجد شحنات حاليا'.tr,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'ابدأ بطلب توصيل جديد'.tr,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF94A3B8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  : ListView.separated(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: filtered.length,
                                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                                      itemBuilder: (context, index) {
                                        final shipment = filtered[index];
                                        final tracking =
                                            (shipment['tracking_number'] ??
                                                    shipment['number'] ??
                                                    shipment['id'] ??
                                                    '')
                                                .toString();
                                        final status = _normalizeStatus(
                                          _shipmentStatusRaw(shipment),
                                        );
                                        final statusColor = _statusColor(status);
                                        final step = _statusStep(status);
                                        final weight =
                                            (shipment['weight'] ?? shipment['total_weight'] ?? '0').toString();
                                        final date = _shipmentDateRaw(shipment);

                                        return _ShipmentCardWithImage(
                                          trackingNumber: tracking,
                                          status: status,
                                          statusColor: statusColor,
                                          step: step,
                                          weight: weight,
                                          date: date,
                                          shipment: shipment,
                                        );
                                      },
                                    ),
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ShipmentCardWithImage extends StatelessWidget {
  final String trackingNumber;
  final String status;
  final Color statusColor;
  final int step;
  final String weight;
  final String date;
  final Map<String, dynamic> shipment;

  const _ShipmentCardWithImage({
    required this.trackingNumber,
    required this.status,
    required this.statusColor,
    required this.step,
    required this.weight,
    required this.date,
    required this.shipment,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: context.read<ShipmentProvider>().loadShipmentImage(
        trackingNumber,
        shipment: shipment,
      ),
      builder: (context, snapshot) {
        final imageUrl = snapshot.data ?? '';
        
        return _ShipmentCard(
          trackingNumber: trackingNumber,
          status: status,
          statusColor: statusColor,
          imageUrl: imageUrl,
          step: step,
          weight: weight,
          date: date,
        );
      },
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  final String trackingNumber;
  final String status;
  final Color statusColor;
  final String imageUrl;
  final int step;
  final String weight;
  final String date;

  const _ShipmentCard({
    required this.trackingNumber,
    required this.status,
    required this.statusColor,
    required this.imageUrl,
    required this.step,
    required this.weight,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedImageUrl = normalizeImageUrl(imageUrl);
    final canOpenImage = normalizedImageUrl.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: canOpenImage
                    ? () => _showZoomableImage(context, normalizedImageUrl)
                    : null,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedImage(
                        imageUrl: imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (canOpenImage)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.zoom_in,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'رقم التتبع : $trackingNumber'.tr,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          _buildTimeline(step),
          SizedBox(height: 24),
          Row(
            children: [
              const Spacer(),
              Text(
                'الوزن $weight كجم | تاريخ $date'.tr,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showZoomableImage(BuildContext context, String imageUrl) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return GestureDetector(
          onTap: () => Navigator.of(dialogContext).pop(),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 5.0,
                      panEnabled: true,
                      child: CachedImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        width: MediaQuery.of(dialogContext).size.width,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeline(int step) {
    Color activeRed = const Color(0xFFE71D24);
    Color inactiveGrey = const Color(0xFFE2E8F0);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 11,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      color: step >= 2 ? activeRed : inactiveGrey,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: step >= 3 ? activeRed : inactiveGrey,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTimelineNode(
                  title: 'في الصندوق'.tr,
                  state: 1,
                  activeColor: activeRed,
                  inactiveColor: inactiveGrey,
                ),
                _buildTimelineNode(
                  title: 'في الطريق'.tr,
                  state: step >= 2 ? 2 : 0,
                  activeColor: activeRed,
                  inactiveColor: inactiveGrey,
                ),
                _buildTimelineNode(
                  title: 'تم التسليم'.tr,
                  state: step >= 3 ? 2 : 0,
                  activeColor: activeRed,
                  inactiveColor: inactiveGrey,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimelineNode({
    required String title,
    required int state,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    Widget circle;
    if (state == 1) {
      circle = Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: activeColor, shape: BoxShape.circle),
        child: Icon(Icons.check, color: Colors.white, size: 16),
      );
    } else if (state == 2) {
      circle = Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: activeColor, width: 2),
        ),
        child: Center(
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: activeColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    } else {
      circle = Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: inactiveColor, width: 2),
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: inactiveColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        circle,
        SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
