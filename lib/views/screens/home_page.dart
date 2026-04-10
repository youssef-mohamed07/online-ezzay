import 'package:online_ezzy/core/app_translations.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_ezzy/providers/auth_provider.dart';
import 'package:online_ezzy/providers/product_provider.dart';
import 'package:online_ezzy/providers/cart_provider.dart';
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
  const _TopHeader({required this.onTapNotification});

  final VoidCallback onTapNotification;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final userName = auth.userData?['first_name'] ?? 'ضيف';
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'مرحبا ',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'لديك 0 شحنات نشطة',
                  style: TextStyle(
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
                  onTap: onTapNotification,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFF1E293B),
                        size: 28,
                      ),
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
                    child: Text(
                      userName.isNotEmpty ? userName[0] : 'ك',
                      style: const TextStyle(
                        color: Color(0xFFE71D24),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
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
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
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
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
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
                return Image.network(
                  images[i],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade300,
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                        size: 40,
                      ),
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
  _SectionTitle(this.title);
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
              child: const TextField(
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: 'أدخل رقم التتبع',
                  hintStyle: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            onPressed: () {},
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
  const _ActiveShipmentCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                    child: Icon(
                      Icons.inventory_2_rounded,
                      size: 28,
                      color: Color(0xFFC68A5A),
                    ),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'طرد أمازون',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'رقم التتبع #2638',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B).withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5E6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'في الصندوق'.tr,
                  style: TextStyle(
                    color: Color(0xFFD97706),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _buildTimelineStep(
                  'في الصندوق'.tr,
                  isActive: false,
                  isCompleted: true,
                ),
              ),
              _buildTimelineLine(isCompleted: true),
              Expanded(
                child: _buildTimelineStep(
                  'في الطريق'.tr,
                  isActive: true,
                  isCompleted: false,
                ),
              ),
              _buildTimelineLine(isCompleted: false),
              Expanded(
                child: _buildTimelineStep(
                  'تم التسليم'.tr,
                  isActive: false,
                  isCompleted: false,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
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
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFFE71D24)
                : (isActive ? const Color(0xFFE71D24) : Colors.white),
            shape: BoxShape.circle,
            border: Border.all(
              color: isCompleted || isActive
                  ? const Color(0xFFE71D24)
                  : const Color(0xFFCBD5E1),
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check, color: Colors.white, size: 14)
                : (isActive
                      ? Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        )
                      : Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFCBD5E1),
                            shape: BoxShape.circle,
                          ),
                        )),
          ),
        ),
        SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive || isCompleted
                ? FontWeight.bold
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

class _AddressCardsRow extends StatefulWidget {
  @override
  State<_AddressCardsRow> createState() => _AddressCardsRowState();
}

class _AddressCardsRowState extends State<_AddressCardsRow> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).loadProducts();
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

        List<dynamic> items = productProvider.products.where((p) {
          final cats = p['categories'] as List?;
          if (cats != null) {
            return cats.any((c) => c['name'].toString().contains('عناوين') || c['name'].toString().contains('عنوان'));
          }
          return false;
        }).toList();

        // Fallback for demo if no categories match perfectly
        if (items.isEmpty) {
          final nameMatches = productProvider.products.where((p) => p['name'].toString().contains('عنوان') || p['name'].toString().contains('عناوين')).toList();
          items = nameMatches.isNotEmpty ? nameMatches : productProvider.products;
        }

        if (items.isEmpty) {
          return const SizedBox(
            height: 154,
            child: Center(child: Text('لا يوجد عناوين حاليا', style: TextStyle(color: Colors.grey))),
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
                      '$price جنيه\nتعرف على تفاصيل العنوان',
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
                              (item) => item['id'].toString() == productId.toString(),
                              orElse: () => null);

                          final isInCart = cartItem != null;
                          final quantity = isInCart ? (cartItem['quantity'] as int? ?? 1) : 0;
                          final itemKey = isInCart ? cartItem['key'].toString() : null;

                          if (isInCart) {
                            return Container(
                              height: 36,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE71D24)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  InkWell(
                                    onTap: cartProvider.isLoading ? null : () async {
                                      await cartProvider.updateCartItemQuantity(itemKey!, quantity + 1);
                                    },
                                    child: const Icon(Icons.add, color: Color(0xFFE71D24), size: 18),
                                  ),
                                  Text(
                                    '$quantity',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  InkWell(
                                    onTap: cartProvider.isLoading ? null : () async {
                                      final newQty = quantity - 1;
                                      if (newQty < 1) {
                                        await cartProvider.removeCartItem(itemKey!);
                                      } else {
                                        await cartProvider.updateCartItemQuantity(itemKey!, newQty);
                                      }
                                    },
                                    child: const Icon(Icons.remove, color: Color(0xFFE71D24), size: 18),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ElevatedButton(
                            onPressed: cartProvider.isLoading ? null : () async {
                              await cartProvider.addToCart(productId, 1);
                            },
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
                            child: cartProvider.isLoading
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text(
                                    'اطلب الآن',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                          );
                        }
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
