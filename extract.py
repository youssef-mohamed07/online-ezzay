import os
import re

texts = set()
for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            with open(os.path.join(root, file), 'r', encoding='utf-8') as f:
                for line in f:
                    # Find strings conceptually
                    matches = re.findall(r"['\"](.*?)['\"]", line)
                    for m in matches:
                        if re.search(r'[\u0600-\u06FF]', m):
                            texts.add(m)

import json
with open('arabic_strings.json', 'w', encoding='utf-8') as f:
    json.dump(list(texts), f, ensure_ascii=False, indent=2)
print(f"Extracted {len(texts)} strings")
