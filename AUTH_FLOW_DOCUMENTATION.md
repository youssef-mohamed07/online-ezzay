# Authentication Flow - توثيق نظام المصادقة

## 📋 نظرة عامة

التطبيق يستخدم JWT (JSON Web Token) للمصادقة مع WooCommerce REST API.

---

## 🔄 Flow الكامل (محدث)

### 1️⃣ **Splash Screen** (`splash_page.dart`)
```
عند فتح التطبيق
    ↓
يعرض شاشة Splash لمدة 2.3 ثانية
    ↓
يتحقق من:
  1. وجود token في SharedPreferences
  2. هل شاهد الـ Onboarding من قبل
    ↓
    ├─ إذا يوجد token → ينتقل إلى ShellPage (مستخدم مسجل)
    ├─ إذا شاهد Onboarding من قبل → ينتقل إلى ShellPage (ضيف)
    └─ أول مرة → ينتقل إلى OnboardingPage
```

**الكود:**
```dart
final prefs = await SharedPreferences.getInstance();
final hasToken = prefs.getString('auth_token') != null;
final hasSeenOnboarding = prefs.getBool('onboarding_completed') ?? false;

Widget nextPage;
if (hasToken) {
  nextPage = const ShellPage(); // مستخدم مسجل
} else if (hasSeenOnboarding) {
  nextPage = const ShellPage(); // ضيف
} else {
  nextPage = const OnboardingPage(); // أول مرة
}
```

---

### 2️⃣ **Onboarding** (`onboarding_page.dart`) - محدث ⭐
```
شاشة تعريفية بالتطبيق (3 شرائح)
    ↓
المستخدم يضغط:
  - "تخطي" (في أي وقت)
  - "التالي" (للانتقال للشريحة التالية)
  - "ابدأ الآن" (في الشريحة الأخيرة)
    ↓
يحفظ onboarding_completed = true
    ↓
ينتقل مباشرة إلى ShellPage كضيف ✅
```

**التغيير الرئيسي:**
- ❌ **قبل:** كان يذهب إلى LoginPage
- ✅ **بعد:** يذهب مباشرة إلى ShellPage كضيف

**الكود:**
```dart
void _goHome() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboarding_completed', true);
  
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => const ShellPage()),
  );
}
```

---

### 3️⃣ **Login Page** (`login_page.dart`)

#### الخيارات المتاحة:
1. **تسجيل الدخول** - للمستخدمين المسجلين
2. **تخطي والدخول كضيف** - الدخول بدون حساب
3. **نسيت كلمة المرور** - استعادة كلمة المرور

#### Flow تسجيل الدخول:
```
المستخدم يدخل:
  - البريد الإلكتروني / رقم الهاتف
  - كلمة المرور
    ↓
يضغط "تسجيل الدخول"
    ↓
AuthProvider.login() يتم استدعاؤه
    ↓
ApiService.login() يرسل طلب إلى:
  POST /wp-json/jwt-auth/v1/token
    ↓
    ├─ نجح ✅
    │   ↓
    │   يحفظ token في SharedPreferences
    │   يحفظ user_data في SharedPreferences
    │   يجلب تفاصيل العميل من WooCommerce
    │   ينتقل إلى ShellPage
    │
    └─ فشل ❌
        ↓
        يعرض رسالة خطأ
```

**الكود الرئيسي:**
```dart
// في AuthProvider
Future<bool> login(String username, String password) async {
  final response = await ApiService.login(username, password);
  
  if (response['status_code'] == 200 && response.containsKey('token')) {
    _token = response['token'];
    _userData = response;
    
    // حفظ في SharedPreferences
    await prefs.setString('auth_token', _token!);
    await prefs.setString('user_data', jsonEncode(_userData));
    
    // جلب تفاصيل العميل
    final userId = _extractUserId(_userData);
    if (userId != null) {
      await fetchCustomerDetails(userId);
    }
    
    return true;
  }
  return false;
}
```

---

### 4️⃣ **Register Page** (`register_page.dart`)

#### Flow التسجيل:
```
المستخدم يدخل:
  - الاسم الكامل
  - البريد الإلكتروني
  - رقم الهاتف
  - العنوان
  - المدينة
  - كلمة المرور
    ↓
يضغط "إنشاء الحساب"
    ↓
AuthProvider.register() يتم استدعاؤه
    ↓
ApiService.register() يرسل طلب إلى:
  POST /wp-json/custom-api/v1/register
    ↓
    ├─ نجح ✅
    │   ↓
    │   يعرض رسالة نجاح
    │   ينتقل إلى LoginPage
    │   المستخدم يسجل دخول بالبيانات الجديدة
    │
    └─ فشل ❌
        ↓
        يعرض رسالة خطأ
```

**الكود الرئيسي:**
```dart
// في AuthProvider
Future<bool> register(String username, String email, String password) async {
  final response = await ApiService.register(username, email, password);
  
  if (response['status_code'] == 200 || response['status_code'] == 201) {
    return true;
  }
  
  _lastError = response['message'] ?? 'حدث خطأ';
  return false;
}
```

---

### 5️⃣ **Guest Mode - الدخول كضيف** ⭐ محدث

```
المستخدم الجديد:
    ↓
يشاهد Onboarding
    ↓
يضغط "ابدأ الآن" أو "تخطي"
    ↓
يدخل مباشرة إلى ShellPage كضيف ✅
    ↓
يمكنه:
  - تصفح المنتجات
  - إضافة للسلة
  - تتبع الشحنات
  - استخدام جميع الميزات
    ↓
عند الحاجة لتسجيل الدخول:
  - يذهب إلى Profile Page
  - يضغط "تسجيل الدخول"
  - يسجل دخول أو ينشئ حساب
```

**مميزات Guest Mode:**
- ✅ دخول فوري بدون تسجيل
- ✅ استخدام كامل للتطبيق
- ✅ يمكن التسجيل لاحقاً
- ✅ زر "تسجيل الدخول" في Profile Page

**الكود في Profile Page:**
```dart
Consumer<AuthProvider>(
  builder: (context, auth, _) {
    if (auth.isAuthenticated) {
      return TextButton(
        onPressed: () => auth.logout(),
        child: Text('تسجيل الخروج'),
      );
    } else {
      return TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
        ),
        child: Text('تسجيل الدخول'),
      );
    }
  },
)
```

---

## 🔐 API Endpoints

### 1. Login (تسجيل الدخول)
```
POST /wp-json/jwt-auth/v1/token

Body:
{
  "username": "user@example.com",
  "password": "password123"
}

Response (Success):
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user_email": "user@example.com",
  "user_nicename": "user",
  "user_display_name": "User Name",
  "id": "123"
}
```

### 2. Register (إنشاء حساب)
```
POST /wp-json/custom-api/v1/register

Body:
{
  "username": "newuser",
  "email": "user@example.com",
  "password": "password123"
}

Response (Success):
{
  "status_code": 200,
  "message": "User created successfully"
}
```

### 3. Get Customer Details (جلب تفاصيل العميل)
```
GET /wp-json/wc/v3/customers/{id}

Headers:
Authorization: Basic {base64(consumer_key:consumer_secret)}

Response:
{
  "id": 123,
  "email": "user@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "billing": {...},
  "shipping": {...}
}
```

---

## 💾 Data Storage (التخزين المحلي)

### SharedPreferences Keys:
```dart
'auth_token'              // JWT token
'user_data'               // JSON string of user data
'onboarding_completed'    // bool - هل شاهد الـ Onboarding
```

### User Data Structure:
```json
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user_email": "user@example.com",
  "user_nicename": "user",
  "user_display_name": "User Name",
  "id": "123",
  "first_name": "John",
  "last_name": "Doe",
  "billing": {
    "first_name": "John",
    "last_name": "Doe",
    "email": "user@example.com",
    "phone": "+966501234567"
  }
}
```

---

## 🎯 AuthProvider State Management

### Properties:
```dart
bool isLoading          // حالة التحميل
String? token           // JWT token
bool isAuthenticated    // هل المستخدم مسجل دخول
Map<String, dynamic>? userData  // بيانات المستخدم
String displayName      // اسم العرض
String primaryEmail     // البريد الإلكتروني
String? lastError       // آخر خطأ حدث
```

### Methods:
```dart
login(username, password)           // تسجيل الدخول
register(username, email, password) // إنشاء حساب
logout()                            // تسجيل الخروج
fetchCustomerDetails(id)            // جلب تفاصيل العميل
updateCustomerDetails(id, data)     // تحديث بيانات العميل
```

---

## 🔄 Session Management

### عند فتح التطبيق:
```dart
// في AuthProvider constructor
AuthProvider() {
  _loadToken();  // يحمل token من SharedPreferences
}

Future<void> _loadToken() async {
  final prefs = await SharedPreferences.getInstance();
  _token = prefs.getString('auth_token');
  
  // تحميل بيانات المستخدم
  final userStr = prefs.getString('user_data');
  if (userStr != null) {
    _userData = jsonDecode(userStr);
  }
  
  // جلب تفاصيل محدثة من السيرفر
  if (isAuthenticated && userId != null) {
    await fetchCustomerDetails(userId);
  }
}
```

### تسجيل الخروج:
```dart
Future<void> logout() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('auth_token');
  await prefs.remove('user_data');
  _token = null;
  _userData = null;
  notifyListeners();
}
```

---

## 🛡️ Security Features

1. **JWT Token**: يُستخدم لتأمين الطلبات
2. **HTTPS**: جميع الطلبات عبر HTTPS
3. **Password Validation**: كلمة المرور يجب أن تكون 8 أحرف على الأقل
4. **Token Storage**: يُحفظ في SharedPreferences (آمن على الجهاز)
5. **Auto Logout**: عند انتهاء صلاحية الـ token

---

## 📱 UI/UX Flow

### Login Page Features:
- ✅ حقول إدخال مع validation
- ✅ مؤشر تحميل أثناء الطلب
- ✅ رسائل خطأ واضحة
- ✅ خيار "نسيت كلمة المرور"
- ✅ خيار "الدخول كضيف"
- ✅ تصميم responsive

### Register Page Features:
- ✅ حقول متعددة (اسم، بريد، هاتف، عنوان)
- ✅ Password strength indicator
- ✅ مؤشر تحميل
- ✅ رسائل نجاح/فشل
- ✅ رابط للانتقال إلى Login

---

## 🔧 Error Handling

### أنواع الأخطاء:
```dart
// خطأ في الشبكة
'خطأ في الاتصال بالشبكة'

// بيانات خاطئة
'فشل تسجيل الدخول، تأكد من بياناتك'

// حقول فارغة
'الرجاء إدخال البريد الإلكتروني وكلمة المرور'

// خطأ من السيرفر
response['message'] // الرسالة من API
```

---

## 🎨 Design Patterns Used

1. **Provider Pattern**: لإدارة الحالة
2. **Repository Pattern**: ApiService يفصل logic عن UI
3. **Singleton**: SharedPreferences
4. **Observer Pattern**: notifyListeners() في Provider

---

## 📝 ملاحظات مهمة

1. **Guest Mode الجديد**: المستخدم يدخل مباشرة كضيف بعد Onboarding ⭐
2. **تسجيل الدخول اختياري**: يمكن التسجيل في أي وقت من Profile Page
3. **Auto Login**: إذا يوجد token صالح، يدخل تلقائياً
4. **Onboarding مرة واحدة**: يُعرض فقط في أول مرة
5. **Token Refresh**: لا يوجد حالياً، يحتاج تسجيل دخول جديد عند انتهاء الصلاحية
6. **Multi-device**: كل جهاز له session منفصل
7. **Logout**: يحذف البيانات المحلية ويبقى كضيف

---

## 🚀 Future Improvements

- [ ] إضافة Token Refresh
- [ ] إضافة Biometric Authentication (بصمة/وجه)
- [ ] إضافة Social Login (Google, Apple)
- [ ] إضافة Two-Factor Authentication
- [ ] تحسين Error Messages
- [ ] إضافة Remember Me option
