import os
import re
import json

cache_file = 'translation_cache.json'
with open(cache_file, 'r', encoding='utf-8') as f:
    cache = json.load(f)

# Sort cache keys by length descending so that 'طرد ${index + 1}' gets replaced safely without messing up shorter subsets.
sorted_keys = sorted(cache.keys(), key=len, reverse=True)

# Generate app_translations.dart
with open('lib/core/app_translations.dart', 'w', encoding='utf-8') as f:
    f.write("class AppTranslations {\n")
    f.write("  static String currentLang = 'ar';\n")
    f.write("  static const Map<String, String> arToEn = {\n")
    for k in sorted_keys:
        v = cache[k]
        ks = k.replace("'", "\\'").replace('\n', '\\n').replace('$', '\\$')
        vs = v.replace("'", "\\'").replace('\n', '\\n').replace('$', '\\$')
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

# Now apply translations to views folder
for root, _, files in os.walk('lib/views'):
    for file in files:
        if file.endswith('.dart'):
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original = content
            
            for k in sorted_keys:
                if k not in content: continue
                # replace Exact string if it lacks .tr
                # we must handle single and double quotes
                s1 = f"'{k}'"
                s2 = f'"{k}"'
                # replace to temporarily hide the existing .tr
                content = content.replace(s1 + '.tr', s1)
                content = content.replace(s2 + '.tr', s2)
                
                content = content.replace(s1, s1 + '.tr')
                content = content.replace(s2, s2 + '.tr')
            
            # fix accidental multiple tr
            content = content.replace('.tr.tr', '.tr')

            if content != original:
                if 'app_translations.dart' not in content:
                    content = "import 'package:online_ezzy/core/app_translations.dart';\n" + content
                
                # fix const
                content = re.sub(r'const\s+(Text|SnackBar|_SectionTitle|Center|DropdownMenuItem|Column|Row|Padding|SizedBox|Icon|Tab|TabItem)\b', r'\1', content)
                
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(content)
                  
# Fix Directionality globally
for root, _, files in os.walk('lib/views'):
    for file in files:
        if file.endswith('.dart'):
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()

            original = content
            content = re.sub(r'textDirection:\s*TextDirection\.[lr]tl', r'textDirection: Provider.of<LanguageProvider>(context).textDirection', content)
            
            if content != original:
                if 'Provider.of<LanguageProvider>' in content and 'language_provider.dart' not in content:
                    content = "import 'package:provider/provider.dart';\nimport 'package:online_ezzy/core/language_provider.dart';\n" + content
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(content)

print("Done")