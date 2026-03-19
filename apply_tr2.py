import os
import json

# Load translation keys
with open('translation_cache.json', 'r', encoding='utf-8') as f:
    translations = json.load(f)

# we want to match both arabic (keys) and english (values)
# but we want to avoid short keys like 'الكل' or 'More' which might match things that are not UI text.
# Let's collect all strings > 2 characters.
valid_strings = set()
for k, v in translations.items():
    if len(k.strip()) > 1:
        valid_strings.add(k.strip())
    if len(v.strip()) > 1:
        valid_strings.add(v.strip())

# Sort by length descending to match longest phrases first
keys = sorted(list(valid_strings), key=len, reverse=True)

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    for key in keys:
        if key in content:
            # We want to replace exactly literal strings
            safe_key_single = f"'{key}'"
            safe_key_double = f'"{key}"'
            
            # replace only if it doesn't already end with .tr
            # a simple way is replace and then fix .tr.tr
            content = content.replace(safe_key_single, safe_key_single + '.tr')
            content = content.replace(safe_key_double, safe_key_double + '.tr')
    
    # fix accidental double applications if any run multiple times
    content = content.replace('.tr.tr', '.tr')

    if content != original_content:
        # insert import if missing
        if 'app_translations.dart' not in content:
            if 'views/screens/' in filepath.replace('\\', '/') or 'src/pages' in filepath.replace('\\', '/'):
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

print('Done applying translations.')
