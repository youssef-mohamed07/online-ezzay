# تقرير مشكلة Stripe — تفاصيل كاملة للباك إيند
**التاريخ:** 26 أبريل 2026  
**المشروع:** Online Ezzy — Flutter App  
**الأولوية:** 🔴 حرجة (Security Issue)

---

## 1. ملخص المشكلة

التطبيق يعرض الخطأ التالي عند محاولة الدفع بالبطاقة:

```
Exception: خطأ في إنشاء نية الدفع: Exception: Stripe secret key is not configured
```

**السبب الجذري:** التطبيق مصمم حالياً ليتصل بـ Stripe API مباشرة من الموبايل باستخدام `sk_secret_key`، وهذا المفتاح غير موجود في بيئة الإنتاج — وهو أمر **صحيح أن يكون غير موجود** لأن وضعه في التطبيق خطر أمني بالغ.

---

## 2. تشخيص المشكلة — خطوة بخطوة

### 2.1 مسار الكود الحالي (المعطوب)

```
المستخدم يضغط "ادفع الآن"
        │
        ▼
cart_page.dart → _checkoutNativeStripe()
        │
        ▼
payment_service.dart → processNativeStripePayment()
        │
        ▼
payment_service.dart → createPaymentIntent()
        │
        ▼
api_service.dart → createStripePaymentIntent()
        │
        ▼
  if (stripeSecretKey.isEmpty) {
    return {'error': 'Stripe secret key is not configured'}  ← 💥 هنا المشكلة
  }
        │
        ▼
payment_service.dart يرمي Exception
        │
        ▼
cart_page.dart يعرض الخطأ للمستخدم
```

### 2.2 الكود المسبب للمشكلة

**ملف:** `lib/core/api_service.dart` — السطر 28

```dart
// المفتاح يُقرأ من --dart-define فقط، وبدونه يكون فارغاً
static const String stripeSecretKey = String.fromEnvironment(
  'STRIPE_SECRET_KEY',
  defaultValue: '',   // ← فارغ دائماً في الإنتاج
);
```

**ملف:** `lib/core/api_service.dart` — دالة `createStripePaymentIntent()`

```dart
static Future<Map<String, dynamic>> createStripePaymentIntent({
  required double amount,
  required String currency,
}) async {
  // هذا الشرط يمنع الاتصال بـ Stripe لأن المفتاح فارغ
  if (stripeSecretKey.trim().isEmpty || stripeSecretKey.contains('REMOVED')) {
    return {
      'error': 'Stripe secret key is not configured',  // ← الخطأ الظاهر
      'status_code': 500,
    };
  }
  // ... باقي الكود لا يُنفَّذ أبداً
}
```

---

## 3. لماذا هذا التصميم خاطئ أمنياً؟

| المشكلة | التفاصيل |
|---------|----------|
| **Secret Key في التطبيق** | أي شخص يفك ضغط الـ APK/IPA يقدر يستخرج المفتاح |
| **صلاحيات خطيرة** | `sk_secret_key` يقدر يسحب أموال، يسترد مدفوعات، يرى بيانات العملاء |
| **مخالفة Stripe ToS** | Stripe تمنع صراحةً استخدام الـ secret key في client-side code |
| **لا يمكن إلغاؤه بسهولة** | لو تسرب المفتاح، كل إصدارات التطبيق القديمة تظل خطرة |

---

## 4. الحل المطلوب من الباك إيند

### 4.1 المطلوب: Endpoint واحد جديد

```
POST /wp-json/ezzy/v1/stripe/create-payment-intent
```

**الوصف:** السيرفر يستقبل المبلغ والعملة، يتصل بـ Stripe بالـ secret key المحفوظ عنده بأمان، ويرجع الـ `client_secret` فقط للتطبيق.

---

### 4.2 تفاصيل الـ Request

**Headers:**
```http
POST /wp-json/ezzy/v1/stripe/create-payment-intent HTTP/1.1
Host: demo.onlineezzy.com
Content-Type: application/json
Authorization: Bearer {jwt_token}
```

**Body:**
```json
{
  "amount": 150.00,
  "currency": "usd"
}
```

| الحقل | النوع | الوصف |
|-------|-------|-------|
| `amount` | `float` | المبلغ بالوحدة الرئيسية (مثلاً 150.00 دولار) |
| `currency` | `string` | كود العملة بحروف صغيرة (usd, eur, ...) |

---

### 4.3 تفاصيل الـ Response — نجاح

**HTTP Status:** `200 OK`

```json
{
  "client_secret": "pi_3RExample_secret_AbCdEfGhIj",
  "payment_intent_id": "pi_3RExample1234567890"
}
```

| الحقل | النوع | الوصف |
|-------|-------|-------|
| `client_secret` | `string` | يُرسل للتطبيق لإتمام الدفع عبر Stripe SDK |
| `payment_intent_id` | `string` | يُستخدم لاحقاً لتأكيد الطلب في WooCommerce |

---

### 4.4 تفاصيل الـ Response — خطأ

**HTTP Status:** `400` أو `500`

```json
{
  "error": "وصف الخطأ",
  "code": "stripe_error_code"
}
```

---

### 4.5 كيف يعمل السيرفر داخلياً (PHP / WordPress)

```php
// مثال على التنفيذ في WordPress
add_action('rest_api_init', function() {
    register_rest_route('ezzy/v1', '/stripe/create-payment-intent', [
        'methods'  => 'POST',
        'callback' => 'ezzy_create_payment_intent',
        'permission_callback' => function() {
            return is_user_logged_in(); // أو التحقق من JWT
        },
    ]);
});

function ezzy_create_payment_intent(WP_REST_Request $request) {
    $amount   = floatval($request->get_param('amount'));
    $currency = sanitize_text_field($request->get_param('currency'));

    // المفتاح محفوظ بأمان في إعدادات WordPress
    $secret_key = get_option('ezzy_stripe_secret_key'); // أو من wp-config.php

    // تحويل المبلغ لأصغر وحدة (سنت)
    $amount_cents = intval($amount * 100);

    // الاتصال بـ Stripe API
    $response = wp_remote_post('https://api.stripe.com/v1/payment_intents', [
        'headers' => [
            'Authorization' => 'Bearer ' . $secret_key,
            'Content-Type'  => 'application/x-www-form-urlencoded',
        ],
        'body' => [
            'amount'                                  => $amount_cents,
            'currency'                                => strtolower($currency),
            'automatic_payment_methods[enabled]'      => 'true',
            'automatic_payment_methods[allow_redirects]' => 'never',
        ],
    ]);

    if (is_wp_error($response)) {
        return new WP_Error('stripe_error', $response->get_error_message(), ['status' => 500]);
    }

    $body = json_decode(wp_remote_retrieve_body($response), true);

    if (isset($body['error'])) {
        return new WP_Error('stripe_error', $body['error']['message'], ['status' => 400]);
    }

    return rest_ensure_response([
        'client_secret'      => $body['client_secret'],
        'payment_intent_id'  => $body['id'],
    ]);
}
```

---

## 5. المسار الكامل بعد الإصلاح

```
المستخدم يضغط "ادفع الآن"
        │
        ▼
Flutter App
POST /wp-json/ezzy/v1/stripe/create-payment-intent
{ amount: 150.00, currency: "usd" }
        │
        ▼
WordPress Backend
← يتصل بـ Stripe بالـ sk_secret_key المحفوظ عنده
← يستقبل payment_intent من Stripe
← يرجع client_secret فقط للتطبيق
        │
        ▼
Flutter App
← يستخدم client_secret مع Stripe SDK (flutter_stripe)
← يعرض Payment Sheet للمستخدم
← المستخدم يدخل بيانات البطاقة
        │
        ▼
Stripe يعالج الدفع مباشرة مع التطبيق (بأمان)
        │
        ▼
Flutter App
POST /wp-json/wc/store/v1/checkout
{ payment_method: "stripe", payment_data: [{ key: "payment_method", value: payment_intent_id }] }
        │
        ▼
WooCommerce ينشئ الطلب ✅
```

---

## 6. التغييرات في التطبيق بعد الـ Endpoint

بعد ما الباك إيند يعمل الـ endpoint، التعديل في التطبيق بسيط جداً — ملف واحد، دالة واحدة:

**ملف:** `lib/core/api_service.dart`

```dart
// قبل: كان يتصل بـ Stripe مباشرة
static Future<Map<String, dynamic>> createStripePaymentIntent({
  required double amount,
  required String currency,
}) async {
  if (stripeSecretKey.trim().isEmpty) {
    return {'error': 'Stripe secret key is not configured'};
  }
  // اتصال مباشر بـ https://api.stripe.com ← خطأ
  ...
}

// بعد: يتصل بالباك إيند
static Future<Map<String, dynamic>> createStripePaymentIntent({
  required double amount,
  required String currency,
}) async {
  final url = Uri.parse('$baseUrl/ezzy/v1/stripe/create-payment-intent');
  final headers = await _getHeaders(useAuth: true);
  final response = await http.post(
    url,
    headers: headers,
    body: jsonEncode({'amount': amount, 'currency': currency}),
  );
  final decoded = _safeDecodeBody(response.body);
  if (decoded is Map<String, dynamic>) {
    decoded['status_code'] = response.statusCode;
    return decoded;
  }
  return {'error': 'Invalid response', 'status_code': response.statusCode};
}
```

باقي الكود في `payment_service.dart` و `cart_page.dart` **لا يحتاج أي تعديل**.

---

## 7. ملخص ما هو مطلوب من الباك إيند

| # | المطلوب | الأولوية |
|---|---------|----------|
| 1 | إضافة endpoint `POST /wp-json/ezzy/v1/stripe/create-payment-intent` | 🔴 حرج |
| 2 | حفظ `STRIPE_SECRET_KEY` في إعدادات WordPress أو `wp-config.php` | 🔴 حرج |
| 3 | التحقق من JWT token في الـ endpoint | 🟡 مهم |
| 4 | إرجاع `client_secret` و `payment_intent_id` في الـ response | 🔴 حرج |

---

## 8. بيانات الاختبار

بعد تجهيز الـ endpoint، اختبر بهذه البطاقات:

| رقم البطاقة | النتيجة المتوقعة |
|-------------|-----------------|
| `4242 4242 4242 4242` | ✅ دفع ناجح |
| `4000 0000 0000 0002` | ❌ رفض البطاقة |
| `4000 0025 0000 3155` | 🔐 يتطلب 3D Secure |

> تاريخ انتهاء: أي تاريخ مستقبلي — CVV: أي 3 أرقام — ZIP: أي 5 أرقام

---

**للتواصل:** بعد تجهيز الـ endpoint، أبلغنا وسيتم تحديث التطبيق فوراً.
