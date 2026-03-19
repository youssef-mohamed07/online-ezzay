import 'package:online_ezzy/core/app_translations.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:online_ezzy/data/real_images.dart';
import 'packages_page.dart';
import 'profile_page.dart';
import 'address_page.dart';
import 'track_page.dart';
import 'shipments_page.dart';
import 'notifications_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  int _bannerIndex = 0;

  static const _bannerImages = [
    RealImages.homeHero,
    RealImages.trackHero,
    RealImages.shipmentsHero,
  ];

  @override
  void initState() {
    super.initState();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_bannerController.hasClients) return;
      final next = (_bannerIndex + 1) % _bannerImages.length;
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
              onTapNotification: () => _openPage(const NotificationsPage()),
            ),
            SizedBox(height: 28),
            _TopActionsRow(
              onTapDelivery: () => _openPage(const PackagesPage()),
              onTapAddress: () => _openPage(const AddressPage()),
              onTapTrack: () => _openPage(const ShipmentsPage()),
              onTapServices: () => _openPage(const PackagesPage()),
            ),
            SizedBox(height: 28),
            _HeroSlider(
              controller: _bannerController,
              images: _bannerImages,
              index: _bannerIndex,
              onPageChanged: (value) => setState(() => _bannerIndex = value),
            ),
            SizedBox(height: 28),
            _SectionTitle('تتبع الشحنة'.tr),
            SizedBox(height: 12),
            const _TrackingCard(),
            SizedBox(height: 24),
            _SectionTitle('الشحنات النشطة'),
            SizedBox(height: 12),
            const _ActiveShipmentCard(),
            SizedBox(height: 24),
            _SectionTitle('طرود في المستودع'),
            SizedBox(height: 12),
            _WarehouseOrderCard(onTap: () => _openPage(const PackagesPage())),
            SizedBox(height: 12),
            _WarehouseOrderCard(onTap: () => _openPage(const PackagesPage())),
            SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionTitle('العناوين'),
                GestureDetector(
                  onTap: () => _openPage(const PackagesPage()),
                  child: Text('الباقات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE71D24))),
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
  const _TopHeader({required this.onTapNotification});

  final VoidCallback onTapNotification;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('مرحبا كريم', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                SizedBox(width: 8),
                Text('', style: TextStyle(fontSize: 20)),
              ],
            ),
            SizedBox(height: 2),
            Text('لديك 3 شحنات نشطة', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: onTapNotification,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.notifications_none_rounded, color: Color(0xFF1E293B), size: 28),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE71D24),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFFFFC0B6),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('ك', style: TextStyle(color: Color(0xFFE71D24), fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ),
          ],
        ),
      ],
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
      children: [
        _ActionItem(
          title: 'اطلب توصيل',
          imagePath: 'lib/assets/images/home/اطلب توصيل.png',
          onTap: onTapDelivery,
        ),
        _ActionItem(
          title: 'العناوين',
          imagePath: 'lib/assets/images/home/العناوين.png',
          onTap: onTapAddress,
        ),
        _ActionItem(
          title: 'تتبع شحنتك',
          imagePath: 'lib/assets/images/home/تتبع شحنتك.png',
          onTap: onTapTrack,
        ),
        _ActionItem(
          title: 'خدمات مالية',
          imagePath: 'lib/assets/images/home/خدمات مالية.png',
          onTap: onTapServices,
        ),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.title,
    required this.imagePath,
    required this.onTap,
  });

  final String title;
  final String imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSlider extends StatelessWidget {
  const _HeroSlider({required this.controller, required this.images, required this.index, required this.onPageChanged});

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
                return Image.network(
                  images[i], 
                  fit: BoxFit.cover, 
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade300,
                    child: Center(
                      child: Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                    ),
                  ),
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
                color: active ? const Color(0xFFE71D24) : const Color(0xFFCBD5E1),
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
  _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.right,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
    );
  }
}

class _TrackingCard extends StatelessWidget {
  const _TrackingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Align(
                alignment: Alignment.centerRight,
                child: Text('أدخل رقم التتبع', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE71D24),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
              elevation: 0,
            ),
            child: Text('تتبع'.tr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class _ActiveShipmentCard extends StatelessWidget {
  const _ActiveShipmentCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5E6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.inventory_2_rounded, size: 28, color: Color(0xFFC68A5A)),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('طرد أمازون', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                      SizedBox(height: 2),
                      Text('رقم التتبع #2638', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B).withValues(alpha: 0.8))),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5E6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('في الصندوق'.tr, style: TextStyle(color: Color(0xFFD97706), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          SizedBox(height: 28),
          Row(
            children: [
              Expanded(child: _buildTimelineStep('في الصندوق'.tr, isActive: false, isCompleted: true)),
              _buildTimelineLine(isCompleted: true),
              Expanded(child: _buildTimelineStep('في الطريق'.tr, isActive: true, isCompleted: false)),
              _buildTimelineLine(isCompleted: false),
              Expanded(child: _buildTimelineStep('تم التسليم'.tr, isActive: false, isCompleted: false)),
            ],
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(String label, {required bool isActive, required bool isCompleted}) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isCompleted ? const Color(0xFFE71D24) : (isActive ? const Color(0xFFE71D24) : Colors.white),
            shape: BoxShape.circle,
            border: Border.all(
              color: isCompleted || isActive ? const Color(0xFFE71D24) : const Color(0xFFCBD5E1),
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted 
                ? Icon(Icons.check, color: Colors.white, size: 14)
                : (isActive ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)) 
                            : Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFCBD5E1), shape: BoxShape.circle))),
          ),
        ),
        SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.w600,
            color: isActive || isCompleted ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineLine({required bool isCompleted}) {
    return Expanded(
      child: Container(
        height: 2,
        color: isCompleted ? const Color(0xFFE71D24) : const Color(0xFFF1F5F9),
        margin: const EdgeInsets.only(bottom: 24),
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('اطلب إرسال طردك', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: onTap ?? () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE71D24),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: 0,
                ),
                child: Text('اطلب توصيل الآن', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5E6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.inventory_2_rounded, size: 36, color: Color(0xFFC68A5A)),
          ),
        ],
      ),
    );
  }
}

class _AddressCardsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 154,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          final titles = ['العنوان الامريكي', 'العنوان صيني', 'العنوان الايطالي'];
          return Container(
            width: 155,
            margin: const EdgeInsets.only(left: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(Icons.place_rounded, color: Color(0xFFE71D24), size: 18),
                    SizedBox(width: 6),
                    Expanded(child: Text(titles[index], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis)),
                  ],
                ),
                Text(
                  'تعرف على باقات العنوان\n${titles[index].replaceAll("العنوان ", "")}',
                  textAlign: TextAlign.start,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600, height: 1.4),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE71D24),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                    ),
                    child: Text('اطلب الآن', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
