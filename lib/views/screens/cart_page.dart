import 'package:online_ezzy/core/app_translations.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:online_ezzy/widgets/cached_image.dart';
import '../../agent_debug_log.dart';
import '../../core/api_service.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/payment_service.dart';
import 'paypal_approval_page.dart';

enum _CheckoutMethod { stripe, paypal, direct }

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

    final hasOrderId = result['id'] != null || result['order_id'] != null;
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
      ], 'OnlineEzzy'),
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
    // REMOVED - No longer needed with native Stripe
    return null;
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

  String _cleanErrorMessage(dynamic error) {
    final raw = error?.toString().trim() ?? '';
    if (raw.isEmpty) return 'فشل إتمام الطلب';
    var text = raw;
    while (text.startsWith('Exception: ')) {
      text = text.substring('Exception: '.length).trim();
    }
    return text.isEmpty ? 'فشل إتمام الطلب' : text;
  }

  Future<void> _storeSuccessfulOrder({
    required String orderId,
    required String status,
    required String paymentMethodTitle,
    required double totalMajor,
    required String currencyCode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('local_success_orders');
    final existing = <Map<String, dynamic>>[];
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              existing.add(Map<String, dynamic>.from(item));
            }
          }
        }
      } catch (_) {}
    }

    // Keep newest copy for same order id.
    existing.removeWhere((o) => o['id']?.toString() == orderId);
    existing.insert(0, {
      'id': orderId,
      'status': status,
      'date_created': DateTime.now().toIso8601String(),
      'total': totalMajor.toStringAsFixed(2),
      'currency': currencyCode.toUpperCase(),
      'payment_method_title': paymentMethodTitle,
      'line_items': const [
        {'name': 'طلب جديد', 'quantity': 1},
      ],
      'is_local_cached': true,
    });

    // Avoid unbounded growth.
    if (existing.length > 30) {
      existing.removeRange(30, existing.length);
    }

    await prefs.setString('local_success_orders', jsonEncode(existing));
  }

  /// Native Stripe payment flow (UPDATED - works with existing backend)
  Future<Map<String, dynamic>?> _checkoutNativeStripe(
    CartProvider cartProvider,
    Map<String, dynamic> billingAddress,
    double amount,
    String currency,
  ) async {
    try {
      final cartToken = cartProvider.cartToken;
      if (cartToken == null || cartToken.isEmpty) {
        throw Exception('Cart token is missing');
      }

      // #region agent log
      agentDebugLog(
        location: 'cart_page.dart:_checkoutNativeStripe',
        message: 'checkout input summary',
        hypothesisId: 'H6',
        data: {
          'amount': amount,
          'currency': currency.toLowerCase(),
          'cartItemCount': cartProvider.cartItems.length,
        },
      );
      // #endregion

      // Process native Stripe payment
      final result = await PaymentService.processNativeStripePayment(
        amount: amount,
        currency: currency,
        cartToken: cartToken,
        billingAddress: billingAddress,
        merchantDisplayName: 'OnlineEzzy',
      );

      return result;
    } catch (e) {
      return {
        'success': false,
        'error': true,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> _checkoutPaypalFlow({
    required CartProvider cartProvider,
    required Map<String, dynamic> billingAddress,
  }) async {
    final cartToken = cartProvider.cartToken;
    if (cartToken == null || cartToken.isEmpty) {
      throw Exception('Cart token is missing');
    }

    final create = await ApiService.createPaypalOrder(cartToken: cartToken);
    final createStatus = create['status_code'] as int? ?? 500;
    if (createStatus >= 400) {
      throw Exception(
        create['message']?.toString().isNotEmpty == true
            ? create['message'].toString()
            : 'فشل إنشاء طلب PayPal',
      );
    }

    final approvalUrl =
        create['approval_url']?.toString() ??
        create['approve_url']?.toString() ??
        '';
    final createdOrderId = create['paypal_order_id']?.toString() ?? '';
    if (approvalUrl.isEmpty || createdOrderId.isEmpty) {
      throw Exception('رد إنشاء طلب PayPal غير مكتمل');
    }

    final returnedToken = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => PayPalApprovalPage(approvalUrl: approvalUrl),
      ),
    );
    final paypalOrderId = (returnedToken?.trim().isNotEmpty ?? false)
        ? returnedToken!.trim()
        : createdOrderId;

    return ApiService.capturePaypalOrder(
      paypalOrderId: paypalOrderId,
      cartToken: cartToken,
      billingAddress: billingAddress,
    );
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
            final hasPaypal =
                knownMethods.contains('paypal') ||
                knownMethods.any((m) => m.contains('ppcp'));
            final hasDirect =
                !hasKnownMethods ||
                knownMethods.any((m) => m == 'bacs' || m == 'cod');

            final checkoutHelpText =
                _selectedCheckoutMethod == _CheckoutMethod.stripe
                ? 'سيتم فتح نافذة الدفع الآمنة من Stripe مباشرة داخل التطبيق.'
                      .tr
                : _selectedCheckoutMethod == _CheckoutMethod.paypal
                ? 'سيتم إرسال الطلب عبر بوابة PayPal من إعدادات المتجر.'.tr
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
                          title: 'الدفع عبر PayPal',
                          iconData: Icons.account_balance_wallet_rounded,
                          iconColor: const Color(0xFF2563EB),
                          selected:
                              _selectedCheckoutMethod == _CheckoutMethod.paypal,
                          enabled: hasPaypal,
                          onTap: () {
                            setState(() {
                              _selectedCheckoutMethod = _CheckoutMethod.paypal;
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
            final isPaypalFlow =
                _selectedCheckoutMethod == _CheckoutMethod.paypal;

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
                            SnackBar(content: Text('جاري المعالجة...'.tr)),
                          );

                          try {
                            final billingAddress =
                                _selectedCheckoutMethod ==
                                    _CheckoutMethod.stripe
                                ? (context.read<AuthProvider>().isAuthenticated
                                      ? _buildBillingAddress()
                                      : _buildGuestBillingAddress())
                                : _buildBillingAddress();

                            Map<String, dynamic>? result;
                            final availableMethods = await cartProvider
                                .refreshAvailablePaymentMethods();

                            if (_selectedCheckoutMethod ==
                                _CheckoutMethod.stripe) {
                              // Native Stripe Payment (NEW)
                              if (!availableMethods.contains('stripe')) {
                                throw Exception(
                                  'Stripe غير متاح حالياً من إعدادات المتجر'.tr,
                                );
                              }

                              result = await _checkoutNativeStripe(
                                cartProvider,
                                billingAddress,
                                cartTotal,
                                settingsProvider.currencyCode ?? 'USD',
                              );
                            } else if (_selectedCheckoutMethod ==
                                _CheckoutMethod.paypal) {
                              final paypalMethod = availableMethods.firstWhere(
                                (m) => m == 'paypal' || m.contains('ppcp'),
                                orElse: () => '',
                              );
                              if (paypalMethod.isEmpty) {
                                throw Exception(
                                  'PayPal غير متاح حالياً من إعدادات المتجر'.tr,
                                );
                              }
                              result = await _checkoutPaypalFlow(
                                cartProvider: cartProvider,
                                billingAddress: billingAddress,
                              );
                            } else {
                              // Direct Order (COD/BACS)
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
                                  'billing_address': billingAddress,
                                  'create_account': false,
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

                            // Handle Stripe payment result
                            if (_selectedCheckoutMethod ==
                                _CheckoutMethod.stripe) {
                              final stripeOrderCreated = _isOrderCreated(result);
                              final stripePaymentCompleted =
                                  _isPaymentCompleted(result);
                              if (result?['success'] == true &&
                                  stripeOrderCreated &&
                                  stripePaymentCompleted) {
                                final orderId = result?['order_id']?.toString();
                                final successText = orderId != null
                                    ? 'تم الدفع بنجاح! رقم الطلب: $orderId'
                                    : 'تم الدفع بنجاح!';
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(successText.tr),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                if (orderId != null && orderId.isNotEmpty) {
                                  await _storeSuccessfulOrder(
                                    orderId: orderId,
                                    status:
                                        result?['status']?.toString() ??
                                        'processing',
                                    paymentMethodTitle: 'Stripe',
                                    totalMajor: cartTotal,
                                    currencyCode:
                                        settingsProvider.currencyCode ?? 'USD',
                                  );
                                }
                                // Ensure cart is emptied after successful checkout.
                                await cartProvider.clearCart();
                                await cartProvider.refreshCart();
                              } else if (stripeOrderCreated &&
                                  !stripePaymentCompleted) {
                                final orderId = result?['order_id']?.toString();
                                final failedText = orderId != null
                                    ? 'الدفع لم يكتمل للطلب رقم: $orderId'
                                    : 'الدفع لم يكتمل، حاول مرة أخرى';
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(failedText.tr),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } else if (result?['cancelled'] == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('تم إلغاء عملية الدفع'.tr),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              } else {
                                final errorMsg = result?['message']?.toString() ??
                                    'فشل الدفع، حاول مرة أخرى';
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(errorMsg.tr),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } else {
                              // Handle PayPal/direct order result
                              final orderCreated = _isOrderCreated(result);
                              if (orderCreated) {
                                final orderId =
                                    result?['order_id']?.toString() ??
                                    result?['id']?.toString();
                                final successText = orderId != null
                                    ? 'تم إنشاء الطلب بنجاح! رقم الطلب: $orderId'
                                    : 'تم إنشاء الطلب بنجاح!';
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(successText.tr),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                if (orderId != null && orderId.isNotEmpty) {
                                  await _storeSuccessfulOrder(
                                    orderId: orderId,
                                    status:
                                        result?['status']?.toString() ??
                                        'pending',
                                    paymentMethodTitle:
                                        result?['payment_method_title']?.toString() ??
                                        (isPaypalFlow ? 'PayPal' : 'Direct'),
                                    totalMajor: cartTotal,
                                    currencyCode:
                                        settingsProvider.currencyCode ?? 'USD',
                                  );
                                }
                                // Ensure cart is emptied after successful checkout.
                                await cartProvider.clearCart();
                                await cartProvider.refreshCart();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(_extractOrderError(result)),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'فشل إتمام الطلب: ${_cleanErrorMessage(e)}',
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
                        ? ((isDirectFlow || isPaypalFlow)
                              ? 'جاري إنشاء الطلب...'.tr
                              : 'جاري الدفع وإنشاء الطلب...'.tr)
                        : ((isDirectFlow || isPaypalFlow)
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
