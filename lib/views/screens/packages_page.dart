import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_ezzy/providers/product_provider.dart';
import 'package:online_ezzy/providers/cart_provider.dart';
import 'custom_shipment_page.dart';

class PackagesPage extends StatefulWidget {
  const PackagesPage({super.key});

  @override
  State<PackagesPage> createState() => _PackagesPageState();
}

class _PackagesPageState extends State<PackagesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: const Text(
            'طلب توصيل',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Consumer<ProductProvider>(
          builder: (context, productProvider, child) {
            if (productProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFE71D24)),
              );
            }

            final items = productProvider.products;
            final categories = productProvider.categories;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'اختر الباقة المناسبة لك',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'اختر الباقة المناسبة لتوصيل طرودك',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 32),
                  if (items.isEmpty && !productProvider.isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.wifi_off_rounded,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'تعذر تحميل الباقات',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'لا توجد باقات متاحة حالياً، يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              Provider.of<ProductProvider>(context, listen: false).loadProducts();
                            },
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('إعادة المحاولة', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE71D24),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ),

                  ...items.map((prod) {
                    final name = prod['name']?.toString() ?? 'بدون اسم';
                    final price = prod['price']?.toString() ?? '0';
                    final productId = int.tryParse(prod['id'].toString()) ?? 0;
                    
                    // Parse categories to optionally change image
                    bool isAddress = false;
                    final cats = prod['categories'] as List?;
                    if (cats != null) {
                      isAddress = cats.any((c) => c['name'].toString().contains('عناوين') || c['name'].toString().contains('العنوان'));
                    }

                    // Extract features from short_description or fallbacks
                    List<String> features = [];
                    final desc = prod['short_description']?.toString() ?? '';
                    if (desc.isNotEmpty) {
                        // Very simple stripped HTML
                        final stripped = desc.replaceAll(RegExp(r'<[^>]*>'), '').trim();
                        if (stripped.isNotEmpty) {
                          features = stripped.split('\n').where((s) => s.trim().isNotEmpty).toList();
                        }
                    }
                    if (features.isEmpty) {
                      features = isAddress ? ['عنوان دولي مخصص لك'] : ['مرونة كاملة في عدد الطرود'];
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _buildPackageCard(
                        productId: productId,
                        imageUrl: isAddress ? 'lib/assets/images/home/العناوين.png' : 'lib/assets/images/home/اطلب توصيل.png',
                        title: name,
                        subtitle: '$price جنيه',
                        features: features,
                      ),
                    );
                  }),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPackageCard({
    required int productId,
    required String imageUrl,
    required String title,
    required String subtitle,
    required List<String> features,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 180,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Image.asset(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.inventory, size: 80, color: Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (features.isNotEmpty) const SizedBox(height: 24),
                ...features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: Color(0xFFE71D24),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF334155),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Consumer<CartProvider>(
                  builder: (context, cartProvider, child) {
                    final cartItem = cartProvider.cartItems.firstWhere(
                        (item) => item['id'].toString() == productId.toString(),
                        orElse: () => null);

                    final isInCart = cartItem != null;
                    final quantity = isInCart ? (cartItem['quantity'] as int? ?? 1) : 0;
                    final itemKey = isInCart ? cartItem['key'].toString() : null;

                    if (isInCart) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () async {
                              if (cartProvider.isLoading) return;
                              final newQty = quantity + 1;
                              await cartProvider.updateCartItemQuantity(itemKey!, newQty);
                            },
                            icon: const Icon(Icons.add_circle, color: Color(0xFFE71D24), size: 30),
                          ),
                          Text(
                            '$quantity',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              if (cartProvider.isLoading) return;
                              final newQty = quantity - 1;
                              if (newQty < 1) {
                                await cartProvider.removeCartItem(itemKey!);
                              } else {
                                await cartProvider.updateCartItemQuantity(itemKey!, newQty);
                              }
                            },
                            icon: const Icon(Icons.remove_circle, color: Colors.grey, size: 30),
                          ),
                        ],
                      );
                    }

                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: cartProvider.isLoading ? null : () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('جاري الإضافة للسلة...')),
                          );
                          final success = await cartProvider.addToCart(productId, 1);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم إضافة الباقة للسلة بنجاح!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('فشل إضافة الباقة للسلة'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE71D24),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: cartProvider.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'احصل علي الباقة',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    );
                  }
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
