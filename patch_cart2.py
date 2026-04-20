import re

with open('lib/views/screens/cart_page.dart', 'r', encoding='utf-8') as f:
    text = f.read()

old_block = """                              final paymentIntentData = await cartProvider.checkout(
                                amount,
                                'usd', // Currency
                                'pm_card_visa', // Payment method (card) Example
                              );"""
                              
new_block = """                              final paymentIntentData = await cartProvider.createPaymentIntent(
                                amount,
                                'usd', // Currency
                                'pm_card_visa', // Payment method (card) Example
                              );"""
                              
text = text.replace(old_block, new_block)

with open('lib/views/screens/cart_page.dart', 'w', encoding='utf-8') as f:
    f.write(text)
