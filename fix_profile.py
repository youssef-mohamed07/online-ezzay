import re

with open('lib/views/screens/profile_page.dart', 'r') as f:
    content = f.read()

# Instead of patching inside _buildShipmentItem since we saw it didn't have the full Map, 
# let's see how _buildShipmentItem is called inside _buildShipmentsTab

with open('profile_debug.txt', 'w') as f:
    f.write(re.search(r'Widget _buildShipmentsTab\(\) \{.*?(Widget _build|return)', content, re.DOTALL)[0])
