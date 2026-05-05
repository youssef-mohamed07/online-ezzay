String normalizeImageUrl(Object? value) {
  if (value == null) return '';

  if (value is Map) {
    return firstValidImageUrl([
      value['src'],
      value['url'],
      value['image_url'],
      value['source'],
      value['thumbnail'],
      value['product_image'],
    ]);
  }

  if (value is List) {
    return firstValidImageUrl(value);
  }

  var url = value.toString().trim();
  if (url.isEmpty || url == 'null' || url == '{}' || url == '[]') return '';

  url = url
      .replaceAll(r'\/', '/')
      .replaceAll('&amp;', '&')
      .replaceAll(' ', '%20');

  final embeddedUrl = RegExp(
    r'(https?:\/\/[^\s,}]+|\/\/[^\s,}]+|\/wp-content\/[^\s,}]+|wp-content\/[^\s,}]+|\/wp-includes\/[^\s,}]+|wp-includes\/[^\s,}]+|\/uploads\/[^\s,}]+|uploads\/[^\s,}]+)',
  ).firstMatch(url)?.group(0);
  if (embeddedUrl != null) {
    url = embeddedUrl.replaceAll('"', '').replaceAll("'", '');
  }

  if (url.startsWith('//')) return 'https:$url';
  if (url.startsWith('http://')) return url.replaceFirst('http://', 'https://');
  if (url.startsWith('https://')) return url;
  if (url.startsWith('/')) return 'https://demo.onlineezzy.com$url';
  if (url.startsWith('wp-content/') || url.startsWith('wp-includes/')) {
    return 'https://demo.onlineezzy.com/$url';
  }

  return '';
}

String firstValidImageUrl(Iterable<Object?> values) {
  for (final value in values) {
    final url = normalizeImageUrl(value);
    if (url.isNotEmpty) return url;
  }
  return '';
}

String shipmentImageUrl(Map<dynamic, dynamic>? shipment) {
  if (shipment == null) return '';

  final candidates = <Object?>[
    shipment['image_url'],
    shipment['image'],
    shipment['product_image'],
    shipment['thumbnail'],
    shipment['featured_image'],
  ];

  final lineItems = shipment['line_items'];
  if (lineItems is List && lineItems.isNotEmpty) {
    final firstItem = lineItems.first;
    if (firstItem is Map) {
      candidates.addAll([
        firstItem['image_url'],
        firstItem['image'],
        firstItem['product_image'],
        firstItem['thumbnail'],
        firstItem['featured_image'],
      ]);

      // Check for image in meta_data
      final metaData = firstItem['meta_data'];
      if (metaData is List) {
        for (final meta in metaData) {
          if (meta is Map && (meta['key'] == 'image' || meta['key'] == '_thumbnail_id')) {
            candidates.add(meta['value']);
          }
        }
      }

      // Check for image object with src
      final image = firstItem['image'];
      if (image is Map) {
        candidates.addAll([
          image['src'],
          image['url'],
        ]);
      }
    }
  }

  return firstValidImageUrl(candidates);
}
