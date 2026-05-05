import re

with open('lib/views/screens/home_page.dart', 'r') as f:
    content = f.read()

old_logic = """              final prod = items[index];
              final productId = int.tryParse(prod['id'].toString()) ?? 0;
              final String name = prod['name']?.toString() ?? 'عنوان';
              final String price = prod['price']?.toString() ?? '0';

              return Container("""

new_logic = """              final prod = items[index];
              final productId = int.tryParse(prod['id'].toString()) ?? 0;
              final String name = prod['name']?.toString() ?? 'عنوان';
              final String price = prod['price']?.toString() ?? '0';

              // Extract description from pack_description or fallback
              String descriptionText = 'تعرف على تفاصيل العنوان';
              String packDescRaw = '';
              
              if (prod['pack_description'] is String) {
                packDescRaw = prod['pack_description'];
              } else if (prod['pack_description'] is Map) {
                packDescRaw = prod['pack_description']['value']?.toString() ?? '';
              } else if (prod['meta_data'] is List) {
                for (var meta in prod['meta_data']) {
                  if (meta is Map && meta['key'] == 'pack_description') {
                    packDescRaw = meta['value']?.toString() ?? '';
                    break;
                  }
                }
              }

              if (packDescRaw.trim().isNotEmpty) {
                 descriptionText = packDescRaw.replaceAll('\\r', '');
              } else {
                String desc = prod['short_description']?.toString() ?? '';
                if (desc.isEmpty) {
                  desc = prod['description']?.toString() ?? '';
                }
                if (desc.isNotEmpty) {
                  descriptionText = desc.replaceAll(RegExp(r'<[^>]*>'), '').trim();
                }
              }
              // Limits lines for UI to just 1 or 2 lines for the card
              final lines = descriptionText.split('\\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
              final displayDesc = lines.isNotEmpty ? lines.first : 'تعرف على تفاصيل العنوان';

              return Container("""

content = content.replace(old_logic, new_logic)

old_text = """                    Text(
                      '$price دولار\\nتعرف على تفاصيل العنوان',
                      textAlign: TextAlign.start,"""

new_text = """                    Text(
                      '$price دولار\\n$displayDesc',
                      textAlign: TextAlign.start,"""

content = content.replace(old_text, new_text)

with open('lib/views/screens/home_page.dart', 'w') as f:
    f.write(content)
