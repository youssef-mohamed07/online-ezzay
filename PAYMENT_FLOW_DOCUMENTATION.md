# توثيق نظام الدفع في التطبيق
## Payment System Documentation

---

## 📋 نظرة عامة

يدعم التطبيق نظام دفع متكامل مع WooCommerce وStripe، يوفر للمستخدمين خيارات متعددة لإتمام عمليات الشراء بشكل آمن وسهل.

---

## 💳 طرق الدفع المتاحة

### 1. الدفع بالبطاقة عبر Stripe
- دفع إلكتروني آمن عبر بوابة Stripe
- يدعم جميع أنواع البطاقات الائتمانية والخصم
- معالجة آمنة للمدفوعات عبر صفحة Stripe المشفرة

### 2. الطلب المباشر
- إنشاء طلب بدون دفع إلكتروني فوري
- يدعم الدفع عند الاستلام (COD - Cash on Delivery)
- يدعم التحويل البنكي المباشر (BACS)

---

## 🔄 تدفق عملية الدفع

### المرحلة الأولى: التحضير

```
1. المستخدم يضيف المنتجات إلى السلة
2. يراجع محتويات السلة والإجمالي
3. يختار طريقة الدفع المفضلة
4. يضغط على زر "ادفع الآن" أو "تأكيد الطلب"
```

### المرحلة الثانية: جمع البيانات

عند الضغط على زر الدفع، يتم:

1. **جمع بيانات الفواتير** من ملف المستخدم:
   - الاسم الأول والأخير
   - البريد الإلكتروني
   - رقم الهاتف
   - العنوان الكامل (المدينة، الولاية، الرمز البريدي)
   - الدولة

2. **إعداد بيانات الطلب**:
   ```dart
   {
     'billing_address': {
       'first_name': 'محمد',
       'last_name': 'أحمد',
       'email': 'user@example.com',
       'phone': '0100000000',
       'address_1': 'شارع الجامعة',
       'city': 'Hebron',
       'state': 'Hebron',
       'postcode': '00000',
       'country': 'PS'
     },
     'payment_method': 'stripe', // أو 'cod' أو 'bacs'
     'create_account': false
   }
   ```

### المرحلة الثالثة: إنشاء الطلب

#### أ. للدفع عبر Stripe:

```
1. إرسال طلب إلى WooCommerce API مع payment_method = 'stripe'
   └─> POST /wp-json/wc/store/v1/checkout

2. استلام رد يحتوي على:
   - order_id: رقم الطلب
   - order_key: مفتاح الطلب
   - status: حالة الطلب (pending)

3. بناء رابط صفحة الدفع:
   https://demo.onlineezzy.com/checkout/order-pay/{order_id}/?pay_for_order=true&key={order_key}

4. فتح صفحة الدفع في متصفح مدمج (WebView)
   └─> StripeCheckoutWebViewPage

5. المستخدم يدخل بيانات البطاقة في صفحة Stripe الآمنة

6. Stripe يعالج الدفع ويحدث حالة الطلب في WooCommerce

7. عند نجاح الدفع، يتم توجيه المستخدم لصفحة "order-received"

8. التطبيق يكتشف التوجيه ويغلق WebView

9. التطبيق يتحقق من حالة الطلب النهائية:
   └─> GET /wp-json/wc/v3/orders/{order_id}

10. عرض رسالة نجاح أو فشل للمستخدم
```

#### ب. للطلب المباشر (COD/BACS):

```
1. إرسال طلب إلى WooCommerce API مع payment_method = 'cod' أو 'bacs'
   └─> POST /wp-json/wc/store/v1/checkout

2. استلام رد يحتوي على:
   - order_id: رقم الطلب
   - status: حالة الطلب (pending أو processing)

3. إذا نجح إنشاء الطلب:
   └─> عرض رسالة "تم إنشاء الطلب بنجاح! رقم الطلب: {order_id}"

4. لا يوجد دفع إلكتروني فوري
   └─> الطلب ينتظر الدفع عند الاستلام أو التحويل البنكي
```

---

## 🔧 الكود الرئيسي

### 1. دالة الدفع عبر WebView

في ملف `lib/views/screens/cart_page.dart`:

```dart
Future<Map<String, dynamic>?> _checkoutViaWebView(
  CartProvider cartProvider,
  Map<String, dynamic> baseCheckoutData,
  String paymentMethod,
) async {
  // إضافة طريقة الدفع للبيانات
  final checkoutData = {...baseCheckoutData, 'payment_method': paymentMethod};

  // محاولة إنشاء الطلب (مع معالجة مشكلة الدولة)
  final firstAttempt = await _checkoutWithCountryFallback(
    cartProvider,
    checkoutData,
    useAuth: false,
  );

  // إذا تم الدفع مباشرة، إرجاع النتيجة
  if (_isPaymentCompleted(firstAttempt)) {
    return firstAttempt;
  }

  // بناء رابط صفحة الدفع
  final payUrl = _buildOrderPayUrl(firstAttempt);
  if (payUrl == null || !mounted) {
    return firstAttempt;
  }

  // فتح صفحة الدفع في WebView
  final paid = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => StripeCheckoutWebViewPage(initialUrl: payUrl),
    ),
  );

  // إذا أكمل المستخدم الدفع
  if (paid == true) {
    final normalized = Map<String, dynamic>.from(firstAttempt ?? {});
    final orderId = normalized['order_id']?.toString() ?? 
                    normalized['id']?.toString();

    // جلب آخر حالة للطلب من المتجر
    if (orderId != null && orderId.isNotEmpty) {
      final latestOrder = await ApiService.getOrder(orderId);
      final latestStatus = latestOrder?['status']?.toString().toLowerCase() ?? '';
      
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
  }

  return firstAttempt;
}
```

### 2. دالة إنشاء الطلب في API Service

في ملف `lib/core/api_service.dart`:

```dart
static Future<Map<String, dynamic>> checkout(
  String cartToken,
  Map<String, dynamic> checkoutData, {
  bool useAuth = true,
}) async {
  final url = Uri.parse('$baseUrl/wc/store/v1/checkout');
  final headers = await _getHeaders(useAuth: useAuth, cartToken: cartToken);
  
  final response = await http.post(
    url,
    headers: headers,
    body: jsonEncode(checkoutData),
  );
  
  dynamic decoded;
  try {
    decoded = jsonDecode(response.body);
  } catch (_) {
    decoded = {'raw_body': response.body};
  }

  if (decoded is Map<String, dynamic>) {
    decoded['status_code'] = response.statusCode;
    return decoded;
  }

  return {'data': decoded, 'status_code': response.statusCode};
}
```

### 3. صفحة WebView للدفع

في ملف `lib/views/screens/stripe_checkout_webview_page.dart`:

```dart
class StripeCheckoutWebViewPage extends StatefulWidget {
  const StripeCheckoutWebViewPage({super.key, required this.initialUrl});
  final String initialUrl;

  @override
  State<StripeCheckoutWebViewPage> createState() =>
      _StripeCheckoutWebViewPageState();
}

class _StripeCheckoutWebViewPageState extends State<StripeCheckoutWebViewPage> {
  bool _isSuccessUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('/checkout/order-received/') ||
        lower.contains('order-received');
  }

  void _finish(bool paid) {
    if (_finished) return;
    _finished = true;
    if (mounted) {
      Navigator.of(context).pop(paid);
    }
  }

  // فتح صفحة الدفع في متصفح مدمج
  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.initialUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح صفحة الدفع')),
      );
    }
  }
}
```

---

## 🛡️ معالجة الأخطاء

### 1. فشل إنشاء الطلب

```dart
String _extractOrderError(Map<String, dynamic>? result) {
  if (result == null) return 'فشل إنشاء الطلب، حاول مرة أخرى';

  final message = result['message']?.toString();
  final code = result['code']?.toString();
  
  // معالجة خطأ البريد المسجل مسبقاً
  if (combined.contains('account is already registered') ||
      combined.contains('email') && combined.contains('registered')) {
    return 'هذا البريد مسجل بالفعل. سجل الدخول أولاً';
  }

  return message ?? code ?? 'فشل إنشاء الطلب';
}
```

### 2. رفض الدولة

```dart
Future<Map<String, dynamic>?> _checkoutWithCountryFallback(
  CartProvider cartProvider,
  Map<String, dynamic> checkoutData, {
  bool useAuth = true,
}) async {
  // محاولة أولى
  var attempt = await cartProvider.checkout(checkoutData, useAuth: useAuth);

  // إذا رفضت الدولة، إعادة المحاولة بدولة PS
  if (!_isOrderCreated(attempt) && _isCountryRejected(attempt)) {
    final currentBilling = Map<String, dynamic>.from(
      checkoutData['billing_address'] as Map<String, dynamic>,
    );
    
    currentBilling['country'] = 'PS';
    currentBilling['state'] = 'Hebron';

    final retryCheckout = {
      ...checkoutData,
      'billing_address': currentBilling,
    };
    
    attempt = await cartProvider.checkout(retryCheckout, useAuth: useAuth);
  }

  return attempt;
}
```

### 3. معالجة حالات الطلب

```dart
bool _isOrderCreated(Map<String, dynamic>? result) {
  if (result == null) return false;
  if (result['code'] != null || result['error'] != null) return false;

  final statusCode = result['status_code'] as int? ?? 0;
  if (statusCode >= 400) return false;

  final status = result['status']?.toString().toLowerCase() ?? '';
  if (status == 'failed' || status == 'cancelled') return false;

  final hasOrderId = result['id'] != null;
  return hasOrderId || 
         status == 'processing' || 
         status == 'completed' || 
         status == 'pending';
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
  }

  return false;
}
```

---

## ⚙️ إعدادات Stripe

### في ملف `lib/main.dart`:

```dart
import 'package:flutter_stripe/flutter_stripe.dart';

const String _defaultStripePublishableKey =
    'pk_test_51SC0wKRwqXYqDUmPxuBKGdQawJCymAgsTx8at0e9mC9MYJ22S54zPcWVJK3Nc4YIxLEwQtcTuO1NyAFzWDC5MoZf00VSKWbkS5';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // إعداد Stripe
  const configuredPk = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: _defaultStripePublishableKey,
  );

  Stripe.publishableKey = configuredPk;
  await Stripe.instance.applySettings();

  runApp(const MyApp());
}
```

### مفاتيح API في `lib/core/api_service.dart`:

```dart
class ApiService {
  static const String baseUrl = 'https://demo.onlineezzy.com/wp-json';
  static const String stripeBaseUrl = 'https://api.stripe.com/v1';

  // WooCommerce API Keys
  static const String consumerKey = 'ck_5ca575dad48fd87c2b7fae55a80096e14f90ff4f';
  static const String consumerSecret = 'cs_5d69ab19a7f8325b4d10e6a8687ed27ea5aa0768';

  // Stripe Secret Key (للاستخدام من Backend فقط)
  static const String stripeSecretKey = String.fromEnvironment(
    'STRIPE_SECRET_KEY',
    defaultValue: '',
  );
}
```

---

## 📊 حالات الطلب

### حالات WooCommerce المدعومة:

| الحالة | الوصف | نوع الرسالة |
|--------|-------|-------------|
| `pending` | في انتظار الدفع | معلق ⏳ |
| `processing` | قيد المعالجة (تم الدفع) | نجاح ✅ |
| `completed` | مكتمل | نجاح ✅ |
| `on-hold` | معلق | معلق ⏳ |
| `failed` | فشل | خطأ ❌ |
| `cancelled` | ملغي | خطأ ❌ |

### تتبع حالة الطلب بعد الدفع:

```dart
// جلب آخر حالة للطلب
final latestOrder = await ApiService.getOrder(orderId);
final latestStatus = latestOrder?['status']?.toString().toLowerCase() ?? '';

// تحديد نوع الرسالة
if (latestStatus == 'processing' || latestStatus == 'completed') {
  // عرض رسالة نجاح
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('تم الدفع بنجاح! رقم الطلب: $orderId'),
      backgroundColor: Colors.green,
    ),
  );
} else if (latestStatus == 'pending' || latestStatus == 'on-hold') {
  // عرض رسالة معلقة
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('الطلب قيد المراجعة. رقم الطلب: $orderId'),
      backgroundColor: Colors.orange,
    ),
  );
} else {
  // عرض رسالة خطأ
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('فشل الدفع. حاول مرة أخرى'),
      backgroundColor: Colors.red,
    ),
  );
}
```

---

## 🔐 الأمان

### 1. معالجة بيانات البطاقة
- **لا يتم تخزين** بيانات البطاقة في التطبيق أبداً
- جميع بيانات الدفع تُعالج عبر **Stripe** مباشرة
- الاتصال مشفر بـ **HTTPS/TLS**

### 2. المصادقة
```dart
static Future<Map<String, String>> _getHeaders({
  bool useAuth = false,
  String? cartToken,
}) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('auth_token');

  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  if (useAuth && token != null) {
    headers['Authorization'] = 'Bearer $token';
  }

  if (cartToken != null) {
    headers['Cart-Token'] = cartToken;
  }

  return headers;
}
```

### 3. Cart Token
- كل سلة لها **Cart-Token** فريد
- يُستخدم لربط العناصر بالمستخدم
- يُحفظ محلياً ويُرسل مع كل طلب

---

## 🧪 اختبار النظام

### بطاقات اختبار Stripe:

| رقم البطاقة | النتيجة |
|-------------|---------|
| `4242 4242 4242 4242` | نجاح ✅ |
| `4000 0000 0000 0002` | فشل ❌ |
| `4000 0025 0000 3155` | يتطلب مصادقة 3D Secure |

**ملاحظة:** استخدم أي تاريخ انتهاء مستقبلي وأي CVV مكون من 3 أرقام.

### سيناريوهات الاختبار:

1. **دفع ناجح عبر Stripe**
   - إضافة منتج للسلة
   - اختيار "الدفع بالبطاقة"
   - استخدام بطاقة اختبار ناجحة
   - التحقق من رسالة النجاح

2. **طلب مباشر COD**
   - إضافة منتج للسلة
   - اختيار "طلب مباشر"
   - التحقق من إنشاء الطلب

3. **معالجة الأخطاء**
   - محاولة الدفع ببطاقة فاشلة
   - التحقق من رسالة الخطأ المناسبة

---

## 📱 واجهة المستخدم

### عناصر صفحة السلة:

1. **قائمة المنتجات**
   - صورة المنتج
   - اسم المنتج
   - الكمية × السعر
   - زر الحذف

2. **اختيار طريقة الدفع**
   - راديو بتن للاختيار
   - أيقونة مميزة لكل طريقة
   - نص توضيحي

3. **ملخص الطلب**
   - الإجمالي النهائي
   - العملة

4. **زر الدفع**
   - نص ديناميكي حسب الطريقة
   - حالة تحميل أثناء المعالجة
   - معطل عند السلة الفارغة

---

## 🔄 تحديثات مستقبلية محتملة

- [ ] إضافة Apple Pay / Google Pay
- [ ] دعم المحافظ الإلكترونية
- [ ] حفظ بطاقات الدفع للاستخدام المستقبلي
- [ ] دعم الأقساط
- [ ] كوبونات الخصم
- [ ] نقاط الولاء

---

## 📞 الدعم الفني

في حالة وجود مشاكل في نظام الدفع:

1. التحقق من اتصال الإنترنت
2. التأكد من صحة مفاتيح API
3. مراجعة سجلات الأخطاء (logs)
4. التواصل مع فريق الدعم

---

**آخر تحديث:** 2026-04-26
**الإصدار:** 1.0.0
