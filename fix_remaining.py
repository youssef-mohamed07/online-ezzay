import re

def fix_file(path, old_str, new_str):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace(old_str, new_str)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

# 1. auth_layout.dart
# The default value can't be '.tr'. We change:
# `this.headerTitle = 'Account portal'.tr,` to `this.headerTitle = 'Account portal',`
fix_file('lib/views/screens/auth/auth_layout.dart', 
         "this.headerTitle = 'Account portal'.tr,", 
         "this.headerTitle = 'Account portal',")

# Wait, we need to make sure we call .tr when it's used inside the builder
with open('lib/views/screens/auth/auth_layout.dart', 'r', encoding='utf-8') as f:
    text = f.read()
    text = text.replace('Text(headerTitle,', 'Text(headerTitle.tr,')
with open('lib/views/screens/auth/auth_layout.dart', 'w', encoding='utf-8') as f:
    f.write(text)

# 2. forgot_password_page.dart
fix_file('lib/views/screens/auth/forgot_password_page.dart',
         "const AuthTextField(",
         "AuthTextField(")

# 3. otp_verification_page.dart
fix_file('lib/views/screens/auth/otp_verification_page.dart',
         "const AuthTextField(",
         "AuthTextField(")

# 4. register_page.dart
fix_file('lib/views/screens/auth/register_page.dart',
         "const AuthTextField(",
         "AuthTextField(")

# 5. reset_password_page.dart
fix_file('lib/views/screens/auth/reset_password_page.dart',
         "const AuthTextField(",
         "AuthTextField(")
fix_file('lib/views/screens/auth/reset_password_page.dart',
         "const SnackBar(content: Text('The password has been updated successfully'.tr)),",
         "SnackBar(content: Text('The password has been updated successfully'.tr)),")

# 6. shipments_page.dart
fix_file('lib/views/screens/shipments_page.dart',
         "const Center(\n                    child: Text('There are no shipments currently'.tr, style: TextStyle(color: Colors.grey)),\n                  ),",
         "Center(\n                    child: Text('There are no shipments currently'.tr, style: TextStyle(color: Colors.grey)),\n                  ),")
fix_file('lib/views/screens/shipments_page.dart',
         "const Center(child: Text('There are no shipments currently'.tr, style: TextStyle(color: Colors.grey))),",
         "Center(child: Text('There are no shipments currently'.tr, style: TextStyle(color: Colors.grey))),")

# More brute-force for shipments_page.dart
with open('lib/views/screens/shipments_page.dart', 'r', encoding='utf-8') as f:
    c = f.read()
    c = re.sub(r'const\s+Center\(\s*child:\s*Text\(\'There are no shipments currently\'\.tr',
               r"Center(\nchild: Text('There are no shipments currently'.tr", c)
with open('lib/views/screens/shipments_page.dart', 'w', encoding='utf-8') as f:
    f.write(c)

