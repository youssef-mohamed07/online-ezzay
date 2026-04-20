import re

with open('lib/providers/product_provider.dart', 'r') as f:
    content = f.read()

# Add delivery products right after products
pattern = r"List<dynamic> _products = \[\];\s*List<dynamic> get products => _products;"
replacement = "List<dynamic> _products = [];\n  List<dynamic> get products => _products;\n\n  List<dynamic> _deliveryProducts = [];\n  List<dynamic> get deliveryProducts => _deliveryProducts;"
content = re.sub(pattern, replacement, content)

# Add loadDeliveryProducts after loadProducts
pattern_load = r"(Future<void> loadProducts\(\) async \{.*?notifyListeners\(\);\n  \})"
replacement_load = r"""\1

  Future<void> loadDeliveryProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _deliveryProducts = await ApiService.getProducts(categoryId: 68);
    } catch (e) {
      print('Load delivery products error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }"""
content = re.sub(pattern_load, replacement_load, content, flags=re.DOTALL)

with open('lib/providers/product_provider.dart', 'w') as f:
    f.write(content)

