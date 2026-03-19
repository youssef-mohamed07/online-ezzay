import os
import re
import json
from deep_translator import GoogleTranslator

translator = GoogleTranslator(source='ar', target='en')

# Load existing cache
cache_file = 'translation_cache.json'
if os.path.exists(cache_file):
    with open(cache_file, 'r', encoding='utf-8') as f:
        cache = json.load(f)
else:
    cache = {}

def get_translation(text):
    if text in cache:
        return cache[text]
    try:
        t = translator.translate(text)
        cache[text] = t
        return t
    except Exception as e:
        print(f"Failed to translate: {text}")
        return text

# First, extract all unique arabic strings literally
all_arabic_strings = set()

dart_files = []
for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            dart_files.append(os.path.join(root, file))

for path in dart_files:
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # regex to find strings: we look for single or double quoted strings
    # We ignore multiline strings for now (''' or """) or handle them if needed.
    # We must match non-escaped quotes inside.
    # Simple regex for single line strings:
    matches = re.finditer(r"(['\"])(.*?)\1", content)
    for m in matches:
        s = m.group(2)
        if re.search(r'[\u0600-\u06FF]', s):
            all_arabic_strings.add(s)

print(f"Found {len(all_arabic_strings)} unique Arabic strings.")

# Translate them
translations = {}
for s in all_arabic_strings:
    translations[s] = get_translation(s)

with open(cache_file, 'w', encoding='utf-8') as f:
    json.dump(cache, f, ensure_ascii=False, indent=2)

# Generate app_translations.dart
with open('lib/core/app_translations.dart', 'w', encoding='utf-8') as f:
    f.write("class AppTranslations {\n")
    f.write("  static String currentLang = 'ar';\n")
    f.write("  static const Map<String, String> arToEn = {\n")
    for k, v in translations.items():
        ks = k.replace("'", "\\'").replace('\n', '\\n').replace('$', '\\$')
        if v:
            vs = v.replace("'", "\\'").replace('\n', '\\n').replace('$', '\\$')
        else:
            vs = ks
        f.write(f"    '{ks}': '{vs}',\n")
    f.write("  };\n")
    f.write("  static String translate(String key) {\n")
    f.write("    if (currentLang == 'en') {\n")
    f.write("      return arToEn[key] ?? key;\n")
    f.write("    }\n")
    f.write("    return key;\n")
    f.write("  }\n")
    f.write("}\n\n")
    f.write("extension TranslationExtension on String {\n")
    f.write("  String get tr => AppTranslations.translate(this);\n")
    f.write("}\n")

print("Generated app_translations.dart")

# Now modify files to add .tr to Arabic strings and remove `const` where necessary
for path in dart_files:
    if path.endswith('app_translations.dart'): continue
    
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    
    # Replace all arabic strings with .tr
    # Sort by length descending to replace longest first
    sorted_strings = sorted(list(all_arabic_strings), key=len, reverse=True)
    
    for s in sorted_strings:
        # Avoid replacing inside existing .tr or messing up
        # We find `'string'` or `"string"`
        s_esc1 = f"'{s}'"
        s_esc2 = f'"{s}"'
        
        content = content.replace(s_esc1 + '.tr', s_esc1)
        content = content.replace(s_esc2 + '.tr', s_esc2)
        
        content = content.replace(s_esc1, s_esc1 + '.tr')
        content = content.replace(s_esc2, s_esc2 + '.tr')
    
    # Fix import
    if content != original:
        if 'app_translations.dart' not in content:
            content = "import 'package:online_ezzy/core/app_translations.dart';\n" + content

    # Fix const issues
    # Any line with .tr cannot have a `const ` keyword that applies to it.
    # The safest way is to just blindly remove `const ` from lines that contain `.tr`, 
    # but multiline consts like `const Center(\n child: Text('...'.tr))` are tricky.
    # regex: remove const before Widget( if the body has .tr
    # A simplified approach:
    content = re.sub(r'const\s+(Text|SnackBar|_SectionTitle|Center|DropdownMenuItem|Column|Row|Padding|SizedBox|Icon|Tab|TabItem)\b', r'\1', content)
    
    # Fix Directionality
    # We replace `TextDirection.rtl` or `TextDirection.ltr` with `Provider.of<LanguageProvider>(context).textDirection` inside `Directionality(textDirection:`
    content = re.sub(r'textDirection:\s*TextDirection\.[lt]tr', r'textDirection: Provider.of<LanguageProvider>(context).textDirection', content)
    
    if 'Provider.of<LanguageProvider>' in content and 'language_provider.dart' not in content:
        content = "import 'package:provider/provider.dart';\nimport 'package:online_ezzy/core/language_provider.dart';\n" + content
    
    # remove any duplicate .tr.tr just in case
    content = content.replace('.tr.tr', '.tr')

    if content != original:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {path}")

print("Done processing UI files.")
