import re

with open('lib/views/screens/shipments_page.dart', 'r') as f:
    content = f.read()

# Define the new image url logic
new_logic = """                                        String imageUrl = (shipment['image'] ?? shipment['image_url'] ?? '').toString();
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

content = content.replace(
    """                                        final imageUrl =
                                            (shipment['image'] ?? shipment['image_url'] ?? '').toString();""",
    new_logic
)

with open('lib/views/screens/shipments_page.dart', 'w') as f:
    f.write(content)
