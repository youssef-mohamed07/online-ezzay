# خطة إصلاح الباك إند: Stripe + WooCommerce Checkout

## ملخص المشكلة

تطبيق الموبايل أصبح يرسل بيانات الدفع والـ checkout بشكل صحيح، ومع ذلك endpoint:

`wc/store/v1/checkout`

يرجع `400` وحالة الطلب `failed`.

### أدلة مؤكدة من التشغيل الفعلي (Runtime)

- إنشاء Stripe PaymentIntent ناجح (`httpStatus: 200`, `hasClientSecret: true`)
- صفحة الدفع (Stripe Payment Sheet) ناجحة (`piSdkStatus: Succeeded`)
- PaymentMethod موجود (`hasPm: true`)
- هيكل الـ checkout صحيح:
  - `billing_address` موجود
  - `payment_method` موجود
  - `payment_data` تحتوي:
    - `payment_method = pm_xxx`
    - `payment_intent_id = pi_xxx`
- رغم ذلك Woo Store API يفشل دائمًا بـ `httpStatus: 400` و `orderStatus: failed`

النتيجة: المشكلة غالبًا عدم توافق في الباك إند/الجيتواي، وليست مشكلة تنسيق payload من الموبايل.

---

## السبب الجذري (الأقرب)

Endpoint:

`/wp-json/wc/store/v1/checkout`

في إعداد Woo Stripe الحالي لا يقبل بسهولة PaymentIntent تم إنشاؤه/تأكيده خارجيًا من native app flow.

بمعنى:

- الموبايل ينفذ Stripe native payment بنجاح.
- Woo Stripe gateway يتوقع دورة حياة مختلفة داخل Woo نفسه.
- فتكون النتيجة `400 failed` عامة بدون error code واضح في رد Store API.

---

## الحل المقترح في الباك إند

بدل الاعتماد على `wc/store/v1/checkout` لإغلاق الدفع الخارجي، أنشئ endpoint مخصص في الباك إند لإتمام الطلب بعد نجاح الدفع.

### Endpoint جديد

`POST /wp-json/ezzy/v1/stripe/complete-order`

### ماذا يجب أن يفعل الباك إند

1. توثيق الطلب (JWT / App Auth).
2. التحقق من صحة payload.
3. جلب PaymentIntent من Stripe API باستخدام `payment_intent_id`.
4. التحقق من:
   - وجود الـ intent
   - حالة الدفع `succeeded` (أو حالة نجاح نهائية مقبولة)
   - تطابق amount/currency مع إجمالي الطلب/السلة
   - ملكية العميل أو السياق الصحيح (عند الحاجة)
5. إنشاء طلب WooCommerce من السيرفر بصلاحيات موثوقة.
6. إضافة العناصر، الإجماليات، billing/shipping من مصدر موثوق (cart/user context).
7. تعليم الطلب كمدفوع وربط transaction id = `payment_intent_id`.
8. إعادة رد موحّد للتطبيق (order id + status).

---

## عقد الطلب (Request Contract مقترح)

```json
{
  "payment_intent_id": "pi_xxx",
  "cart_token": "jwt-or-store-cart-token",
  "billing_address": {
    "first_name": "Ahmed",
    "last_name": "Ali",
    "email": "test@test.com",
    "phone": "01000000000",
    "address_1": "Street 1",
    "city": "Cairo",
    "country": "EG"
  }
}
```

## عقد الاستجابة (Response Contract مقترح)

```json
{
  "success": true,
  "order_id": 12345,
  "status": "processing",
  "payment_intent_id": "pi_xxx",
  "message": "Order completed successfully"
}
```

مثال استجابة خطأ:

```json
{
  "success": false,
  "code": "payment_not_succeeded",
  "message": "PaymentIntent status is not succeeded"
}
```

---

## متطلبات الأمان وسلامة البيانات

- عدم الثقة في إجماليات محسوبة من العميل.
- إعادة حساب إجمالي الطلب/السلة في الباك إند ومقارنته بقيمة Stripe intent.
- التأكد أن Stripe account المستخدم في إنشاء intent هو نفسه المعتمد لبيزنس Woo.
- التحقق الصارم من currency.
- جعل endpoint Idempotent بالاعتماد على `payment_intent_id`:
  - إذا الطلب موجود لنفس intent، يتم إرجاع الطلب الحالي بدل إنشاء طلب جديد.

---

## سلوك مؤقت للموبايل (لحين تنفيذ endpoint الجديد)

- الاستمرار في native Stripe payment flow.
- عند فشل `wc/store/v1/checkout`، إظهار رسالة واضحة:
  - الدفع نجح لكن تأكيد الطلب فشل
  - يحتاج تدخل دعم/باك إند
- عدم إنشاء أو تعديل Woo orders من العميل بمفاتيح read-only.

---

## لماذا هذه الخطة مناسبة

هذه الخطة تفصل المسؤوليات بشكل صحيح:

- تأكيد الدفع يتم في التطبيق (Stripe native).
- إنشاء/إغلاق الطلب يتم بشكل موثوق من الباك إند.
- حالة طلب Woo لا تُدار إلا من كود سيرفر موثوق.

وبذلك نتجنب فرضيات Store API gateway الحالية غير المتوافقة مع external native intent flow.
