import 'package:online_ezzy/core/app_translations.dart';
import 'package:flutter/material.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartItem {
  final String id;
  final String title;
  final String subtitle;
  final double price;
  final String imagePath;

  _CartItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.imagePath,
  });
}

enum PaymentMethod { visa, googlePay, paypal, link }

class _CartPageState extends State<CartPage> {
  PaymentMethod _selectedPayment = PaymentMethod.visa;

  List<_CartItem> cartItems = [
    _CartItem(
      id: '1',
      title: 'باقة 3 طرود',
      subtitle: 'طلب توصيل',
      price: 30.00,
      imagePath: 'lib/assets/images/home/اطلب توصيل.png',
    ),
    _CartItem(
      id: '2',
      title: 'العنوان الأمريكي',
      subtitle: 'الباقة الذهبية',
      price: 30.00,
      imagePath: 'lib/assets/images/home/العناوين.png',
    ),
    _CartItem(
      id: '3',
      title: 'Wise Starter',
      subtitle: '120\$',
      price: 120.00,
      imagePath: 'lib/assets/images/home/خدمات مالية.png',
    ),
  ];

  void _removeItem(String id) {
    setState(() {
      cartItems.removeWhere((item) => item.id == id);
    });
  }

  void _clearCart() {
    setState(() {
      cartItems.clear();
    });
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
          automaticallyImplyLeading: false, // لا نريد سهم رجوع لأنها من ضمن القوائم
          title: Text(
            'السلة'.tr,
            style: TextStyle(
              color: Color(0xFF1E3A5F),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: cartItems.isEmpty
            ? Center(
                child: Text(
                  'السلة فارغة',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    // زر تفريغ السلة
                    Align(
                      alignment: Alignment.center,
                      child: TextButton.icon(
                        onPressed: _clearCart,
                        icon: Icon(Icons.refresh,
                            color: Colors.grey, size: 18),
                        label: Text(
                          'تفريغ السلة',
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),

                    // قائمة عناصر السلة
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cartItems.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildCartItem(cartItems[index]);
                      },
                    ),

                    SizedBox(height: 24),

                    // طرق الدفع
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
                          Text(
                            'طريقة الدفع',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A5F),
                            ),
                          ),
                          SizedBox(height: 16),
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
                    SizedBox(height: 100), // مساحة للزر السفلي
                  ],
                ),
              ),

        // الزر السفلي
        bottomSheet: Container(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 20),
          color: const Color(0xFFF8F9FA),
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: cartItems.isEmpty ? null : () {
                // إتمام الدفع
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'إتمام الدفع',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartItem(_CartItem item) {
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
              // صورة المنتج
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    item.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.image, color: Colors.grey),
                  ),
                ),
              ),
              SizedBox(width: 16),
              // تفاصيل المنتج
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              // زر الحذف
              InkWell(
                onTap: () => _removeItem(item.id),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.delete_outline, color: Colors.red, size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'السعر',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                item.price == item.price.toInt()
                    ? '\$${item.price.toInt()}'
                    : '\$${item.price.toStringAsFixed(2)}',
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
    );
  }

  Widget _buildPaymentOption(
      PaymentMethod method, String title, IconData iconData, Color iconColor,
      {double iconSize = 24}) {
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
            Icon(
              iconData,
              color: iconColor,
              size: iconSize,
            ),
          ],
        ),
      ),
    );
  }
}
