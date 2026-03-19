import json
import os
import re

cache_file = 'translation_cache.json'
with open(cache_file, 'r', encoding='utf-8') as f:
    cache = json.load(f)

all_arabic_strings = set()
dart_files = []
for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            dart_files.append(os.path.join(root, file))

for path in dart_files:
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    matches = re.finditer(r"(['\"])(.*?)\1", content)
    for m in matches:
        s = m.group(2)
        if re.search(r'[\u0600-\u06FF]', s):
            all_arabic_strings.add(s)

missing = [s for s in all_arabic_strings if s not in cache]
print(json.dumps(missing, ensure_ascii=False, indent=2))
