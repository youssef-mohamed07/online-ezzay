import re

with open('lib/views/screens/profile_page.dart', 'r') as f:
    content = f.read()

match = re.search(r'Widget _buildShipmentsTab\(\) \{.*?\n  \}', content, re.DOTALL)
if match:
    with open('profile_debug.txt', 'w') as f:
        f.write(match[0])
    print("Logged to profile_debug.txt")
else:
    print("Match failed")
