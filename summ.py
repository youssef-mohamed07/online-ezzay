import os

with open('analyze_res2.txt', 'r', encoding='utf-8') as f:
    text = f.read()

lines = text.split('\n')
const_errs = [l.strip() for l in lines if 'const_eval_extension_method' in l]
other_errs = [l.strip() for l in lines if 'error' in l.lower() and 'const_eval_extension_method' not in l]

print(f"Found {len(const_errs)} const errors and {len(other_errs)} other errors.")
with open('summary_errors.txt', 'w', encoding='utf-8') as f:
    f.write("CONST ERRORS:\n")
    f.write('\n'.join(const_errs))
    f.write("\n\nOTHER ERRORS:\n")
    f.write('\n'.join(other_errs))
