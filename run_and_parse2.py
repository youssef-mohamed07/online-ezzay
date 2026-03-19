import os
import subprocess
import re

print("Running flutter analyze...")
result = subprocess.run('flutter analyze', shell=True, capture_output=True, text=True, encoding='utf-8')

with open('analyze_output_latest.txt', 'w', encoding='utf-8') as f:
    f.write(result.stdout)

lines = result.stdout.split('\n')
const_errs = [l.strip() for l in lines if 'const_eval_extension_method' in l]

print(f"Found {len(const_errs)} const errors.")
with open('summary_errors_latest.txt', 'w', encoding='utf-8') as f:
    f.write("CONST ERRORS:\n")
    f.write('\n'.join(const_errs))

print("Done. Wrote summary_errors_latest.txt")
