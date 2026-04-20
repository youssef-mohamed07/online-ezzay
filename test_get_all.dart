import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  final auth = 'Basic Y2tfZWUxMDQyMDUwNGQyZWJjOTAwMGFhODgxNjhjMWIwZTcyNjc3YWVhZjpjc18zMmY4NTZhM2YyODY4MmZkZWNmM2YyNjY0NmM4ZWJhOGM4Njc1MmRm';
  var res = await http.get(Uri.parse('https://the-tech.net/online-ezzy/wp-json/wc/v3/products'), headers: {'Authorization': auth});
  
  if (res.statusCode == 200) {
    try {
        var products = jsonDecode(res.body);
        print("Products count: \${products.length}");
        for (var p in products) {
            print("Product: \${p['id']} - \${p['name']} - Categories: \${p['categories']?.map((c) => c['name']).toList()}");
        }
    } catch (e) {
        print("Products count: error \$e");
    }
  } else {
    print("Failed to get products: \${res.statusCode}");
  }

  var cRes = await http.get(Uri.parse('https://the-tech.net/online-ezzy/wp-json/wc/v3/products/categories'), headers: {'Authorization': auth});
  if (cRes.statusCode == 200) {
    try {
      var categories = jsonDecode(cRes.body);
      print("Categories count: \${categories.length}");
      for (var c in categories) {
        print("Category: \${c['id']} - \${c['name']}");
      }
    } catch(e) {}
  }

  // test wp-json/cocart/v2/cart
  var cartRes = await http.get(Uri.parse('https://the-tech.net/online-ezzy/wp-json/cocart/v2/cart'), headers: {'Authorization': auth});
  print("Cart Code: \${cartRes.statusCode}");
  print("Cart Body length: \${cartRes.body.length}");
}
