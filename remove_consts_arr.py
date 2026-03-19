import os
import re

for root, _, files in os.walk('lib/views'):
    for file in files:
        if file.endswith('.dart'):
            with open(os.path.join(root, file), 'r', encoding='utf-8') as f:
                content = f.read()

            content = content.replace('const [', '[')
            content = content.replace('const <Widget>[', '<Widget>[')
            content = content.replace('const SliverGridDelegate', 'SliverGridDelegate')
            
            with open(os.path.join(root, file), 'w', encoding='utf-8') as f:
                f.write(content)

print("done")
