import os
import re

for root, _, files in os.walk('lib/views'):
    for file in files:
        if file.endswith('.dart'):
            with open(os.path.join(root, file), 'r', encoding='utf-8') as f:
                content = f.read()

            # Remove const before Text
            content = re.sub(r'\bconst\s+Text\b', 'Text', content)
            # Remove const before AuthTextField
            content = re.sub(r'\bconst\s+AuthTextField\b', 'AuthTextField', content)
            # Remove const before arrays that might contain tr
            # It's an array: const [ ... ] -> [ ... ]
            # But just removing `const ` before `[` is risky.
            
            # Let's find any `const ` that precedes a block of code which contains `.tr`.
            # An easier way: just remove `const ` if the SAME LINE contains `.tr`
            lines = content.split('\n')
            for i in range(len(lines)):
                if '.tr' in lines[i]:
                    lines[i] = re.sub(r'\bconst\s+', '', lines[i])
                    # also look up to 5 lines above for a `const ` that might be wrapping this
                    for j in range(max(0, i-5), i):
                        if 'const ' in lines[j] and ('Center' in lines[j] or 'Column' in lines[j] or 'Row' in lines[j] or '[' in lines[j] or 'SnackBar' in lines[j] or '_SectionTitle' in lines[j] or 'AuthTextField' in lines[j]):
                            lines[j] = re.sub(r'\bconst\s+', '', lines[j])

            new_content = '\n'.join(lines)
            
            # Additional sweep for `const [` because of `children: const [`
            new_content = new_content.replace('children: const [', 'children: [')
            
            if new_content != content:
                with open(os.path.join(root, file), 'w', encoding='utf-8') as f:
                    f.write(new_content)

print('done')
