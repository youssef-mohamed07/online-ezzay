import 'package:flutter/material.dart';
import 'package:online_ezzy/core/app_title_assets.dart';
import 'package:online_ezzy/core/image_url_utils.dart';
import 'package:online_ezzy/providers/product_provider.dart';
import 'package:online_ezzy/widgets/cached_image.dart';
import 'package:provider/provider.dart';
import 'address_details_page.dart';
import 'us_address_page.dart';
import 'cn_address_page.dart';

class AddressPage extends StatelessWidget {
  const AddressPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'العناوين',
            style: TextStyle(
              color: Color(0xFF1E3A5F),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: Consumer<ProductProvider>(
          builder: (context, productProvider, _) {
            final categories = productProvider.categories;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildAddressCard(
                    context,
                    title: 'عنوان الداخل',
                    imageAsset: AppTitleAssets.insideAddress,
                    imageUrl: _categoryImageById(categories, 69),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AddressDetailsPage(title: 'عنوان الداخل'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildAddressCard(
                    context,
                    title: 'عنوان صيني',
                    imageAsset: AppTitleAssets.chinaAddress,
                    imageUrl: _categoryImageById(categories, 77),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CnAddressPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildAddressCard(
                    context,
                    title: 'عنوان امريكي',
                    imageAsset: AppTitleAssets.usAddress,
                    imageUrl: _categoryImageById(categories, 70),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UsAddressPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Object? _categoryImageById(List<dynamic> categories, int categoryId) {
    for (final item in categories) {
      if (item is! Map) continue;
      final category = Map<String, dynamic>.from(item);
      final id = category['id'];
      if (id is num && id.toInt() == categoryId) {
        return category['image'] ?? category['image_url'];
      }
    }
    return null;
  }

  Widget _buildAddressCard(
    BuildContext context, {
    required String title,
    required String imageAsset,
    Object? imageUrl,
    required VoidCallback onPressed,
  }) {
    final normalizedImage = normalizeImageUrl(imageUrl);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
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
            child: normalizedImage.isNotEmpty
                ? CachedImage(
                    imageUrl: imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: Image.asset(
                      imageAsset,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                : Image.asset(
                    imageAsset,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 45,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'تعرف على الباقات',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
