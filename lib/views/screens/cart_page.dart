import 'package:online_ezzy/core/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

enum PaymentMethod { visa, googlePay, paypal, link }

class _CartPageState extends State<CartPage> {
  PaymentMethod _selectedPayment = PaymentMethod.visa;

  void _removeItem(String itemKey) {
    Provider.of<CartProvider>(context, listen: false).removeCartItem(itemKey);
  }

  void _updateQuantity(String itemKey, int currentQuantity, int change) {
    final newQuantity = currentQuantity + change;
    if (newQuantity < 1) {
      _removeItem(itemKey);
    } else {
      Provider.of<CartProvider>(context, listen: false)
          .updateCartItemQuantity(itemKey, newQuantity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            'السلة'.tr,
            style: const TextStyle(
              color: Color(0xFF1E3A5F),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: Consumer<CartProvider>(
          builder: (context, cartProvider, child) {
            if (cartProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.red),
              );
            }

            final cartItems = cartProvider.cartItems;

            if (cartItems.isEmpty) {
              return const Center(
                child: Text(
                  'السلة فارغة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: TextButton.icon(
                      onPressed: () {
                         Provider.of<CartProvider>(context, listen: false).clearCart();
                      },
                      icon: const Icon(
                        Icons.refresh,
                        color: Colors.grey,
                        size: 18,
                      ),
                      label: const Text(
                        'تفريغ السلة',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cartItems.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildCartItem(cartItems[index]);
                    },
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.04),
                          blurRadius: 10,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'طريقة الدفع',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A5F),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPaymentOption(
                          PaymentMethod.visa,
                          'الدفع عن طريق الفيزا',
                          Icons.credit_card_outlined,
                          Colors.grey.shade700,
                        ),
                        _buildPaymentOption(
                          PaymentMethod.googlePay,
                          'Google pay',
                          Icons.g_mobiledata,
                          Colors.orange,
                          iconSize: 32,
                        ),
                        _buildPaymentOption(
                          PaymentMethod.paypal,
                          'PayPal',
                          Icons.paypal,
                          Colors.blue,
                        ),
                        _buildPaymentOption(
                          PaymentMethod.link,
                          'Link',
                          Icons.link,
                          Colors.green,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
        bottomSheet: Consumer<CartProvider>(
          builder: (context, cartProvider, child) {
            return Container(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 20,
              ),
              color: const Color(0xFFF8F9FA),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: cartProvider.cartItems.isEmpty
                      ? null
                      : () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('جاري معالجة الطلب وإتمام الدفع...'),
                            ),
                          );

                          // Step 1: Calculate total amount here (e.g., from cartProvider or predefined)
                          int amount = 2000; // Example: $20.00 -> 2000 cents. Update logic based on cart logic
                          
                          // Example checkout data (normally collected from a form)
                          final checkoutData = {
                            'billing_address': {
                              'first_name': 'Test',
                              'last_name': 'User',
                              'email': 'test@example.com',
                              'phone': '0100000000',
                            },
                            'payment_method': _selectedPayment == PaymentMethod.visa ? 'stripe' : 'bacs',
                          };

                          if (_selectedPayment == PaymentMethod.visa) {
                            try {
                              // Create Payment Intent via your Backend
                              final paymentIntentData = await cartProvider.createPaymentIntent(
                                amount,
                                'usd', // Currency
                                'pm_card_visa', // Payment method (card) Example
                              );
                              
                              if (paymentIntentData != null && paymentIntentData['client_secret'] != null) {
                                final clientSecret = paymentIntentData['client_secret'];
                                final paymentIntentId = paymentIntentData['id'];

                                // Initialize Stripe Payment Sheet (Frontend)
                                await Stripe.instance.initPaymentSheet(
                                  paymentSheetParameters: SetupPaymentSheetParameters(
                                    paymentIntentClientSecret: clientSecret,
                                    merchantDisplayName: 'Online Ezzy',
                                  ),
                                );

                                // Present Stripe Payment Sheet (Frontend)
                                await Stripe.instance.presentPaymentSheet();

                                // Optional: Confirm from Backend if required 
                                // await cartProvider.confirmPaymentIntent(paymentIntentId, { 'payment_method': 'pm_card_visa' });
                                
                                // Success! Now place the actual order in WooCommerce
                                checkoutData['payment_data'] = [
                                  {
                                    'key': 'payment_method',
                                    'value': paymentIntentId,
                                  }
                                ];
                              } else {
                                throw Exception("فشل في استخراج بيانات الدفع.");
                              }
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('فشل عملية الدفع: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return; // Stop execution on payment failure
                            }
                          }

                          final result = await cartProvider.checkout(
                            checkoutData,
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();

                          if (result != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم الدفع بنجاح!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('فشل عملية إنشاء الطلب، حاول مرة أخرى'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'إتمام الدفع',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCartItem(dynamic item) {
    // Assuming WooCommerce Store API response structure
    final id = item['key'] ?? item['id']?.toString() ?? '';
    final title = item['name'] ?? 'منتج';
    final subtitle = item['description'] ?? '';

    var rawPrice = '0';
    if (item['prices'] != null && item['prices']['price'] != null) {
      rawPrice = (int.parse(item['prices']['price'].toString()) / 100)
          .toString(); // often in cents
    } else if (item['price'] != null) {
      rawPrice = item['price'].toString();
    }

    final quantity = item['quantity'] ?? 1;

    // images
    var imageUrl = '';
    if (item['images'] != null && item['images'].isNotEmpty) {
      imageUrl = item['images'][0]['src'] ?? '';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.04),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image, color: Colors.grey),
                        )
                      : const Icon(Icons.image, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              InkWell(
                onTap: () => _removeItem(id),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Text(
                        'حذف',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.delete_outline, color: Colors.red, size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'السعر',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => _updateQuantity(id, quantity, 1),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Icon(Icons.add, size: 18, color: Color(0xFF1E3A5F)),
                          ),
                        ),
                        Text(
                          quantity.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A5F),
                          ),
                        ),
                        InkWell(
                          onTap: () => _updateQuantity(id, quantity, -1),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Icon(Icons.remove, size: 18, color: Color(0xFF1E3A5F)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '\scripts_cart.py{(double.tryParse(rawPrice) ?? 0) * quantity}',
                    style: const TextStyle(
                      color: Color(0xFF1E3A5F),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
    PaymentMethod method,
    String title,
    IconData iconData,
    Color iconColor, {
    double iconSize = 24,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPayment = method;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: Colors.transparent,
        child: Row(
          children: [
            Radio<PaymentMethod>(
              value: method,
              groupValue: _selectedPayment,
              onChanged: (PaymentMethod? value) {
                if (value != null) {
                  setState(() {
                    _selectedPayment = value;
                  });
                }
              },
              activeColor: Colors.red,
            ),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E3A5F),
                ),
              ),
            ),
            Icon(iconData, color: iconColor, size: iconSize),
          ],
        ),
      ),
    );
  }
}
