import os
import re

output = r'''
  error - Extension methods can't be used in constant expressions -
         lib\views\screens\auth\auth_layout.dart:12:24 -
         const_eval_extension_method
  error - Extension methods can't be used in constant expressions -
         lib\views\screens\auth\forgot_password_page.dart:25:20 -
         const_eval_extension_method
         lib\views\screens\auth\forgot_password_page.dart:26:20 -
         const_eval_extension_method
         lib\views\screens\auth\otp_verification_page.dart:24:20 -
         const_eval_extension_method
         lib\views\screens\auth\reset_password_page.dart:24:20 -
         const_eval_extension_method
         lib\views\screens\auth\reset_password_page.dart:30:20 -
         const_eval_extension_method
         lib\views\screens\auth\reset_password_page.dart:40:22 -
         const_eval_extension_method
'''

# Wait, let's just make a script that removes `const ` if the line has `.tr`
def fix_const_tr(root_dir='lib'):
    for root, _, files in os.walk(root_dir):
        for file in files:
            if file.endswith('.dart'):
                path = os.path.join(root, file)
                with open(path, 'r', encoding='utf-8') as f:
                    lines = f.readlines()
                
                changed = False
                for i in range(len(lines)):
                    if '.tr' in lines[i] and 'const ' in lines[i]:
                        lines[i] = re.sub(r'\bconst\s+', '', lines[i])
                        changed = True
                    
                    # Also look for multiline where 'const' is on previous lines and '.tr' next
                    # A better way is to do it on the whole content
                
                if changed:
                    with open(path, 'w', encoding='utf-8') as f:
                        f.writelines(lines)

fix_const_tr()
