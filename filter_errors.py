import sys
with open('analyze_res.txt', 'r', encoding='utf-8') as f:
    text = f.read()

lines = [line for line in text.split('\n') if 'const_eval_extension_method' in line]
with open('const_errors.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))
print(f"Wrote {len(lines)} errors")
