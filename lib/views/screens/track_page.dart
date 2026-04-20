import 'package:online_ezzy/core/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_ezzy/providers/shipment_provider.dart';

import 'package:online_ezzy/data/real_images.dart';

class TrackPage extends StatefulWidget {
  const TrackPage({super.key, this.initialTrackingNumber});

  final String? initialTrackingNumber;

  @override
  State<TrackPage> createState() => _TrackPageState();
}

class _TrackPageState extends State<TrackPage> {
  late final TextEditingController _trackingController;
  Map<String, dynamic>? _trackingData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _trackingController = TextEditingController(
      text: widget.initialTrackingNumber ?? '',
    );

    if ((widget.initialTrackingNumber ?? '').trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _trackShipment());
    }
  }

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  Future<void> _trackShipment() async {
    final number = _trackingController.text.trim();
    if (number.isEmpty) {
      setState(() {
        _error = 'برجاء إدخال رقم الشحنة'.tr;
        _trackingData = null;
      });
      return;
    }

    setState(() {
      _error = null;
    });

    final result = await context.read<ShipmentProvider>().trackShipment(number);
    if (!mounted) return;

    final payload = _extractPayload(result);
    if (payload == null || payload.isEmpty) {
      setState(() {
        _trackingData = null;
        _error = 'تعذر العثور على الشحنة'.tr;
      });
      return;
    }

    setState(() {
      _trackingData = payload;
      _error = null;
    });
  }

  Map<String, dynamic>? _extractPayload(Map<String, dynamic>? data) {
    if (data == null) return null;
    final nested = data['data'];
    if (nested is Map<String, dynamic>) {
      return nested;
    }
    return data;
  }

  List<_TimelineItem> _buildTimeline(Map<String, dynamic> data) {
    final timelineRaw =
        data['status_history'] ??
        data['timeline'] ??
        data['history'] ??
        data['events'] ??
        data['steps'];

    if (timelineRaw is List && timelineRaw.isNotEmpty) {
      return timelineRaw
          .whereType<Map>()
          .map((event) {
            final title =
                (event['title'] ?? event['status'] ?? event['description'] ?? 'تحديث الشحنة'.tr)
                    .toString();
            final subtitle =
              (event['subtitle'] ??
                  event['date'] ??
                  event['changed_at'] ??
                  event['time'] ??
                  event['timestamp'] ??
                  '')
                    .toString();

            final doneValue = event['is_done'] ?? event['done'] ?? event['completed'];
            final isDone = doneValue == null
              ? true
              : (doneValue is bool
                  ? doneValue
                  : doneValue.toString().toLowerCase() == 'true');

            return _TimelineItem(title, subtitle, isDone);
          })
          .toList();
    }

    return const <_TimelineItem>[];
  }

  double _resolveProgress(Map<String, dynamic> data, List<_TimelineItem> timeline) {
    final raw = data['progress'];
    if (raw is num) {
      if (raw > 1) return (raw / 100).clamp(0.0, 1.0);
      return raw.toDouble().clamp(0.0, 1.0);
    }

    final done = timeline.where((item) => item.isDone).length;
    if (timeline.isEmpty) return 0;
    return (done / timeline.length).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ShipmentProvider>().isLoading;
    final trackingData = _trackingData;
    final timeline =
        trackingData == null ? <_TimelineItem>[] : _buildTimeline(trackingData);
    final progress =
        trackingData == null ? 0.0 : _resolveProgress(trackingData, timeline);
    final trackingNumber =
        (trackingData?['tracking_number'] ??
                trackingData?['number'] ??
                _trackingController.text.trim())
            .toString();
    final status =
      (trackingData?['current_status'] ??
          trackingData?['status'] ??
          trackingData?['shipment_status'] ??
          '')
        .toString();
    final origin = (trackingData?['origin'] ?? trackingData?['from'] ?? '').toString();
    final destination =
        (trackingData?['destination'] ?? trackingData?['to'] ?? '').toString();
    final eta =
        (trackingData?['eta'] ??
                trackingData?['expected_delivery'] ??
                trackingData?['delivery_date'] ??
          trackingData?['date_added'] ??
                '')
            .toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 145,
                width: double.infinity,
                child: Image.network(
                  RealImages.trackHero,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 16),
            Text('تتبع الشحنة'.tr, style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 10),
            Text(
              'استخدم رقم الشحنة لمتابعة المسار وموعد الوصول ونقاط التحديث.'.tr,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _trackingController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _trackShipment(),
              decoration: InputDecoration(
                labelText: 'رقم الشحنة'.tr, hintText: 'ادخل رقم الشحنة (مثال: EZ-94012)'.tr, floatingLabelBehavior: FloatingLabelBehavior.auto,
                prefixIcon: Icon(Icons.search_rounded),
                suffixIcon: FilledButton(
                  onPressed: isLoading ? null : _trackShipment,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('تتبع'.tr),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                filled: true,
              ),
            ),
            if (isLoading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(minHeight: 4),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFCDD2)),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFB91C1C)),
                ),
              ),
            ],
            if (trackingData != null) ...[
            SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الشحنة $trackingNumber'.tr,
                        style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: 6),
                    Text(
                      [origin, destination]
                          .where((value) => value.isNotEmpty)
                          .join('   '),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: 14),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      valueColor:
                          const AlwaysStoppedAnimation(Color(0xFFE71D24)),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'اكتمل ${(progress * 100).toStringAsFixed(0)}%  ${eta.isNotEmpty ? 'موعد الوصول: $eta'.tr : ''}',
                    ),
                    if (status.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('الحالة الحالية: $status'),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'الخط الزمني للمسار'.tr,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            if (timeline.isEmpty)
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
              ...timeline.map((item) => _TimelineTile(item: item)),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimelineItem {
  const _TimelineItem(this.title, this.subtitle, this.isDone);
  final String title;
  final String subtitle;
  final bool isDone;
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.item});

  final _TimelineItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.isDone ? const Color(0xFFE71D24) : const Color(0xFF9AAEC1);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: item.isDone ? color : Colors.white,
                border: Border.all(color: color, width: 2),
                shape: BoxShape.circle,
              ),
            ),
            Container(width: 2, height: 54, color: const Color(0xFFD7E1EA)),
          ],
        ),
        SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 2),
                Text(item.subtitle),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
