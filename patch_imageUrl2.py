import re

with open('lib/views/screens/shipment_details_page.dart', 'r') as f:
    content = f.read()

new_logic = """    String imageUrl = _details?['image']?.toString() ?? _details?['image_url']?.toString() ?? '';
    if (imageUrl.isEmpty && _details?['line_items'] is List && (_details?['line_items'] as List).isNotEmpty) {
      final firstItem = (_details?['line_items'] as List)[0];
      if (firstItem is Map && firstItem['image'] is Map && firstItem['image']['src'] != null) {
        imageUrl = firstItem['image']['src'].toString();
      } else if (firstItem is Map && firstItem['image'] is String) {
        imageUrl = firstItem['image'].toString();
      } else if (firstItem is Map && firstItem['image_url'] != null) {
        imageUrl = firstItem['image_url'].toString();
      }
    }"""

content = content.replace(
    """    final imageUrl = _details?['image']?.toString() ?? _details?['image_url']?.toString();""",
    new_logic
)

with open('lib/views/screens/shipment_details_page.dart', 'w') as f:
    f.write(content)
