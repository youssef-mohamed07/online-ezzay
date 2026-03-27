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
                    const Text(
                      'لا يوجد باقات تأكد من اتصال الانترنت أو إعدادات المتجر',
                      style: TextStyle(color: Colors.red),
                    ),

                  ...items.map((prod) {
                    final name = prod['name']?.toString() ?? 'بدون اسم';
                    final price = prod['price']?.toString() ?? '0';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _buildPackageCard(
                        imageUrl: 'lib/assets/images/home/اطلب توصيل.png',
                        title: name,
                        subtitle: '$price جنيه',
                        features: ['مرونة كاملة في عدد الطرود'],
                        onPressed: () async {
                          final cartProvider = Provider.of<CartProvider>(
                            context,
                            listen: false,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('جاري الإضافة للسلة...'),
                            ),
                          );
                          final success = await cartProvider.addToCart(
                            int.parse(prod['id'].toString()),
                            1,
                          );
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
                      ),
                    );
                  }),

                  const SizedBox(height: 10),
                  // Fallback
                  _buildPackageCard(
                    imageUrl: 'lib/assets/images/home/العناوين.png',
                    title: 'باقة مخصصة (إضافية)',
                    subtitle: 'تحكم كامل في عدد الطرود والتكلفة.',
                    features: [
                      'تحديد عدد الطرود بحرية',
                      'حساب التكلفة تلقائيا',
                      'إحصائيات الشحنة',
                    ],
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CustomShipmentPage(),
                        ),
                      );
                    },
                  ),
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
    required String imageUrl,
    required String title,
    required String subtitle,
    required List<String> features,
    VoidCallback? onPressed,
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
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onPressed ?? () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE71D24),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'احصل علي الباقة',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
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
}
