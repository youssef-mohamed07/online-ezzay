import os

with open('lib/views/screens/shipment_details_page.dart', 'r') as f:
    content = f.read()

new_content = """import 'package:online_ezzy/core/app_translations.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchDetails();
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
                  'رقم التتبع : ${widget.trackingNumber}'.tr,
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
                    widget.status,
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

  Widget _buildTimelineCard() {
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
          _buildTimelineStep(title: 'تم الطلب'.tr, date: '10 مايو'.tr, isCompleted: true, isLast: false),
          _buildTimelineStep(title: 'في الصندوق'.tr, date: '11 مايو'.tr, isCompleted: true, isLast: false),
          _buildTimelineStep(title: 'في الطريق'.tr, date: '12 مايو'.tr, isActive: widget.status == 'في الطريق'.tr, isCompleted: widget.status == 'تم التسليم'.tr, isLast: false),
          _buildTimelineStep(title: 'تم التسليم'.tr, date: '', isCompleted: widget.status == 'تم التسليم'.tr, isLast: true),
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
    final statusHistory = _details?['history'] as List?;
    final lastUpdate = statusHistory != null && statusHistory.isNotEmpty ? statusHistory.last['date']?.toString() : widget.date;
    final carrier = _details?['carrier']?.toString() ?? 'أرامكس - Aramex';

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
          _buildDetailRow('الوزن'.tr, '${widget.weight} كجم'.tr),
          const Divider(height: 30, color: Color(0xFFF1F5F9)),
          _buildDetailRow('تاريخ التحديث'.tr, lastUpdate ?? widget.date),
          const Divider(height: 30, color: Color(0xFFF1F5F9)),
          _buildDetailRow('شركة الشحن'.tr, carrier.tr),
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
"""

with open('lib/views/screens/shipment_details_page.dart', 'w') as f:
    f.write(new_content)

