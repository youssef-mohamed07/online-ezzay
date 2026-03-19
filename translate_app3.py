import os
import re
from deep_translator import GoogleTranslator
import time

translator = GoogleTranslator(source='ar', target='en')
cache = {}
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
    if re.search(r'[\u0600-\u06FF]', original):
        has_interpolation = '$' in original
        
        for k, v in overrides.items():
            if k == original:
                return v
        
        if original not in cache:
            try:
                time.sleep(0.1) # prevent rate limit
                if has_interpolation:
                    def repl_arabic_block(m):
                        block = m.group(0)
                        return translator.translate(block)
                    translated = re.sub(r'[\u0600-\u06FF\s]+', repl_arabic_block, original)
                else:
                    translated = translator.translate(original)
                if not translated:
                    translated = original
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

    # 1. Fix RTL to LTR
    content = content.replace("TextDirection.rtl", "TextDirection.ltr")
    # Also change 'ar' to 'en' in locale
    content = content.replace("Locale('ar')", "Locale('en')")
    
    def string_replacer(m):
        quote_char = m.group(1)
        inner_text = m.group(2)
        translated = translate_arabic(inner_text)
        return f"{quote_char}{translated}{quote_char}"
        
    try:
        new_content = re.sub(r"(')(.*?)(')", string_replacer, content)
        new_content = re.sub(r'(")(.*?)(")', string_replacer, new_content)
    except Exception as e:
        print(f"Failed regex on {filepath}")
        return

    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f'Translated and updated {filepath}')

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))

print('Done')
