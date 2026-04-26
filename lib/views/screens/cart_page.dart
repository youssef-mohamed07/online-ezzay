import 'package:online_ezzy/core/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_ezzy/widgets/cached_image.dart';
import 'stripe_checkout_webview_page.dart';
import '../../core/api_service.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

enum _CheckoutMethod { stripe, direct }

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _isProcessingPayment = false;
  _CheckoutMethod _selectedCheckoutMethod = _CheckoutMethod.stripe;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartProvider = context.read<CartProvider>();
      cartProvider.refreshCart();
      cartProvider.refreshAvailablePaymentMethods();
    });
  }

  bool _isOrderCreated(Map<String, dynamic>? result) {
    if (result == null) return false;
    if (result['code'] != null || result['error'] != null) return false;

    final statusCode = result['status_code'] as int? ?? 0;
    if (statusCode >= 400) return false;

    final status = result['status']?.toString().toLowerCase() ?? '';
    if (status == 'failed' || status == 'cancelled' || status == 'canceled') {
      return false;
    }

    final hasOrderId = result['id'] != null;
    return hasOrderId ||
        status == 'processing' ||
        status == 'completed' ||
        status == 'pending' ||
        status == 'on-hold';
  }

  bool _isPaymentCompleted(Map<String, dynamic>? result) {
    if (!_isOrderCreated(result)) return false;

    final status = result?['status']?.toString().toLowerCase() ?? '';
    if (status == 'processing' || status == 'completed') {
      return true;
    }

    final paymentResult = result?['payment_result'];
    if (paymentResult is Map) {
      final paymentStatus =
          paymentResult['payment_status']?.toString().toLowerCase() ?? '';
      if (paymentStatus == 'success' || paymentStatus == 'succeeded') {
        return true;
      }
      if (paymentStatus == 'failure' || paymentStatus == 'failed') {
        return false;
      }
    }

    return false;
  }

  String _extractOrderError(Map<String, dynamic>? result) {
    if (result == null) return 'فشل إنشاء الطلب، حاول مرة أخرى'.tr;

    final message = result['message']?.toString();
    final data = result['data'];
    final nestedMessage = data is Map ? data['message']?.toString() : null;
    final code = result['code']?.toString();

    final combined = [
      message,
      nestedMessage,
      code,
    ].whereType<String>().join(' ').toLowerCase();

    if (combined.contains('account is already registered') ||
        combined.contains('email') && combined.contains('registered') ||
        combined.contains('registration-error-email-exists') ||
        combined.contains('تم تسجيل حساب بالفعل') ||
        combined.contains('يحمل') && combined.contains('البريد')) {
      return 'هذا البريد مسجل بالفعل. سجل الدخول أولاً بنفس الحساب ثم أعد الطلب.'
          .tr;
    }

    final paymentResult = result['payment_result'];
    if (paymentResult is Map) {
      final paymentDetails = paymentResult['payment_details'];
      if (paymentDetails is List) {
        for (final entry in paymentDetails) {
          if (entry is Map &&
              entry['key']?.toString() == 'errorMessage' &&
              (entry['value']?.toString().isNotEmpty ?? false)) {
            return entry['value'].toString();
          }
        }
      }
    }

    if (message != null && message.isNotEmpty) return message;
    if (nestedMessage != null && nestedMessage.isNotEmpty) return nestedMessage;
    if (code != null && code.isNotEmpty) return code;
    final statusCode = result['status_code']?.toString();
    if (statusCode != null && statusCode.isNotEmpty) {
      return 'فشل إنشاء الطلب (كود: $statusCode)'.tr;
    }
    return 'فشل إنشاء الطلب، حاول مرة أخرى'.tr;
  }

  Map<String, dynamic> _buildBillingAddress() {
    final userData = context.read<AuthProvider>().userData ?? {};
    final billing = userData['billing'] is Map
        ? Map<String, dynamic>.from(userData['billing'])
        : <String, dynamic>{};
    final shipping = userData['shipping'] is Map
        ? Map<String, dynamic>.from(userData['shipping'])
        : <String, dynamic>{};

    String pick(List<dynamic> values, String fallback) {
      for (final value in values) {
        final text = value?.toString().trim() ?? '';
        if (text.isNotEmpty) return text;
      }
      return fallback;
    }

    final guestEmail =
        'guest_${DateTime.now().millisecondsSinceEpoch}@onlineezzy.app';

    return {
      'first_name': pick([
        billing['first_name'],
        shipping['first_name'],
        userData['first_name'],
        userData['name'],
      ], 'Online'),
      'last_name': pick([
        billing['last_name'],
        shipping['last_name'],
        userData['last_name'],
      ], 'Ezzy'),
      'email': pick([billing['email'], userData['email']], guestEmail),
      'phone': pick([billing['phone'], userData['phone']], '0100000000'),
      'address_1': pick([
        billing['address_1'],
        shipping['address_1'],
      ], 'Online Ezzy'),
      'city': pick([billing['city'], shipping['city']], 'Hebron'),
      'state': pick([billing['state'], shipping['state']], 'Hebron'),
      'postcode': pick([billing['postcode'], shipping['postcode']], '00000'),
      'country': pick([
        billing['country'],
        shipping['country'],
        userData['country'],
      ], 'PS'),
    };
  }

  Map<String, dynamic> _buildGuestBillingAddress() {
    final billing = Map<String, dynamic>.from(_buildBillingAddress());
    billing['email'] =
        'guest_${DateTime.now().millisecondsSinceEpoch}@onlineezzy.app';
    return billing;
  }

  bool _isCountryRejected(Map<String, dynamic>? result) {
    if (result == null) return false;

    final message = result['message']?.toString() ?? '';
    final data = result['data'];
    final nested = data is Map ? data['message']?.toString() ?? '' : '';
    final combined = '$message $nested'.toLowerCase();

    return combined.contains('لا نسمح بالطلبات من البلد') ||
        combined.contains('submitted country') ||
        combined.contains('do not allow orders from the submitted country');
  }

  Future<Map<String, dynamic>?> _checkoutWithCountryFallback(
    CartProvider cartProvider,
    Map<String, dynamic> checkoutData, {
    bool useAuth = true,
  }) async {
    Map<String, dynamic>? attempt = await cartProvider.checkout(
      checkoutData,
      useAuth: useAuth,
    );

    if (!_isOrderCreated(attempt) && _isCountryRejected(attempt)) {
      final currentBilling = Map<String, dynamic>.from(
        checkoutData['billing_address'] as Map<String, dynamic>,
      );
      final currentCountry =
          currentBilling['country']?.toString().toUpperCase() ?? '';

      if (currentCountry.isEmpty || currentCountry == 'EG') {
        currentBilling['country'] = 'PS';
        currentBilling['state'] =
            (currentBilling['state']?.toString().isNotEmpty ?? false)
            ? currentBilling['state']
            : 'Hebron';

        final retryCheckout = {
          ...checkoutData,
          'billing_address': currentBilling,
        };
        attempt = await cartProvider.checkout(retryCheckout, useAuth: useAuth);
      }
    }

    return attempt;
  }

  String? _buildOrderPayUrl(Map<String, dynamic>? result) {
    if (result == null) return null;

    final orderId =
        result['order_id']?.toString() ?? result['id']?.toString() ?? '';
    final orderKey = result['order_key']?.toString() ?? '';
    if (orderId.isEmpty || orderKey.isEmpty) return null;

    return 'https://demo.onlineezzy.com/checkout/order-pay/$orderId/?pay_for_order=true&key=$orderKey';
  }

  int _extractItemQuantity(Map<String, dynamic> item) {
    final quantityRaw = item['quantity'];
    if (quantityRaw is Map) {
      return int.tryParse((quantityRaw['value'] ?? '1').toString()) ?? 1;
    }
    return int.tryParse(quantityRaw?.toString() ?? '1') ?? 1;
  }

  double _safeParseMajor(dynamic value) {
    final raw = value?.toString().trim().replaceAll(',', '.') ?? '';
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed.isNaN || parsed.isInfinite || parsed < 0) {
      return 0;
    }
    return parsed;
  }

  double _extractUnitPrice(Map<String, dynamic> item) {
    final prices = item['prices'];
    if (prices is Map) {
      final minor = int.tryParse(prices['price']?.toString() ?? '');
      if (minor != null && minor >= 0) {
        return minor / 100;
      }
    }
    return _safeParseMajor(item['price']);
  }

  double _extractLineTotal(Map<String, dynamic> item, int quantity) {
    final totals = item['totals'];
    if (totals is Map) {
      final lineMinor = int.tryParse(totals['line_total']?.toString() ?? '');
      final lineTaxMinor =
          int.tryParse(totals['line_total_tax']?.toString() ?? '0') ?? 0;
      if (lineMinor != null && lineMinor >= 0) {
        return (lineMinor + lineTaxMinor) / 100;
      }
    }

    return _extractUnitPrice(item) * quantity;
  }

  double _calculateCartTotalMajor(List<dynamic> items) {
    double total = 0;

    for (final raw in items) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      final quantity = _extractItemQuantity(item);
      total += _extractLineTotal(item, quantity);
    }

    return total;
  }

  String _formatPrice(double value) {
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  String _formatCurrency(double value, SettingsProvider settings) {
    return '${_formatPrice(value)} ${settings.currencySymbol}';
  }

  Future<Map<String, dynamic>?> _checkoutViaWebView(
    CartProvider cartProvider,
    Map<String, dynamic> baseCheckoutData,
    String paymentMethod,
  ) async {
    final checkoutData = {...baseCheckoutData, 'payment_method': paymentMethod};

    final firstAttempt = await _checkoutWithCountryFallback(
      cartProvider,
      checkoutData,
      useAuth: false,
    );

    if (_isPaymentCompleted(firstAttempt)) {
      return firstAttempt;
    }

    final payUrl = _buildOrderPayUrl(firstAttempt);
    if (payUrl == null || !mounted) {
      return firstAttempt;
    }

    final paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => StripeCheckoutWebViewPage(initialUrl: payUrl),
      ),
    );

    if (paid == true) {
      final normalized = Map<String, dynamic>.from(firstAttempt ?? {});
      final orderId =
          normalized['order_id']?.toString() ?? normalized['id']?.toString();

      if (orderId != null && orderId.isNotEmpty) {
        final latestOrder = await ApiService.getOrder(orderId);
        final latestStatus =
            latestOrder?['status']?.toString().toLowerCase() ?? '';
        if (latestStatus.isNotEmpty) {
          normalized['status'] = latestStatus;
          final paidStatuses = {'processing', 'completed'};
          normalized['payment_result'] = {
            'payment_status': paidStatuses.contains(latestStatus)
                ? 'success'
                : 'pending',
          };
          return normalized;
        }
      }

      final currentStatus =
          normalized['status']?.toString().toLowerCase() ?? '';
      normalized['status'] = currentStatus.isNotEmpty
          ? currentStatus
          : 'pending';
      normalized['payment_result'] = {'payment_status': 'pending'};
      return normalized;
    }

    return firstAttempt;
  }

  void _removeItem(String itemKey) {
    Provider.of<CartProvider>(context, listen: false).removeCartItem(itemKey);
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
        body: Consumer2<CartProvider, SettingsProvider>(
          builder: (context, cartProvider, settingsProvider, child) {
            if (cartProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.red),
              );
            }

            final cartItems = cartProvider.cartItems;
            final cartTotal = _calculateCartTotalMajor(cartItems);
            final knownMethods = cartProvider.availablePaymentMethods;
            final hasKnownMethods = knownMethods.isNotEmpty;
            final hasStripe =
                !hasKnownMethods || knownMethods.contains('stripe');
            final hasDirect =
                !hasKnownMethods ||
                knownMethods.any((m) => m == 'bacs' || m == 'cod');

            final checkoutHelpText =
                _selectedCheckoutMethod == _CheckoutMethod.stripe
                ? 'سيتم فتح صفحة Stripe الآمنة داخل نافذة مدمجة، وبعد الرجوع سنراجع حالة الطلب من المتجر.'
                      .tr
                : 'طلب مباشر بدون دفع إلكتروني من داخل التطبيق.'.tr;

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
                        Provider.of<CartProvider>(
                          context,
                          listen: false,
                        ).clearCart();
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
                      return _buildCartItem(cartItems[index], settingsProvider);
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
                          'الطريقة المتاحة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A5F),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPaymentOption(
                          title: 'الدفع بالبطاقة (Stripe)',
                          iconData: Icons.credit_card_rounded,
                          iconColor: const Color(0xFF0EA5E9),
                          selected:
                              _selectedCheckoutMethod == _CheckoutMethod.stripe,
                          enabled: hasStripe,
                          onTap: () {
                            setState(() {
                              _selectedCheckoutMethod = _CheckoutMethod.stripe;
                            });
                          },
                        ),
                        _buildPaymentOption(
                          title: 'طلب مباشر عبر النظام',
                          iconData: Icons.verified_rounded,
                          iconColor: const Color(0xFFE71D24),
                          selected:
                              _selectedCheckoutMethod == _CheckoutMethod.direct,
                          enabled: hasDirect,
                          onTap: () {
                            setState(() {
                              _selectedCheckoutMethod = _CheckoutMethod.direct;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          checkoutHelpText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'الإجمالي النهائي',
                                style: TextStyle(
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                _formatCurrency(cartTotal, settingsProvider),
                                style: const TextStyle(
                                  color: Color(0xFF1E3A5F),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
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
        bottomSheet: Consumer2<CartProvider, SettingsProvider>(
          builder: (context, cartProvider, settingsProvider, child) {
            final cartTotal = _calculateCartTotalMajor(cartProvider.cartItems);
            final isDirectFlow =
                _selectedCheckoutMethod == _CheckoutMethod.direct;

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
                  onPressed:
                      cartProvider.cartItems.isEmpty || _isProcessingPayment
                      ? null
                      : () async {
                          setState(() {
                            _isProcessingPayment = true;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('جاري إنشاء الطلب...'.tr)),
                          );

                          try {
                            final baseCheckoutData = {
                              'billing_address':
                                  _selectedCheckoutMethod ==
                                      _CheckoutMethod.stripe
                                  ? _buildGuestBillingAddress()
                                  : _buildBillingAddress(),
                              'create_account': false,
                            };

                            Map<String, dynamic>? result;
                            final availableMethods = await cartProvider
                                .refreshAvailablePaymentMethods();

                            if (_selectedCheckoutMethod ==
                                _CheckoutMethod.stripe) {
                              if (!availableMethods.contains('stripe')) {
                                throw Exception(
                                  'Stripe غير متاح حالياً من إعدادات المتجر'.tr,
                                );
                              }

                              result = await _checkoutViaWebView(
                                cartProvider,
                                baseCheckoutData,
                                'stripe',
                              );
                            } else {
                              final directMethods = <String>[];
                              if (availableMethods.contains('cod')) {
                                directMethods.add('cod');
                              }
                              if (availableMethods.contains('bacs')) {
                                directMethods.add('bacs');
                              }
                              if (directMethods.isEmpty) {
                                throw Exception(
                                  'لا توجد طريقة طلب مباشر متاحة حالياً'.tr,
                                );
                              }

                              for (final method in directMethods) {
                                final checkoutData = {
                                  ...baseCheckoutData,
                                  'payment_method': method,
                                };
                                final attempt =
                                    await _checkoutWithCountryFallback(
                                      cartProvider,
                                      checkoutData,
                                    );
                                result = attempt;
                                if (_isOrderCreated(attempt)) break;
                              }
                            }

                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            final orderCreated = _isOrderCreated(result);
                            final paymentCompleted = _isPaymentCompleted(
                              result,
                            );

                            if ((isDirectFlow && orderCreated) ||
                                (!isDirectFlow && paymentCompleted)) {
                              final orderId = result?['id']?.toString();
                              final isPaidFlow =
                                  _selectedCheckoutMethod !=
                                  _CheckoutMethod.direct;
                              final successText = isPaidFlow
                                  ? (orderId != null
                                        ? 'تم الدفع بنجاح وإنشاء الطلب! رقم الطلب: $orderId'
                                        : 'تم الدفع بنجاح وإنشاء الطلب!')
                                  : (orderId != null
                                        ? 'تم إنشاء الطلب بنجاح! رقم الطلب: $orderId'
                                        : 'تم إنشاء الطلب بنجاح!');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(successText.tr),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else if (!isDirectFlow &&
                                orderCreated &&
                                result != null) {
                              final orderId = result['id']?.toString();
                              final pendingText = orderId != null
                                  ? 'تم إنشاء الطلب رقم $orderId لكن الدفع لم يتأكد بعد. أكمل الدفع من صفحة الدفع.'
                                  : 'تم إنشاء الطلب لكن الدفع لم يتأكد بعد. أكمل الدفع من صفحة الدفع.';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(pendingText.tr),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_extractOrderError(result)),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'فشل إتمام الطلب: ${e.toString()}',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isProcessingPayment = false;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _isProcessingPayment
                        ? (isDirectFlow
                              ? 'جاري إنشاء الطلب...'.tr
                              : 'جاري الدفع وإنشاء الطلب...'.tr)
                        : (isDirectFlow
                              ? 'تأكيد الطلب (${_formatCurrency(cartTotal, settingsProvider)})'.tr
                              : 'ادفع الآن (${_formatCurrency(cartTotal, settingsProvider)})'.tr),
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

  Widget _buildCartItem(dynamic item, SettingsProvider settings) {
    final itemMap = item is Map
        ? Map<String, dynamic>.from(item)
        : <String, dynamic>{};

    print('🛍️ Cart item data: $itemMap');
    
    final id = itemMap['key']?.toString() ?? itemMap['id']?.toString() ?? '';
    final title = itemMap['name']?.toString() ?? 'منتج';
    final subtitle = itemMap['description']?.toString() ?? '';
    final quantity = _extractItemQuantity(itemMap);
    final unitPrice = _extractUnitPrice(itemMap);
    final lineTotal = _extractLineTotal(itemMap, quantity);
    
    print('🛍️ Extracted - title: $title, subtitle: $subtitle, quantity: $quantity');

    var imageUrl = '';
    if (itemMap['images'] != null && itemMap['images'].isNotEmpty) {
      imageUrl = itemMap['images'][0]['src'] ?? '';
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
                  child: CachedImage(
                    imageUrl: imageUrl,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
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
                    const SizedBox(height: 4),
                    Text(
                      'الكمية: $quantity × ${_formatCurrency(unitPrice, settings)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                'الإجمالي',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Text(
                    _formatCurrency(lineTotal, settings),
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

  Widget _buildPaymentOption({
    required String title,
    required IconData iconData,
    required Color iconColor,
    required bool selected,
    required bool enabled,
    required VoidCallback onTap,
    double iconSize = 24,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected
                    ? const Color(0xFFE71D24)
                    : const Color(0xFF94A3B8),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
              ),
              Icon(iconData, color: iconColor, size: iconSize),
            ],
          ),
        ),
      ),
    );
  }
}
