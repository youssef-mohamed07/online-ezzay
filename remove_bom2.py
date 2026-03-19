import os

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
            if '\ufeff' in content:
                content = content.replace('\ufeff', '')
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"Removed BOM char from {path}")
