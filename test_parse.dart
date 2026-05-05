import 'dart:core';

void main() {
  String html = """
<p>مخصصة للتجار وأصحاب الطلبات المتعددة.</p>
<ul>
<li>دعم الطرود حتى 24 طرداً</li>
<li>عملية شحن سلسة ومتعددة</li>
</ul>
""";

  String desc = html.replaceAll(RegExp(r'</p>|</li>|<br\\s*/?>', caseSensitive: false), '\n');
  desc = desc.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  var features = desc.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  print(features);
}
