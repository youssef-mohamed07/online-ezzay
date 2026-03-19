import json
import urllib.request
import urllib.parse
import time

def translate(text):
    url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=ar&tl=en&dt=t&q=" + urllib.parse.quote(text)
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode())
            return "".join([part[0] for part in data[0]])
    except Exception as e:
        print(e)
        return text

with open('missing.json', 'r', encoding='utf-8') as f:
    missing = json.load(f)

with open('translation_cache.json', 'r', encoding='utf-8') as f:
    cache = json.load(f)

print(f"Translating {len(missing)} items...")
for i, m in enumerate(missing):
    cache[m] = translate(m)
    if i % 10 == 0:
        print(f"Done {i}/{len(missing)}")
    time.sleep(0.1)  # small delay to prevent blocking

with open('translation_cache.json', 'w', encoding='utf-8') as f:
    json.dump(cache, f, ensure_ascii=False, indent=2)

print("done")