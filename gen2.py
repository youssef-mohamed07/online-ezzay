import json

with open('translation_cache.json', 'r', encoding='utf-8') as f:
    d = json.load(f)

# Create a map of english to arabic too
en_to_ar = {v: k for k, v in d.items()}

with open('lib/core/app_translations.dart', 'w', encoding='utf-8') as f:
    f.write("class AppTranslations {\n")
    f.write("  static String currentLang = 'ar';\n")
    
    f.write("  static const Map<String, String> arToEn = {\n")
    for k, v in d.items():
        ks = k.replace("'", "\\'").replace('\n', '\\n')
        vs = v.replace("'", "\\'").replace('\n', '\\n')
        f.write(f"    '{ks}': '{vs}',\n")
    f.write("  };\n")
    
    f.write("  static const Map<String, String> enToAr = {\n")
    for k, v in en_to_ar.items():
        ks = k.replace("'", "\\'").replace('\n', '\\n')
        vs = v.replace("'", "\\'").replace('\n', '\\n')
        f.write(f"    '{ks}': '{vs}',\n")
    f.write("  };\n")

    f.write("  static String translate(String key) {\n")
    f.write("    if (currentLang == 'en') {\n")
    f.write("      return arToEn[key] ?? key;\n")
    f.write("    } else {\n")
    f.write("      return enToAr[key] ?? key;\n")
    f.write("    }\n")
    f.write("  }\n")
    f.write("}\n\n")
    
    f.write("extension TranslationExtension on String {\n")
    f.write("  String get tr => AppTranslations.translate(this);\n")
    f.write("}\n")

print('app_translations.dart created with two-way mapping')
