import os
import json
import re

# Load translation keys
with open('translation_cache.json', 'r', encoding='utf-8') as f:
    translations = json.load(f)

# Sort by length descending to avoid partial matches
keys = sorted(translations.keys(), key=len, reverse=True)

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    # For every key, we try to match "key" or 'key' and replace with "key".tr
    for key in keys:
        if key in content:
            # We must be careful to avoid double .tr or messing up inside .tr
            # Simple approach: find `'key'` and replace with `'key'.tr`
            # Escaping the key for literal match
            safe_key_single = f"'{key}'"
            safe_key_double = f'"{key}"'
            
            # Use negative lookahead to prevent '.tr' again
            if original_content.find(safe_key_single) != -1:
                content = content.replace(safe_key_single, safe_key_single + '.tr')
            if original_content.find(safe_key_double) != -1:
                content = content.replace(safe_key_double, safe_key_double + '.tr')
    
    # Fix multiple .tr.tr just in case it happened
    content = content.replace('.tr.tr', '.tr')

    if content != original_content:
        # Check if we need to import app_translations.dart
        if 'app_translations.dart' not in content:
            # Calculate path to core based on current file depth
            depth = filepath.count(os.sep) - 1 # 'lib/src/pages' -> 3 -> depth = 2 relative to lib
            if depth < 0: depth = 0
            
            if 'views/screens/' in filepath.replace('\\', '/'):
                import_path = "import '../../core/app_translations.dart';"
            elif 'src/pages/' in filepath.replace('\\', '/'):
                import_path = "import '../../core/app_translations.dart';"
            elif 'core/' in filepath.replace('\\', '/'):
                import_path = "import 'app_translations.dart';"
            else:
                import_path = "import 'package:online_ezzy/core/app_translations.dart';"
                
            content = import_path + '\n' + content
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))

print('Done')