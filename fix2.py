
import os
import re

lib_dir = 'lib/src/pages'

# Patterns
# 1. Icons.arrow_back_ios
pattern1 = re.compile(r'\s*leading:\s*IconButton\(\s*icon:\s*const\s*Icon\(Icons\.arrow_back_ios[^)]*\),\s*onPressed:\s*\(\)\s*=>\s*Navigator\.(?:of\(context\)\.)?pop\([^)]*\),\s*\),', re.MULTILINE)

# 2. profile page custom leading fallback
pattern2 = re.compile(r'icon:\s*const\s*Icon\(Icons\.arrow_forward,\s*color:\s*Colors\.black87\),', re.MULTILINE)

# 3. other stray explicit back buttons? let's just make it simple.

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            new_content = pattern1.sub('', content)
            new_content = pattern2.sub('icon: const Icon(Icons.arrow_forward),', new_content)
            
            if new_content != content:
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f'Fixed {path}')

