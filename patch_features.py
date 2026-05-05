import re

with open('lib/views/screens/packages_page.dart', 'r') as f:
    content = f.read()

old_logic = """                    // Extract features from short_description or description
                    List<String> features = [];
                    String desc = product['short_description']?.toString() ?? '';
                    if (desc.isEmpty) {
                      desc = product['description']?.toString() ?? '';
                    }

                    if (desc.isNotEmpty) {
                      // Add newlines before removing tags to preserve text separation
                      String processedDesc = desc.replaceAll(RegExp(r'</p>|</li>|<br\s*/?>', caseSensitive: false), '\\n');
                      final stripped = processedDesc
                          .replaceAll(RegExp(r'<[^>]*>'), '')
                          .trim();
                      if (stripped.isNotEmpty) {
                        features = stripped
                            .split('\\n')
                            .map((s) => s.trim())
                            .where((s) => s.isNotEmpty)
                            .toList();
                      }
                    }"""

new_logic = """                    // Extract features from pack_description (direct or meta_data) or fallback to descriptions
                    List<String> features = [];
                    String packDescRaw = '';
                    
                    if (product['pack_description'] is String) {
                      packDescRaw = product['pack_description'];
                    } else if (product['pack_description'] is Map) {
                      packDescRaw = product['pack_description']['value']?.toString() ?? '';
                    } else if (product['meta_data'] is List) {
                      for (var meta in product['meta_data']) {
                        if (meta is Map && meta['key'] == 'pack_description') {
                          packDescRaw = meta['value']?.toString() ?? '';
                          break;
                        }
                      }
                    }

                    if (packDescRaw.trim().isNotEmpty) {
                       features = packDescRaw
                          .replaceAll('\\r', '')
                          .split('\\n')
                          .map((s) => s.trim())
                          .where((s) => s.isNotEmpty)
                          .toList();
                    } else {
                      String desc = product['short_description']?.toString() ?? '';
                      if (desc.isEmpty) {
                        desc = product['description']?.toString() ?? '';
                      }

                      if (desc.isNotEmpty) {
                        // Add newlines before removing tags to preserve text separation
                        String processedDesc = desc.replaceAll(RegExp(r'</p>|</li>|<br\s*/?>', caseSensitive: false), '\\n');
                        final stripped = processedDesc
                            .replaceAll(RegExp(r'<[^>]*>'), '')
                            .trim();
                        if (stripped.isNotEmpty) {
                          features = stripped
                              .split('\\n')
                              .map((s) => s.trim())
                              .where((s) => s.isNotEmpty)
                              .toList();
                        }
                      }
                    }"""

content = content.replace(old_logic, new_logic)

with open('lib/views/screens/packages_page.dart', 'w') as f:
    f.write(content)

