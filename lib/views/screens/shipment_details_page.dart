import 'package:online_ezzy/core/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:online_ezzy/providers/shipment_provider.dart';
import 'package:provider/provider.dart';

class ShipmentDetailsPage extends StatefulWidget {
  final String trackingNumber;
  final String status;
  final String weight;
  final String date;

  const ShipmentDetailsPage({
    super.key,
    required this.trackingNumber,
    required this.status,
    required this.weight,
    required this.date,
  });

  @override
  State<ShipmentDetailsPage> createState() => _ShipmentDetailsPageState();
}

class _ShipmentDetailsPageState extends State<ShipmentDetailsPage> {
  Map<String, dynamic>? _details;
  bool _isLoading = true;

  String get _effectiveStatus {
    return (_details?['current_status'] ??
            _details?['status'] ??
            _details?['shipment_status'] ??
            widget.status)
        .toString();
  }

  String get _effectiveTrackingNumber {
    return (_details?['tracking_number'] ??
            _details?['number'] ??
            widget.trackingNumber)
        .toString();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fetchDetails();
    });
  }

  Future<void> _fetchDetails() async {
    final provider = context.read<ShipmentProvider>();
    final data = await provider.getShipmentDetails(widget.trackingNumber);
    if (mounted) {
      setState(() {
        _details = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: Text(
            'تفاصيل الشحنة'.tr,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFE71D24))),
      );
    }

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
            'تفاصيل الشحنة'.tr,
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              SizedBox(height: 16),
              _buildTimelineCard(),
              SizedBox(height: 16),
              _buildDetailsCard(),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final imageUrl = _details?['image']?.toString() ?? _details?['image_url']?.toString();
    final status = _effectiveStatus;
    final trackingNumber = _effectiveTrackingNumber;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              image: imageUrl != null && imageUrl.isNotEmpty ? DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ) : null,
            ),
            child: imageUrl == null || imageUrl.isEmpty ? const Icon(Icons.inventory_2_outlined, color: Color(0xFFE71D24), size: 30) : null,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'رقم التتبع : $trackingNumber'.tr,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE71D24).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE71D24).withOpacity(0.5)),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Color(0xFFE71D24),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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

  List<Map<String, String>> _extractHistoryItems() {
    final historyRaw =
        _details?['status_history'] ??
        _details?['history'] ??
        _details?['timeline'] ??
        _details?['events'] ??
        _details?['steps'];

    if (historyRaw is! List || historyRaw.isEmpty) {
      return const <Map<String, String>>[];
    }

    final result = <Map<String, String>>[];
    for (final item in historyRaw) {
      if (item is! Map) continue;

      final title =
          (item['title'] ?? item['status'] ?? item['description'] ?? '')
              .toString()
              .trim();
      if (title.isEmpty) continue;

      final date =
          (item['date'] ??
              item['changed_at'] ??
              item['time'] ??
              item['timestamp'] ??
              '')
              .toString()
              .trim();

      result.add({'title': title, 'date': date});
    }

    return result;
  }

  Widget _buildTimelineCard() {
    final historyItems = _extractHistoryItems();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'حالة الشحنة'.tr,
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 24),
          if (historyItems.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                'لا يوجد خط زمني متاح لهذه الشحنة حالياً'.tr,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            )
          else
            ...historyItems.asMap().entries.map((entry) {
              final index = entry.key;
              final event = entry.value;
              return _buildTimelineStep(
                title: event['title'] ?? 'تحديث الشحنة'.tr,
                date: event['date'] ?? '',
                isCompleted: true,
                isLast: index == historyItems.length - 1,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({required String title, required String date, bool isCompleted = false, bool isActive = false, required bool isLast}) {
    Color color = isCompleted || isActive ? const Color(0xFFE71D24) : const Color(0xFFE2E8F0);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0xFFE71D24) : (isActive ? Colors.white : Colors.white),
                border: Border.all(color: color, width: isActive ? 4 : 2),
                shape: BoxShape.circle,
              ),
              child: isCompleted
                  ? Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: color,
              ),
          ],
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isCompleted || isActive ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (date.isNotEmpty) ...[
                SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
              SizedBox(height: 16), // Spacing for alignment
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    final statusHistory =
      (_details?['status_history'] ?? _details?['history']) as List?;
    final lastEntry =
        statusHistory != null && statusHistory.isNotEmpty
            ? statusHistory.last
            : null;
    final lastUpdate =
        lastEntry is Map
            ? (lastEntry['changed_at'] ?? lastEntry['date'])?.toString()
            : (_details?['date_added']?.toString() ?? widget.date);
    final carrier =
      (_details?['carrier'] ?? _details?['shipping_company'] ?? '')
        .toString();
    final weight =
      (_details?['weight'] ?? _details?['total_weight'] ?? widget.weight)
        .toString();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'معلومات إضافية'.tr,
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          _buildDetailRow('الوزن'.tr, '$weight كجم'.tr),
          const Divider(height: 30, color: Color(0xFFF1F5F9)),
          _buildDetailRow('تاريخ التحديث'.tr, lastUpdate ?? widget.date),
          const Divider(height: 30, color: Color(0xFFF1F5F9)),
          _buildDetailRow('شركة الشحن'.tr, carrier.isNotEmpty ? carrier : '-'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE71D24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'تتبع حي'.tr,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
