import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_ezzy/providers/product_provider.dart';
import 'package:online_ezzy/providers/cart_provider.dart';

class PackagesPage extends StatefulWidget {
  const PackagesPage({
    super.key,
    this.categoryId = 68,
    this.categoryIds,
    this.pageTitle = 'طلب توصيل',
  });

  final int categoryId;
  final List<int>? categoryIds;
  final String pageTitle;

  @override
  State<PackagesPage> createState() => _PackagesPageState();
}

class _PackagesPageState extends State<PackagesPage> {
  static const Set<int> _addressCategoryIdSet = {69, 70, 77};
  static const String _insideAddressImageUrl =
      'https://images.pexels.com/photos/196667/pexels-photo-196667.jpeg?auto=compress&cs=tinysrgb&w=600';
  static const String _chinaAddressImageUrl =
      'https://images.pexels.com/photos/17233267/pexels-photo-17233267.jpeg?auto=compress&cs=tinysrgb&w=600';
  static const String _usAddressImageUrl =
      'https://images.pexels.com/photos/466685/pexels-photo-466685.jpeg?auto=compress&cs=tinysrgb&w=600';

  int? _selectedCategoryId;

  String? _extractRemoteProductImage(Map<String, dynamic> product) {
    final imagesRaw = product['images'];
    if (imagesRaw is List && imagesRaw.isNotEmpty) {
      for (final img in imagesRaw) {
        if (img is Map) {
          final src = img['src']?.toString().trim() ?? '';
          if (src.startsWith('http')) return src;
        }
      }
    }

    final imageRaw = product['image'];
    if (imageRaw is Map) {
      final src = imageRaw['src']?.toString().trim() ?? '';
      if (src.startsWith('http')) return src;
    }

    return null;
  }

  bool _isDeliveryPack(Map<String, dynamic> product) {
    final name = product['name']?.toString().toLowerCase() ?? '';
    if (name.contains('توصيل') || name.contains('delivery')) return true;

    final cats = product['categories'];
    if (cats is List) {
      return cats.any((c) {
        final catName = (c is Map ? c['name'] : '').toString().toLowerCase();
        return catName.contains('توصيل') || catName.contains('delivery');
      });
    }

    return false;
  }

  int? _parseInt(dynamic value) {
    return int.tryParse(value?.toString() ?? '');
  }

  bool _productBelongsToCategory(Map<String, dynamic> product, int categoryId) {
    final cats = product['categories'];
    if (cats is! List) return false;

    for (final cat in cats) {
      if (cat is! Map) continue;
      final id = _parseInt(cat['id']);
      if (id == categoryId) return true;
    }

    return false;
  }

  List<dynamic> _filteredItems(List<dynamic> source) {
    final selected = _selectedCategoryId;
    if (selected == null) return source;

    return source.where((item) {
      if (item is! Map) return false;
      final product = Map<String, dynamic>.from(item);
      return _productBelongsToCategory(product, selected);
    }).toList();
  }

  Map<int, int> _buildLocalCategoryCounts(List<dynamic> products) {
    final counts = <int, int>{};

    for (final item in products) {
      if (item is! Map) continue;

      final product = Map<String, dynamic>.from(item);
      final cats = product['categories'];
      if (cats is! List) continue;

      final countedForThisProduct = <int>{};
      for (final cat in cats) {
        if (cat is! Map) continue;
        final id = _parseInt(cat['id']);
        if (id == null || countedForThisProduct.contains(id)) continue;
        countedForThisProduct.add(id);
        counts[id] = (counts[id] ?? 0) + 1;
      }
    }

    return counts;
  }

  String _selectedCategoryName(List<dynamic> categories) {
    final selected = _selectedCategoryId;
    if (selected == null) return '';

    for (final cat in categories) {
      if (cat is! Map) continue;
      final id = _parseInt(cat['id']);
      if (id != selected) continue;

      final name = cat['name']?.toString().trim() ?? '';
      if (name.isNotEmpty) return name;
    }

    return 'التصنيف المحدد';
  }

  bool _isAddressCategoryId(int id) => _addressCategoryIdSet.contains(id);

  bool get _isAddressHubMode {
    final ids = widget.categoryIds;
    if (ids == null || ids.isEmpty) return false;
    return ids.any(_isAddressCategoryId);
  }

  String _categoryNameById(List<dynamic> categories, int categoryId) {
    for (final cat in categories) {
      if (cat is! Map) continue;
      final id = _parseInt(cat['id']);
      if (id != categoryId) continue;
      final name = cat['name']?.toString().trim() ?? '';
      if (name.isNotEmpty) return name;
    }
    return 'عنوان';
  }

  String _addressCategoryImageUrl({
    required int categoryId,
    required String categoryName,
  }) {
    final normalizedName = categoryName
        .trim()
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .toLowerCase();

    // Name has higher priority than id to avoid wrong mapping if backend ids change.
    if (normalizedName.contains('امريك') ||
        normalizedName.contains('america') ||
        normalizedName.contains('usa') ||
        normalizedName.contains('us')) {
      return _usAddressImageUrl;
    }

    if (normalizedName.contains('صين') || normalizedName.contains('china')) {
      return _chinaAddressImageUrl;
    }

    if (normalizedName.contains('داخل') || normalizedName.contains('محلي')) {
      return _insideAddressImageUrl;
    }

    if (categoryId == 77) return _usAddressImageUrl;
    if (categoryId == 70) return _chinaAddressImageUrl;
    if (categoryId == 69) return _insideAddressImageUrl;

    return _insideAddressImageUrl;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      provider.loadDeliveryProducts(
        categoryId: widget.categoryId,
        categoryIds: widget.categoryIds,
      );
    });
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
            widget.pageTitle,
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

            final isAddressHubPage = _isAddressHubMode;
            final allProducts = productProvider.deliveryProducts;

            if (isAddressHubPage) {
              final allCategoryIds = widget.categoryIds ?? const <int>[];
              final addressCategoryIds = allCategoryIds
                  .where(_isAddressCategoryId)
                  .toSet()
                  .toList();
              final categories = productProvider.categories;

              if (addressCategoryIds.isEmpty) {
                return const Center(
                  child: Text(
                    'لا توجد فئات عناوين متاحة حالياً',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    ...addressCategoryIds.map((categoryId) {
                      final categoryName = _categoryNameById(
                        categories,
                        categoryId,
                      );
                      final fixedImageUrl = _addressCategoryImageUrl(
                        categoryId: categoryId,
                        categoryName: categoryName,
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 22),
                        child: _buildAddressCategoryCard(
                          title: categoryName,
                          remoteImageUrl: fixedImageUrl,
                          fallbackImageUrl:
                              'lib/assets/images/home/العناوين.png',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PackagesPage(
                                  categoryId: categoryId,
                                  pageTitle: categoryName,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            }

            final items = _filteredItems(allProducts);
            final categories = productProvider.categories;
            final localCategoryCounts = _buildLocalCategoryCounts(allProducts);
            final visibleCategories = categories.where((cat) {
              if (cat is! Map) return false;
              final id = _parseInt(cat['id']);
              if (id == null) return false;
              final localCount = localCategoryCounts[id] ?? 0;
              return localCount > 0 || _selectedCategoryId == id;
            }).toList();
            final isFilteringByCategory = _selectedCategoryId != null;
            final selectedCategoryName = _selectedCategoryName(categories);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'اختر الباقة المناسبة لك',
                    style: TextStyle(
                      fontSize: 32,
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
                  if (visibleCategories.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF0F172A,
                            ).withValues(alpha: 0.04),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.tune_rounded,
                                size: 18,
                                color: Color(0xFFE71D24),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'فلترة حسب التصنيف',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const Spacer(),
                              const SizedBox.shrink(),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'اختر التصنيف المناسب لعرض الباقات',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildCategoryChip(
                                label: 'الكل',
                                isSelected: _selectedCategoryId == null,
                                onTap: () {
                                  if (_selectedCategoryId == null) return;
                                  setState(() => _selectedCategoryId = null);
                                },
                              ),
                              ...visibleCategories.map<Widget>((cat) {
                                final catMap = Map<String, dynamic>.from(
                                  cat as Map,
                                );
                                final catId = _parseInt(catMap['id']);
                                if (catId == null) {
                                  return const SizedBox.shrink();
                                }

                                final catName =
                                    catMap['name']
                                            ?.toString()
                                            .trim()
                                            .isNotEmpty ==
                                        true
                                    ? catMap['name'].toString().trim()
                                    : 'تصنيف';

                                return _buildCategoryChip(
                                  label: catName,
                                  isSelected: _selectedCategoryId == catId,
                                  onTap: () {
                                    setState(() {
                                      _selectedCategoryId =
                                          _selectedCategoryId == catId
                                          ? null
                                          : catId;
                                    });
                                  },
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (items.isEmpty && !productProvider.isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(
                            isFilteringByCategory
                                ? Icons.category_outlined
                                : Icons.wifi_off_rounded,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isFilteringByCategory
                                ? 'لا توجد باقات داخل $selectedCategoryName'
                                : 'تعذر تحميل الباقات',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isFilteringByCategory
                                ? 'اختر تصنيفاً آخر أو اضغط على الكل لعرض كل الباقات.'
                                : 'لا توجد باقات متاحة حالياً، يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (isFilteringByCategory) {
                                setState(() => _selectedCategoryId = null);
                                return;
                              }
                              Provider.of<ProductProvider>(
                                context,
                                listen: false,
                              ).loadDeliveryProducts(
                                categoryId: widget.categoryId,
                                categoryIds: widget.categoryIds,
                              );
                            },
                            icon: Icon(
                              isFilteringByCategory
                                  ? Icons.filter_alt_off_rounded
                                  : Icons.refresh_rounded,
                            ),
                            label: Text(
                              isFilteringByCategory
                                  ? 'عرض كل الباقات'
                                  : 'إعادة المحاولة',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE71D24),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
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
                    final product = Map<String, dynamic>.from(prod as Map);
                    final name = product['name']?.toString() ?? 'بدون اسم';
                    final price = product['price']?.toString() ?? '0';
                    final productId = int.tryParse(prod['id'].toString()) ?? 0;
                    final remoteImage = _extractRemoteProductImage(product);
                    final isDeliveryPack = _isDeliveryPack(product);

                    // Parse categories to optionally change image
                    bool isAddress = false;
                    final cats = product['categories'] as List?;
                    if (cats != null) {
                      isAddress = cats.any(
                        (c) =>
                            c['name'].toString().contains('عناوين') ||
                            c['name'].toString().contains('العنوان'),
                      );
                    }

                    // Extract features from short_description or fallbacks
                    List<String> features = [];
                    final desc = product['short_description']?.toString() ?? '';
                    if (desc.isNotEmpty) {
                      // Very simple stripped HTML
                      final stripped = desc
                          .replaceAll(RegExp(r'<[^>]*>'), '')
                          .trim();
                      if (stripped.isNotEmpty) {
                        features = stripped
                            .split('\n')
                            .where((s) => s.trim().isNotEmpty)
                            .toList();
                      }
                    }
                    if (features.isEmpty) {
                      features = isAddress
                          ? ['عنوان دولي مخصص لك']
                          : ['مرونة كاملة في عدد الطرود'];
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _buildPackageCard(
                        productId: productId,
                        remoteImageUrl: remoteImage,
                        imageUrl: isAddress
                            ? 'lib/assets/images/home/العناوين.png'
                            : 'lib/assets/images/home/اطلب توصيل.png',
                        title: name,
                        subtitle: '$price جنيه',
                        features: features,
                        isDeliveryPack: isDeliveryPack,
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

  Widget _buildAddressCategoryCard({
    required String title,
    required String? remoteImageUrl,
    required String fallbackImageUrl,
    required VoidCallback onTap,
  }) {
    final hasRemoteImage =
        remoteImageUrl != null && remoteImageUrl.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 180,
              child: hasRemoteImage
                  ? Image.network(
                      remoteImageUrl,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          fallbackImageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.place_rounded,
                            size: 72,
                            color: Color(0xFFE2E8F0),
                          ),
                        );
                      },
                    )
                  : Image.asset(
                      fallbackImageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.place_rounded,
                        size: 72,
                        color: Color(0xFFE2E8F0),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4137),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'تعرف على الباقات',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFE71D24).withValues(alpha: 0.1)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFE71D24)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFFE71D24)
                      : const Color(0xFF475569),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackageCard({
    required int productId,
    required String? remoteImageUrl,
    required String imageUrl,
    required String title,
    required String subtitle,
    required List<String> features,
    required bool isDeliveryPack,
  }) {
    final hasRemoteImage = remoteImageUrl != null && remoteImageUrl.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 240,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasRemoteImage)
                  Image.network(
                    remoteImageUrl,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildLocalImageFallback(
                        imageUrl: imageUrl,
                        isDeliveryPack: isDeliveryPack,
                      );
                    },
                  )
                else
                  _buildLocalImageFallback(
                    imageUrl: imageUrl,
                    isDeliveryPack: isDeliveryPack,
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.02),
                        Colors.black.withValues(alpha: 0.45),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE71D24),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'خيار مميز',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const Text(
                  'سعر الباقة',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  textAlign: TextAlign.center,
                ),
                if (features.isNotEmpty) const SizedBox(height: 24),
                ...features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFECEC),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Color(0xFFE71D24),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(
                              fontSize: 14,
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
                Selector<CartProvider, _PackageCartUiState>(
                  selector: (context, cartProvider) {
                    final cartItem = cartProvider.cartItems
                        .cast<dynamic>()
                        .firstWhere(
                          (item) =>
                              item is Map &&
                              item['id'].toString() == productId.toString(),
                          orElse: () => null,
                        );

                    return _PackageCartUiState(
                      isInCart: cartItem != null,
                      isAdding: cartProvider.isAddingProduct(productId),
                    );
                  },
                  builder: (context, cartState, child) {
                    if (cartState.isInCart) {
                      return Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFE71D24,
                          ).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(
                              0xFFE71D24,
                            ).withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFFE71D24),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'تم اختيار الباقة',
                              style: TextStyle(
                                color: Color(0xFFE71D24),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: cartState.isAdding
                            ? null
                            : () async {
                                final success = await context
                                    .read<CartProvider>()
                                    .addToCart(productId, 1);
                                if (!context.mounted || success) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('فشل إضافة الباقة للسلة'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE71D24),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: cartState.isAdding
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'اختار الباقة',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalImageFallback({
    required String imageUrl,
    required bool isDeliveryPack,
  }) {
    if (isDeliveryPack) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF4D4D), Color(0xFFE71D24)],
          ),
        ),
        child: Center(
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              size: 86,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Center(
        child: Image.asset(
          imageUrl,
          fit: BoxFit.contain,
          width: 110,
          height: 110,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.inventory, size: 80, color: Colors.grey),
        ),
      ),
    );
  }
}

class _PackageCartUiState {
  const _PackageCartUiState({required this.isInCart, required this.isAdding});

  final bool isInCart;
  final bool isAdding;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _PackageCartUiState &&
        other.isInCart == isInCart &&
        other.isAdding == isAdding;
  }

  @override
  int get hashCode => Object.hash(isInCart, isAdding);
}
