# إصلاح مشكلة عدم ظهور الشحنات

## المشكلة
الشحنات لا تظهر في التطبيق عند فتح صفحة الشحنات.

## التشخيص
بعد فحص الكود والـ API، تبين أن:

1. **الـ API يتطلب مصادقة (Authentication)**
   - Endpoint: `https://demo.onlineezzy.com/wp-json/ezzy/v1/shipments`
   - يتطلب JWT token (Bearer authentication)
   - يرجع خطأ 401 عند عدم وجود token صالح

2. **الكود السابق لم يتعامل مع حالة عدم المصادقة**
   - كان يعرض "لا توجد شحنات" حتى لو كان المستخدم غير مسجل دخول
   - لم يكن هناك رسالة واضحة للمستخدم

## الحل المطبق

### 1. تحديث `ShipmentProvider` (lib/providers/shipment_provider.dart)
- إضافة متغير `_requiresAuth` لتتبع حالة المصادقة
- إضافة متغير `_error` لتخزين رسائل الخطأ
- تحديث `loadShipments()` للتعامل مع خطأ 401/403

```dart
bool _requiresAuth = false;
bool get requiresAuth => _requiresAuth;

String? _error;
String? get error => _error;
```

### 2. تحديث `ApiService.getShipments()` (lib/core/api_service.dart)
- إرجاع معلومات الخطأ عند فشل المصادقة
- السماح للـ provider بمعرفة سبب الفشل

```dart
// Return error info if authentication failed
if (response.statusCode == 401 || response.statusCode == 403) {
  final decoded = _safeDecodeBody(response.body);
  if (decoded is Map<String, dynamic>) {
    return decoded;
  }
}
```

### 3. تحديث واجهة المستخدم (lib/views/screens/shipments_page.dart)
- إضافة شاشة خاصة عند الحاجة لتسجيل الدخول
- عرض أيقونة قفل ورسالة واضحة
- زر لتسجيل الدخول ينقل المستخدم لصفحة Login

```dart
shipmentProvider.requiresAuth
  ? Center(
      child: Column(
        children: [
          Icon(Icons.lock_outline, size: 64),
          Text('يجب تسجيل الدخول'),
          Text('قم بتسجيل الدخول لعرض شحناتك'),
          ElevatedButton(
            onPressed: () => Navigator.push(...),
            child: Text('تسجيل الدخول'),
          ),
        ],
      ),
    )
```

### 4. إضافة الترجمات (lib/core/app_translations.dart)
```dart
'يجب تسجيل الدخول': 'You must log in',
'قم بتسجيل الدخول لعرض شحناتك': 'Log in to view your shipments',
```

## النتيجة
الآن عند فتح صفحة الشحنات:

1. **إذا كان المستخدم مسجل دخول**: تظهر الشحنات بشكل طبيعي
2. **إذا لم يكن مسجل دخول**: تظهر رسالة واضحة مع زر لتسجيل الدخول
3. **تجربة مستخدم أفضل**: المستخدم يعرف بالضبط ما يجب فعله

## الملفات المعدلة
- `lib/providers/shipment_provider.dart`
- `lib/core/api_service.dart`
- `lib/views/screens/shipments_page.dart`
- `lib/core/app_translations.dart`

## اختبار الحل
1. افتح التطبيق بدون تسجيل دخول
2. اذهب لصفحة الشحنات
3. يجب أن تظهر رسالة "يجب تسجيل الدخول"
4. اضغط على زر "تسجيل الدخول"
5. سجل دخول بحساب صحيح
6. ارجع لصفحة الشحنات
7. يجب أن تظهر الشحنات (إذا كانت موجودة)
