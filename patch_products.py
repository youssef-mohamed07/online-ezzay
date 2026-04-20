import re

with open('lib/core/api_service.dart', 'r') as f:
    content = f.read()

pattern = r"static Future<List<dynamic>> getProducts\(\) async \{.*?final url = Uri\.parse\('\$baseUrl/wc/v3/products'\);"

replacement = """static Future<List<dynamic>> getProducts({int? categoryId}) async {
    try {
      Uri url = Uri.parse('$baseUrl/wc/v3/products');
      if (categoryId != null) {
        url = Uri.parse('$baseUrl/wc/v3/products?category=$categoryId');
      }"""

content = re.sub(pattern, replacement, content, flags=re.DOTALL)

with open('lib/core/api_service.dart', 'w') as f:
    f.write(content)

