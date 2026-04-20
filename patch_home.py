import re

with open('lib/views/screens/home_page.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Make home page show ALL categories and products
# Section 1: Categories
old_cats = """        List<dynamic> cats = productProvider.categories.where((c) {
          final n = c['name'].toString();
          return n.contains('تجميع') || n.contains('تغليف') || n.contains('تخزين');
        }).toList();

        // Fallback for demo
        if (cats.isEmpty) {
          cats = productProvider.categories.take(4).toList();
        }"""

new_cats = """        List<dynamic> cats = productProvider.categories;
        if (cats.length > 4) cats = cats.take(4).toList();"""

text = text.replace(old_cats, new_cats)

# Section 2: Products
old_prods = """        List<dynamic> items = productProvider.products.where((p) {
          final cats = p['categories'] as List?;
          if (cats != null) {
            return cats.any((c) => c['name'].toString().contains('عناوين') || c['name'].toString().contains('عنوان'));
          }
          return false;
        }).toList();

        // Fallback for demo if no categories match perfectly
        if (items.isEmpty) {
          final nameMatches = productProvider.products.where((p) => p['name'].toString().contains('عنوان') || p['name'].toString().contains('عناوين')).toList();
          items = nameMatches.isNotEmpty ? nameMatches : productProvider.products;
        }"""
        
new_prods = "        List<dynamic> items = productProvider.products;"
text = text.replace(old_prods, new_prods)

text = text.replace("لا يوجد عناوين حاليا", "لا يوجد منتجات حاليا")

with open('lib/views/screens/home_page.dart', 'w', encoding='utf-8') as f:
    f.write(text)
