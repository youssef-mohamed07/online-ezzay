
import os
import re

lib_dir = 'lib/src/pages'
pattern = re.compile(r'\s*leading:\s*IconButton\(\s*icon:\s*const\s*Icon\(Icons\.arrow_forward,\s*color:\s*Colors\.black87\),\s*onPressed:\s*\(\)\s*=>\s*Navigator\.pop\(context\),\s*\),', re.MULTILINE)

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
            new_content = pattern.sub('', content)
            if new_content != content:
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f'Fixed {path}')

