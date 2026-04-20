import re

with open('lib/views/screens/cart_page.dart', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("createPaymentIntent", "checkout")

with open('lib/views/screens/cart_page.dart', 'w', encoding='utf-8') as f:
    f.write(text)
