import re

with open('lib/views/screens/packages_page.dart', 'r') as f:
    content = f.read()

# Replace loadCategories() and loadProducts() with loadDeliveryProducts()
pattern_init = r"provider\.loadCategories\(\);\s*provider\.loadProducts\(\);"
replacement_init = "provider.loadDeliveryProducts();"
content = re.sub(pattern_init, replacement_init, content)

# Replace allProducts = productProvider.products;
pattern_products = r"final allProducts = productProvider\.products;"
replacement_products = "final allProducts = productProvider.deliveryProducts;"
content = re.sub(pattern_products, replacement_products, content)

with open('lib/views/screens/packages_page.dart', 'w') as f:
    f.write(content)

