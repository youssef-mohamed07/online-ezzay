import 'package:online_ezzy/core/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:online_ezzy/views/screens/shipment_details_page.dart';
import 'package:online_ezzy/views/screens/notifications_page.dart';

class ShipmentsPage extends StatefulWidget {
  const ShipmentsPage({super.key});

  @override
  State<ShipmentsPage> createState() => _ShipmentsPageState();
}

class _ShipmentsPageState extends State<ShipmentsPage> {
  String _selectedFilter = 'في المستودع'.tr;

  final List<String> _filters = [
    'الكل'.tr,
    'تم الطلب'.tr,
    'في المستودع'.tr,
    'في الطريق'.tr,
    'تم التسليم'.tr,
  ];

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
          leading: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_none,
                  color: Color(0xFF475569),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsPage(),
                    ),
                  );
                },
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE71D24),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.search, color: Color(0xFF475569)),
              onPressed: () {},
            ),
          ],
        ),
        body: Column(
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
                decoration: InputDecoration(
                  hintText: 'ابحث برقم الشحنة'.tr,
                  hintStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
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
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildShipmentCard(
                    trackingNumber: '8742638',
                    status: 'في المستودع'.tr,
                    statusColor: const Color(0xFF3B82F6),
                    imageUrl:
                        'https://images.pexels.com/photos/6169056/pexels-photo-6169056.jpeg?auto=compress&cs=tinysrgb&w=300',
                    step: 2,
                    weight: '2.5',
                    date: '12 مايو'.tr,
                    buttonDisabled: false,
                  ),
                  SizedBox(height: 16),
                  _buildShipmentCard(
                    trackingNumber: '6654429',
                    status: 'في الطريق'.tr,
                    statusColor: const Color(0xFFF59E0B),
                    imageUrl:
                        'https://images.pexels.com/photos/4393665/pexels-photo-4393665.jpeg?auto=compress&cs=tinysrgb&w=300',
                    step: 2,
                    weight: '1.2',
                    date: '9 مايو'.tr,
                    buttonDisabled: false,
                    isIconPlay: true,
                  ),
                  SizedBox(height: 16),
                  _buildShipmentCard(
                    trackingNumber: '9927715',
                    status: 'تم التسليم'.tr,
                    statusColor: const Color(0xFF10B981),
                    imageUrl:
                        'https://images.pexels.com/photos/4246119/pexels-photo-4246119.jpeg?auto=compress&cs=tinysrgb&w=300',
                    step: 2,
                    weight: '1.9',
                    date: '9 مايو'.tr,
                    buttonDisabled: true,
                    isIconCheck: true,
                  ),
                  SizedBox(height: 32),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'لا توجد شحنات حاليا'.tr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'ابدأ بطلب توصيل جديد'.tr,
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 80),
                ],
              ),
            ),
          ],
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
                child: Image.network(
                  imageUrl,
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
                  onPressed: buttonDisabled ? null : () {},
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
