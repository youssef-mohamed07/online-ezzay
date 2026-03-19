import os
import re
from deep_translator import GoogleTranslator

# Translator
translator = GoogleTranslator(source='ar', target='en')

# Dictionary to cache translations so we don't repeat
cache = {}

# Also keep track of manual overrides where translator fails context
overrides = {
    'الاسم الكامل': 'Full Name',
    'البريد الإلكتروني': 'Email',
    'كلمة المرور': 'Password',
    'تسجيل الدخول': 'Sign In',
    'إنشاء حساب': 'Sign Up',
    'الرئيسية': 'Home',
    'الشحنات': 'Shipments',
    'حسابي': 'Profile',
    'عن التطبيق': 'About App',
    'تسجيل الخروج': 'Logout'
}

def translate_arabic(text):
    original = text
    # Check if string contains arabic
    if re.search(r'[\u0600-\u06FF]', original):
        # We need to protect variable interpolations like $variable or ${variable}
        has_interpolation = '$' in original
        
        # very simple handling: if there's an exact override
        for k, v in overrides.items():
            if k == original:
                return v
        
        if original not in cache:
            try:
                # remove interpolations for safety, or better yet just let translator handle it, 
                # but googletrans often adds spaces around $, destroying Dart syntax.
                # So if there's $ we just try replacing the arabic words only.
                if has_interpolation:
                    # just translate blocks of arabic text
                    def repl_arabic_block(m):
                        block = m.group(0)
                        return translator.translate(block)
                    translated = re.sub(r'[\u0600-\u06FF\s]+', repl_arabic_block, original)
                else:
                    translated = translator.translate(original)
                cache[original] = translated
                return translated
            except Exception as e:
                print(f'Error translating: {original}')
                return original
        return cache[original]
    return original

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Flip Directions
    content = content.replace("TextDirection.rtl", "TextDirection.ltr")
    content = content.replace("alignment: AlignmentDirectional.centerStart", "alignment: AlignmentDirectional.centerStart") # RTL aware already! Actually flutter handles directional based on directionality.
    
    # 2. Iterate and replace single-quoted strings containing Arabic
    # Also double quoted
    # We use a custom replacement function
    def string_replacer(m):
        quote_char = m.group(1)
        inner_text = m.group(2)
        translated = translate_arabic(inner_text)
        return f"{quote_char}{translated}{quote_char}"
        
    new_content = re.sub(r"(')(.*?)(')", string_replacer, content)
    new_content = re.sub(r'(")(.*?)(")', string_replacer, new_content)

    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f'Translated and updated {filepath}')

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))

print('Done')
