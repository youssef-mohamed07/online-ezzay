import re

with open('lib/views/screens/shipments_page.dart', 'r') as f:
    content = f.read()

# Make imageUrl more resilient by checking inside line_items -> firstItem -> image (it could be an object with src, or a string)
# OR it could be firstItem -> image. If it's a map, fallback to image['url'], image['src']
old_logic = """String imageUrl = (shipment['image'] ?? shipment['image_url'] ?? '').toString();
                                        if (imageUrl.isEmpty && shipment['line_items'] is List && (shipment['line_items'] as List).isNotEmpty) {
                                          final firstItem = (shipment['line_items'] as List)[0];
                                          if (firstItem is Map && firstItem['image'] is Map && firstItem['image']['src'] != null) {
                                            imageUrl = firstItem['image']['src'].toString();
                                          } else if (firstItem is Map && firstItem['image'] is String) {
                                            imageUrl = firstItem['image'].toString();
                                          } else if (firstItem is Map && firstItem['image_url'] != null) {
                                            imageUrl = firstItem['image_url'].toString();
                                          }
                                        }"""

new_logic = """String imageUrl = (shipment['image'] ?? shipment['image_url'] ?? '').toString();
                                        if (imageUrl.isEmpty && shipment['line_items'] is List && (shipment['line_items'] as List).isNotEmpty) {
                                          final firstItem = (shipment['line_items'] as List)[0];
                                          if (firstItem is Map) {
                                            if (firstItem['image'] is Map) {
                                              imageUrl = (firstItem['image']['src'] ?? firstItem['image']['url'] ?? firstItem['image']['image_url'] ?? '').toString();
                                            } else if (firstItem['image'] is String && firstItem['image'].toString().isNotEmpty) {
                                              imageUrl = firstItem['image'].toString();
                                            } else if (firstItem['image_url'] != null) {
                                              imageUrl = firstItem['image_url'].toString();
                                            } else if (firstItem['product_image'] != null) {
                                              imageUrl = firstItem['product_image'].toString();
                                            } else if (firstItem['meta_data'] is List) {
                                              // Sometimes image is hidden in meta_data
                                              for(var meta in firstItem['meta_data']) {
                                                if (meta is Map && meta['key'] == 'image') {
                                                  imageUrl = meta['value'].toString();
                                                  break;
                                                }
                                              }
                                            }
                                          }
                                        }"""

content = content.replace(old_logic, new_logic)

with open('lib/views/screens/shipments_page.dart', 'w') as f:
    f.write(content)

