import os
import re
import json

# 1. Regenerate app_translations.dart correctly escaping $
with open('translation_cache.json', 'r', encoding='utf-8') as f:
    d = json.load(f)

en_to_ar = {v: k for k, v in d.items()}

with open('lib/core/app_translations.dart', 'w', encoding='utf-8') as f:
    f.write("class AppTranslations {\n")
    f.write("  static String currentLang = 'ar';\n")
    
    f.write("  static const Map<String, String> arToEn = {\n")
    for k, v in d.items():
        ks = k.replace("'", "\\'").replace('\n', '\\n').replace('$', '\\$')
        vs = v.replace("'", "\\'").replace('\n', '\\n').replace('$', '\\$')
        f.write(f"    '{ks}': '{vs}',\n")
    f.write("  };\n")
    
    f.write("  static const Map<String, String> enToAr = {\n")
    for k, v in en_to_ar.items():
        ks = k.replace("'", "\\'").replace('\n', '\\n').replace('$', '\\$')
        vs = v.replace("'", "\\'").replace('\n', '\\n').replace('$', '\\$')
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

# 2. Fix imports and const expressions in all files
import_pattern = re.compile(r"import\s+['\"](?:\.\./)*core/app_translations\.dart['\"];")

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()

            original_content = content
            
            # Fix imports
            content = import_pattern.sub("import 'package:online_ezzy/core/app_translations.dart';", content)
            
            # Fix `const Text( ... .tr ... )`
            # This regex will look for `const Text` and replace it with `Text`
            # Since regex is hard to perfectly match all nested consts, let's do a few passes:
            content = re.sub(r'const\s+Text\s*\(', r'Text(', content)
            content = re.sub(r'const\s+_SectionTitle\s*\(', r'_SectionTitle(', content)
            content = re.sub(r'const\s+Center\s*\(\s*child:\s*Text\(', r'Center(child: Text(', content)
            content = re.sub(r'const\s+\[([^\]]*\.tr[^\]]*)\]', r'[\1]', content)
            content = re.sub(r'const\s+DropdownMenuItem', r'DropdownMenuItem', content)
            content = re.sub(r"const\s+\[(\s*DropdownMenuItem[^\]]*\.tr)\]", r"[\1]", content)

            if content != original_content:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(content)
