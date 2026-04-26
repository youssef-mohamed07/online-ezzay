import 'package:online_ezzy/core/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_ezzy/core/api_service.dart';
import 'package:online_ezzy/providers/shipment_provider.dart';
import 'package:online_ezzy/views/screens/shipment_details_page.dart';
import 'package:online_ezzy/views/screens/notifications_page.dart';
import 'package:online_ezzy/views/screens/track_page.dart';
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
    'في المستودع'.tr,
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
      return 'في المستودع'.tr;
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
    if (value.contains('مستودع')) return const Color(0xFF3B82F6);
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
                                  separatorBuilder: (_, __) => const SizedBox(height: 16),
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
                                    final imageUrl =
                                        (shipment['image'] ?? shipment['image_url'] ?? '').toString();
                                    final weight =
                                        (shipment['weight'] ?? shipment['total_weight'] ?? '0').toString();
                                    final date = _shipmentDateRaw(shipment);

                                    return _buildShipmentCard(
                                      trackingNumber: tracking,
                                      status: status,
                                      statusColor: statusColor,
                                      imageUrl: imageUrl,
                                      step: step,
                                      weight: weight,
                                      date: date,
                                      buttonDisabled: status == 'تم التسليم'.tr,
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

  Widget _buildShipmentCard({
    required String trackingNumber,
    required String status,
    required Color statusColor,
    required String imageUrl,
    required int step,
    required String weight,
    required String date,
    required bool buttonDisabled,
    bool isIconPlay = false,
    bool isIconCheck = false,
  }) {
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isIconCheck) ...[
                            Icon(
                              Icons.check_circle,
                              color: statusColor,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                          ] else if (isIconPlay) ...[
                            Icon(
                              Icons.play_arrow,
                              color: statusColor,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                          ],
                          Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedImage(
                  imageUrl: imageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          _buildTimeline(step),
          SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: buttonDisabled
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TrackPage(
                                initialTrackingNumber: trackingNumber,
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonDisabled
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFFE71D24),
                    foregroundColor: buttonDisabled
                        ? const Color(0xFF94A3B8)
                        : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                    disabledForegroundColor: const Color(0xFF94A3B8),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: Text(
                    'تتبع'.tr,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShipmentDetailsPage(
                        trackingNumber: trackingNumber,
                        status: status,
                        weight: weight,
                        date: date,
                      ),
                    ),
                  );
                },
                child: Text(
                  'عرض التفاصيل'.tr,
                  style: TextStyle(
                    color: Color(0xFFE71D24),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
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
                  state: 1, // 1 = checked
                  activeColor: activeRed,
                  inactiveColor: inactiveGrey,
                ),
                _buildTimelineNode(
                  title: 'في الطريق'.tr,
                  state: step >= 2 ? 2 : 0, // 2 = active dot, 0 = inactive
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
    required int state, // 0 = inactive, 1 = checked, 2 = active dot
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
