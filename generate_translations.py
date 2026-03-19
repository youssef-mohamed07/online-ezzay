import json
import os
import re

print('generating app_translations.dart...')
with open('translation_cache.json', encoding='utf-8') as f:
    d = json.load(f)

with open('lib/core/app_translations.dart', 'w', encoding='utf-8') as f:
    f.write("class AppTranslations {\n")
    f.write("  static String currentLang = 'ar';\n")
    f.write("  static const Map<String, String> en = {\n")
    for k, v in d.items():
        ks = k.replace("'", "\\'").replace('\n', '\\n')
        vs = v.replace("'", "\\'").replace('\n', '\\n')
        f.write(f"    '{ks}': '{vs}',\n")
    f.write("  };\n")
    f.write("  static String translate(String key) {\n")
    f.write("    if (currentLang == 'ar') return key;\n")
    f.write("    return en[key] ?? key;\n")
    f.write("  }\n")
    f.write("}\n\n")
    f.write("extension TranslationExtension on String {\n")
    f.write("  String get tr => AppTranslations.translate(this);\n")
    f.write("}\n")

print('app_translations.dart generated.')

# Now modify lib/core/language_provider.dart
lp_file = 'lib/core/language_provider.dart'
with open(lp_file, 'r', encoding='utf-8') as f:
    lp_content = f.read()

if 'AppTranslations.currentLang' not in lp_content:
    if "import 'app_translations.dart';" not in lp_content:
        lp_content = "import 'app_translations.dart';\n" + lp_content
    
    lp_content = lp_content.replace(
        '_locale = newLocale;',
        '_locale = newLocale;\n      AppTranslations.currentLang = newLocale.languageCode;'
    )
    with open(lp_file, 'w', encoding='utf-8') as f:
        f.write(lp_content)
    print('Updated language_provider.dart')
