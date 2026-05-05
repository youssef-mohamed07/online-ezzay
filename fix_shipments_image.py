import re

with open('lib/views/screens/shipments_page.dart', 'r') as f:
    content = f.read()

# Let's inspect the exact lines setting imageUrl in shipments_page.dart
with open('debug_shipments.txt', 'w') as f:
    f.write(re.search(r'String imageUrl =.*?final weight =', content, re.DOTALL)[0])
