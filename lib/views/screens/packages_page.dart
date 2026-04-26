import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_ezzy/core/api_service.dart';
import 'package:online_ezzy/providers/product_provider.dart';
import 'package:online_ezzy/providers/cart_provider.dart';
import 'package:online_ezzy/providers/settings_provider.dart';
import 'package:online_ezzy/widgets/cached_image.dart';
import 'package:online_ezzy/views/screens/cart_page.dart';

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

class _ProductVariationOption {
  const _ProductVariationOption({
    required this.id,
    required this.label,
    required this.price,
  });

  final int id;
  final String label;
  final double price;
}

class _PackagesPageState extends State<PackagesPage> {
  static const int _packagesOnlyCategoryId = 68;
  static const Set<int> _addressCategoryIdSet = {69, 70, 77};
  static const String _insideAddressImageUrl =
      'https://images.pexels.com/photos/196667/pexels-photo-196667.jpeg?auto=compress&cs=tinysrgb&w=600';
  static const String _chinaAddressImageUrl =
      'https://images.pexels.com/photos/17233267/pexels-photo-17233267.jpeg?auto=compress&cs=tinysrgb&w=600';
  static const String _usAddressImageUrl =
      'https://images.pexels.com/photos/466685/pexels-photo-466685.jpeg?auto=compress&cs=tinysrgb&w=600';

  int? _selectedCategoryId;
  final Map<int, Future<List<_ProductVariationOption>>>
  _variationOptionsFutureByProduct =
      <int, Future<List<_ProductVariationOption>>>{};
  final Map<int, int> _selectedVariationByProduct = <int, int>{};
  final Map<int, Set<int>> _variationIdsByProduct = <int, Set<int>>{};

  Future<List<_ProductVariationOption>> _variationOptionsFuture(int productId) {
    return _variationOptionsFutureByProduct.putIfAbsent(
      productId,
      () => _loadVariationOptions(productId),
    );
  }

  Future<List<_ProductVariationOption>> _loadVariationOptions(
    int productId,
  ) async {
    final rawVariations = await ApiService.getProductVariations(productId);
    final options = <_ProductVariationOption>[];

    for (final row in rawVariations) {
      if (row is! Map) continue;
      final variation = Map<String, dynamic>.from(row);

      final id = _parseInt(variation['id']);
      if (id == null || id <= 0) continue;

      final status = variation['status']?.toString().toLowerCase() ?? '';
      if (status.isNotEmpty && status != 'publish') continue;
      if (variation['purchasable'] == false) continue;

      final label = _variationOptionLabel(variation);
      final price = _parsePriceValue(
        variation['price'] ??
            variation['regular_price'] ??
            variation['sale_price'],
      );

      options.add(_ProductVariationOption(id: id, label: label, price: price));
    }

    options.sort((a, b) {
      final aNum = double.tryParse(a.label);
      final bNum = double.tryParse(b.label);
      if (aNum != null && bNum != null) {
        return aNum.compareTo(bNum);
      }
      return a.label.compareTo(b.label);
    });

    _variationIdsByProduct[productId] = options.map((e) => e.id).toSet();
    if (options.isNotEmpty) {
      _selectedVariationByProduct.putIfAbsent(
        productId,
        () => options.first.id,
      );
    }

    return options;
  }

  String _variationOptionLabel(Map<String, dynamic> variation) {
    final attrs = variation['attributes'];
    if (attrs is List) {
      final values = <String>[];
      for (final attr in attrs) {
        if (attr is! Map) continue;
        final value = attr['option']?.toString().trim() ?? '';
        if (value.isNotEmpty) values.add(value);
      }
      if (values.isNotEmpty) return values.join(' / ');
    }

    final name = variation['name']?.toString().trim() ?? '';
    if (name.isNotEmpty) return name;
    return 'خيار';
  }

  String? _extractCartVariationLabel(dynamic cartItem) {
    if (cartItem is! Map) return null;
    final variation = cartItem['variation'];
    if (variation is! List || variation.isEmpty) return null;

    final first = variation.first;
    if (first is! Map) return null;

    final attribute = first['attribute']?.toString().trim() ?? '';
    final value = first['value']?.toString().trim() ?? '';
    if (attribute.isNotEmpty && value.isNotEmpty) {
      return '$attribute: $value';
    }
    if (value.isNotEmpty) return value;
    return null;
  }

  int _extractCartQuantity(dynamic cartItem) {
    if (cartItem is! Map) return 0;

    final quantityRaw = cartItem['quantity'];
    if (quantityRaw is Map) {
      return int.tryParse((quantityRaw['value'] ?? '0').toString()) ?? 0;
    }

    return int.tryParse(quantityRaw?.toString() ?? '0') ?? 0;
  }

  bool _isCartItemQuantityEditable(dynamic cartItem) {
    if (cartItem is! Map) return true;

    final limits = cartItem['quantity_limits'];
    if (limits is Map && limits['editable'] is bool) {
      return limits['editable'] as bool;
    }

    return true;
  }

  double _parsePriceValue(dynamic value) {
    final normalized = value?.toString().trim().replaceAll(',', '.') ?? '';
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed.isNaN || parsed.isInfinite || parsed < 0) {
      return 0;
    }
    return parsed;
  }

  String _formatPrice(double value) {
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  String _formatCurrency(double value, SettingsProvider settings) {
    return '${_formatPrice(value)} ${settings.currencySymbol}';
  }

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
      if (widget.categoryIds != null) {
        provider.loadDeliveryProducts(categoryIds: widget.categoryIds);
      } else {
        provider.loadDeliveryProducts(categoryId: widget.categoryId);
      }
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
        body: Consumer2<ProductProvider, SettingsProvider>(
          builder: (context, productProvider, settingsProvider, child) {
            if (productProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFE71D24)),
              );
            }

            final isAddressHubPage = _isAddressHubMode;
            final allProducts = isAddressHubPage
                ? productProvider.deliveryProducts
                : productProvider.deliveryProducts.where((item) {
                    if (item is! Map) return false;
                    final product = Map<String, dynamic>.from(item);
                    return _productBelongsToCategory(
                      product,
                      widget.categoryId,
                    );
                  }).toList();

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
                                'مقارنة حسب التصنيف',
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
                                categoryId: _packagesOnlyCategoryId,
                                categoryIds: null,
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
                    final unitPrice = _parsePriceValue(product['price']);
                    final productId = int.tryParse(prod['id'].toString()) ?? 0;
                    final isVariableProduct =
                        product['type']?.toString() == 'variable' &&
                        product['variations'] is List &&
                        (product['variations'] as List).isNotEmpty;
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
                        unitPrice: unitPrice,
                        isVariableProduct: isVariableProduct,
                        features: features,
                        isDeliveryPack: isDeliveryPack,
                        settingsProvider: settingsProvider,
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
                  ? CachedImage(
                      imageUrl: remoteImageUrl,
                      height: 180,
                      fit: BoxFit.cover,
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
    required double unitPrice,
    required bool isVariableProduct,
    required List<String> features,
    required bool isDeliveryPack,
    required SettingsProvider settingsProvider,
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
                  CachedImage(
                    imageUrl: remoteImageUrl,
                    fit: BoxFit.cover,
                    errorWidget: _buildLocalImageFallback(
                      imageUrl: imageUrl,
                      isDeliveryPack: isDeliveryPack,
                    ),
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
                  _formatCurrency(unitPrice, settingsProvider),
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
                if (isVariableProduct)
                  FutureBuilder<List<_ProductVariationOption>>(
                    future: _variationOptionsFuture(productId),
                    builder: (context, snapshot) {
                      final options =
                          snapshot.data ?? const <_ProductVariationOption>[];
                      final hasOptions = options.isNotEmpty;
                      final selectedVariationId = hasOptions
                          ? (options.any(
                                  (option) =>
                                      option.id ==
                                      _selectedVariationByProduct[productId],
                                )
                                ? _selectedVariationByProduct[productId]
                                : options.first.id)
                          : null;

                      final selectedOption = hasOptions
                          ? options.firstWhere(
                              (option) => option.id == selectedVariationId,
                              orElse: () => options.first,
                            )
                          : null;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'اختر الفريشن',
                            style: TextStyle(
                              color: Color(0xFF334155),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !hasOptions)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: LinearProgressIndicator(
                                color: Color(0xFFE71D24),
                              ),
                            )
                          else if (!hasOptions)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1F2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFDA4AF),
                                ),
                              ),
                              child: const Text(
                                'لا توجد فريشنات متاحة لهذا المنتج حالياً',
                                style: TextStyle(
                                  color: Color(0xFF9F1239),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          else
                            OutlinedButton.icon(
                              onPressed: () => _openVariationPicker(
                                productId: productId,
                                options: options,
                                selectedVariationId: selectedVariationId,
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                side: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: const Color(0xFFF8FAFC),
                                foregroundColor: const Color(0xFF0F172A),
                              ),
                              icon: const Icon(Icons.swap_vert_rounded),
                              label: Text(
                                selectedOption?.label ?? 'اختيار الفريشن',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          const SizedBox(height: 12),
                          _buildPackageCartSection(
                            productId: productId,
                            baseProductPrice: unitPrice,
                            selectedTotal: selectedOption?.price ?? unitPrice,
                            isVariableProduct: true,
                            selectedVariationId: selectedVariationId,
                            selectedVariationLabel: selectedOption?.label,
                            variationRequiredButMissing: !hasOptions,
                          ),
                        ],
                      );
                    },
                  )
                else
                  _buildPackageCartSection(
                    productId: productId,
                    baseProductPrice: unitPrice,
                    selectedTotal: unitPrice,
                    isVariableProduct: false,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openVariationPicker({
    required int productId,
    required List<_ProductVariationOption> options,
    required int? selectedVariationId,
  }) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              const Text(
                'اختر الفريشن',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  itemBuilder: (ctx, index) {
                    final option = options[index];
                    final isSelected = option.id == selectedVariationId;
                    return ListTile(
                      title: Text(option.label),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: Color(0xFFE71D24),
                            )
                          : null,
                      onTap: () => Navigator.of(sheetContext).pop(option.id),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (!mounted || picked == null) return;
    setState(() {
      _selectedVariationByProduct[productId] = picked;
    });
  }

  Widget _buildPackageCartSection({
    required int productId,
    required double baseProductPrice,
    required double selectedTotal,
    required bool isVariableProduct,
    int? selectedVariationId,
    String? selectedVariationLabel,
    bool variationRequiredButMissing = false,
  }) {
    return Selector<CartProvider, _PackageCartUiState>(
      selector: (context, cartProvider) {
        final variationIds = _variationIdsByProduct[productId] ?? const <int>{};
        final cartItem = cartProvider.cartItems.cast<dynamic>().firstWhere((
          item,
        ) {
          if (item is! Map) return false;
          final itemId = _parseInt(item['id']);
          if (itemId == null) return false;

          if (!isVariableProduct) {
            return itemId == productId;
          }

          if (selectedVariationId != null && selectedVariationId > 0) {
            final itemVariationId = _parseInt(item['variation_id']);
            return itemId == selectedVariationId ||
                itemVariationId == selectedVariationId;
          }

          return itemId == productId || variationIds.contains(itemId);
        }, orElse: () => null);

        return _PackageCartUiState(
          cartQuantity: _extractCartQuantity(cartItem),
          cartItemKey: (cartItem is Map) ? cartItem['key']?.toString() : null,
          isQuantityEditable: _isCartItemQuantityEditable(cartItem),
          isAdding:
              cartProvider.isAddingProduct(productId) || cartProvider.isLoading,
        );
      },
      builder: (context, cartState, child) {
        final settingsProvider = context.read<SettingsProvider>();
        final cartTotal = selectedTotal * cartState.cartQuantity;
        final needsVariationSelection =
            isVariableProduct &&
            (selectedVariationId == null || selectedVariationId <= 0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'هذه الخدمة تُشترى مرة واحدة فقط.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (selectedVariationLabel != null &&
                selectedVariationLabel.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'الفريشن المختار: $selectedVariationLabel',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'السعر',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _formatCurrency(selectedTotal, settingsProvider),
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  if (isVariableProduct && selectedTotal != baseProductPrice)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'سعر الباقة الأساسي',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _formatCurrency(baseProductPrice, settingsProvider),
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (cartState.isInCart) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'إجمالي الموجود في السلة',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          _formatCurrency(cartTotal, settingsProvider),
                          style: const TextStyle(
                            color: Color(0xFF1E3A5F),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (cartState.isInCart) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE71D24).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE71D24).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.shopping_cart_checkout_rounded,
                      color: Color(0xFFE71D24),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'مضافة بالفعل في السلة',
                      style: TextStyle(
                        color: Color(0xFFE71D24),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          cartState.isAdding ||
                              cartState.isInCart ||
                              needsVariationSelection ||
                              variationRequiredButMissing
                          ? null
                          : () async {
                              print('🎯 Add to cart button pressed');
                              print('🎯 productId: $productId');
                              print('🎯 isVariableProduct: $isVariableProduct');
                              print('🎯 selectedVariationId: $selectedVariationId');
                              print('🎯 needsVariationSelection: $needsVariationSelection');
                              print('🎯 variationRequiredButMissing: $variationRequiredButMissing');
                              
                              final cartProvider = context.read<CartProvider>();
                              final success = await cartProvider.addToCart(
                                productId,
                                1,
                                variationId: isVariableProduct
                                    ? selectedVariationId
                                    : null,
                              );

                              print('🎯 Add to cart result: $success');
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
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              cartState.isInCart
                                  ? 'في السلة'
                                  : (variationRequiredButMissing ||
                                        needsVariationSelection)
                                  ? 'اختر الفريشن'
                                  : 'أضف للسلة',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed:
                          cartState.isAdding ||
                              needsVariationSelection ||
                              variationRequiredButMissing
                          ? null
                          : () async {
                              print('🛒 Buy Now button pressed');
                              final cartProvider = context.read<CartProvider>();
                              
                              // إذا المنتج مش في السلة، نضيفه ونستنى
                              if (!cartState.isInCart) {
                                print('🛒 Adding product to cart...');
                                final success = await cartProvider.addToCart(
                                  productId,
                                  1,
                                  variationId: isVariableProduct
                                      ? selectedVariationId
                                      : null,
                                );
                                
                                print('🛒 Add to cart result: $success');
                                
                                if (!success) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('فشل إضافة المنتج للسلة'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                  return;
                                }
                                
                                // نستنى شوية عشان الكارت يتحدث
                                await Future.delayed(const Duration(milliseconds: 300));
                              }
                              
                              // نروح على صفحة السلة
                              if (context.mounted) {
                                print('🛒 Navigating to cart page...');
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CartPage(),
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.shopping_cart_checkout, size: 20),
                      label: Text(
                        'اشتري دلوقتي',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
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
  const _PackageCartUiState({
    required this.cartQuantity,
    required this.cartItemKey,
    required this.isQuantityEditable,
    required this.isAdding,
  });

  final int cartQuantity;
  final String? cartItemKey;
  final bool isQuantityEditable;
  final bool isAdding;
  bool get isInCart => cartQuantity > 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _PackageCartUiState &&
        other.cartQuantity == cartQuantity &&
        other.cartItemKey == cartItemKey &&
        other.isQuantityEditable == isQuantityEditable &&
        other.isAdding == isAdding;
  }

  @override
  int get hashCode =>
      Object.hash(cartQuantity, cartItemKey, isQuantityEditable, isAdding);
}
