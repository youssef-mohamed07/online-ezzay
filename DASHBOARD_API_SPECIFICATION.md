# 📊 مواصفات Dashboard API - الوثيقة الكاملة

## 🔗 معلومات الـ Endpoint

**URL:** `GET https://demo.onlineezzy.com/wp-json/ezzy/v1/dashboard`  
**Authentication:** Basic Auth (Consumer Key & Secret)  
**Response Type:** JSON

---

## 📦 البيانات المطلوبة من الباك إند

### 1️⃣ المؤشرات الرئيسية (إحصائيات الشحنات)

#### أ) إجمالي الشحنات
**الحقول المقبولة:**
- `total_shipments` ⭐ (مفضل)
- `shipments_count`
- `shipments.total`
- `total_count`
- `shipments_total`
- `all_shipments`

**المعنى:** العدد الكلي لجميع الشحنات (نشطة + مسلّمة + ملغاة)

**مثال:**
```json
{
  "total_shipments": 221
}
```

---

#### ب) الشحنات النشطة
**الحقول المقبولة:**
- `active_shipments` ⭐ (مفضل)
- `active_count`
- `shipments.active`
- `in_transit`
- `in_transit_count`

**المعنى:** الشحنات التي لم يتم تسليمها بعد (في الصندوق، في الطريق، قيد المعالجة)

**مثال:**
```json
{
  "active_shipments": 127
}
```

---

#### ج) الشحنات المسلّمة
**الحقول المقبولة:**
- `delivered_shipments` ⭐ (مفضل)
- `delivered_count`
- `shipments.delivered`
- `completed_shipments`
- `completed_count`

**المعنى:** الشحنات التي تم تسليمها بنجاح للعميل

**مثال:**
```json
{
  "delivered_shipments": 94
}
```

---

#### د) الطرود في الصندوق/المستودع
**الحقول المقبولة:**
- `warehouse_parcels_count` ⭐ (مفضل)
- `warehouse_count`
- `warehouse.parcels_count`
- `box_parcels_count`
- `parcels_in_box`
- `parcels_box`

**المعنى:** عدد الطرود الموجودة حالياً في المستودع/الصندوق ولم يتم شحنها بعد

**مثال:**
```json
{
  "warehouse_parcels_count": 15
}
```

---

### 2️⃣ الشحنات الأخيرة (Recent Shipments)

**الحقول المقبولة:**
- `recent_shipments` ⭐ (مفضل)
- `latest_shipments`
- `shipments_recent`
- `recent`
- `last_shipments`
- `shipments.latest`

**المعنى:** قائمة بآخر الشحنات (يُفضل 5-10 شحنات)

**الشكل المطلوب:**
```json
{
  "recent_shipments": [
    {
      "tracking_number": "y002",
      "status": "في الصندوق",
      "current_status": "في الصندوق",
      "date": "2026-04-13",
      "date_added": "2026-04-13 19:57:08"
    },
    {
      "tracking_number": "y001",
      "status": "في الطريق",
      "current_status": "في الطريق",
      "date": "2026-04-13"
    }
  ]
}
```

**الحقول المطلوبة في كل شحنة:**
- `tracking_number` أو `number` أو `id` - رقم التتبع
- `status` أو `current_status` أو `shipment_status` - الحالة
- `date` أو `date_added` أو `created_at` - التاريخ

---

### 3️⃣ مؤشرات إضافية (اختيارية)

يمكن إضافة أي مؤشرات رقمية إضافية، وستظهر تلقائياً في قسم "مؤشرات إضافية من الخادم"

#### أمثلة مقترحة:

```json
{
  "pending_shipments": 10,
  "cancelled_shipments": 3,
  "returned_shipments": 2,
  "delayed_shipments": 5,
  "total_revenue": 150000,
  "monthly_revenue": 45000,
  "total_customers": 350,
  "new_customers_this_month": 25
}
```

**الأسماء العربية المقترحة:**
- `pending_shipments` → "شحنات قيد الانتظار"
- `cancelled_shipments` → "شحنات ملغاة"
- `returned_shipments` → "شحنات مرتجعة"
- `delayed_shipments` → "شحنات متأخرة"
- `total_revenue` → "إجمالي الإيرادات"
- `monthly_revenue` → "إيرادات الشهر"
- `total_customers` → "إجمالي العملاء"
- `new_customers_this_month` → "عملاء جدد هذا الشهر"

---

### 4️⃣ بيانات نصية (اختيارية)

أي بيانات نصية ستظهر في قسم "بيانات نصية وتفاصيل من الخادم" (قابل للطي)

**أمثلة:**
```json
{
  "company_name": "أونلاين إيزي",
  "last_update": "2026-04-13 20:30:00",
  "system_status": "نشط",
  "maintenance_mode": false,
  "announcement": "خصم 20% على جميع الشحنات هذا الأسبوع"
}
```

---

## 📋 أمثلة كاملة للـ Response

### مثال 1: Response بسيط (مفضل)

```json
{
  "total_shipments": 221,
  "active_shipments": 127,
  "delivered_shipments": 94,
  "warehouse_parcels_count": 15,
  "recent_shipments": [
    {
      "tracking_number": "y002",
      "status": "في الصندوق",
      "date": "2026-04-13"
    },
    {
      "tracking_number": "y001",
      "status": "في الطريق",
      "date": "2026-04-13"
    }
  ]
}
```

---

### مثال 2: Response مع data wrapper

```json
{
  "success": true,
  "data": {
    "total_shipments": 221,
    "active_shipments": 127,
    "delivered_shipments": 94,
    "warehouse_parcels_count": 15,
    "recent_shipments": [...]
  }
}
```

---

### مثال 3: Response مع nested objects

```json
{
  "shipments": {
    "total": 221,
    "active": 127,
    "delivered": 94
  },
  "warehouse": {
    "parcels_count": 15
  },
  "recent_shipments": [...]
}
```

---

### مثال 4: Response شامل مع كل المؤشرات

```json
{
  "total_shipments": 221,
  "active_shipments": 127,
  "delivered_shipments": 94,
  "warehouse_parcels_count": 15,
  "pending_shipments": 10,
  "cancelled_shipments": 3,
  "returned_shipments": 2,
  "delayed_shipments": 5,
  "total_revenue": 150000,
  "monthly_revenue": 45000,
  "total_customers": 350,
  "new_customers_this_month": 25,
  "recent_shipments": [
    {
      "tracking_number": "y002",
      "status": "في الصندوق",
      "current_status": "في الصندوق",
      "date": "2026-04-13",
      "date_added": "2026-04-13 19:57:08",
      "weight": "2.5",
      "destination": "القاهرة"
    },
    {
      "tracking_number": "y001",
      "status": "في الطريق",
      "current_status": "في الطريق",
      "date": "2026-04-13",
      "date_added": "2026-04-13 01:06:53"
    }
  ],
  "company_name": "أونلاين إيزي",
  "last_update": "2026-04-13 20:30:00",
  "system_status": "نشط"
}
```

---

## 🎨 كيف تظهر البيانات في التطبيق؟

### 1️⃣ المؤشرات الرئيسية (4 بطاقات)

```
┌─────────────────┬─────────────────┐
│  🚚 221         │  ⚡ 127         │
│  إجمالي الشحنات│  شحنات نشطة    │
├─────────────────┼─────────────────┤
│  ✅ 94          │  📦 15          │
│  تم التسليم    │  طرود بالصندوق │
└─────────────────┴─────────────────┘
```

### 2️⃣ مخطط حالة الشحنات (Bar Chart)

```
     127        94         15
      │         │          │
      │         │          │
    ┌─┴─┐     ┌─┴─┐      ┌─┴─┐
    │███│     │███│      │███│
    │███│     │███│      │░░░│
    │███│     │░░░│      │░░░│
    └───┘     └───┘      └───┘
    نشطة    تم التسليم  الصندوق
```

### 3️⃣ مؤشرات إضافية (إذا وُجدت)

```
┌─────────────────┬─────────────────┐
│  📊 10          │  ❌ 3           │
│  قيد الانتظار  │  ملغاة          │
├─────────────────┼─────────────────┤
│  💰 150,000     │  👥 350         │
│  إجمالي الإيرادات│ إجمالي العملاء│
└─────────────────┴─────────────────┘
```

### 4️⃣ آخر الشحنات

```
┌────────────────────────────────┐
│ 📦 رقم التتبع: y002           │
│ 🔴 في الصندوق                 │
│ 📅 2026-04-13                  │
└────────────────────────────────┘
┌────────────────────────────────┐
│ 📦 رقم التتبع: y001           │
│ 🟡 في الطريق                  │
│ 📅 2026-04-13                  │
└────────────────────────────────┘
```

---

## 🔄 Fallback Behavior (السلوك الاحتياطي)

إذا لم يرسل الباك إند البيانات، التطبيق سيحسبها تلقائياً من:
- `GET /ezzy/v1/shipments` - قائمة الشحنات

**مثال:**
```
إذا لم يرسل الباك إند active_shipments:
→ التطبيق يجلب كل الشحنات
→ يفلتر الشحنات التي ليست "تم التسليم"
→ يعد عددها
```

---

## ✅ Checklist للباك إند

### الحد الأدنى المطلوب (Minimum Required):
- [ ] `total_shipments` - إجمالي الشحنات
- [ ] `active_shipments` - الشحنات النشطة
- [ ] `delivered_shipments` - الشحنات المسلّمة
- [ ] `warehouse_parcels_count` - الطرود في الصندوق

### مستحسن (Recommended):
- [ ] `recent_shipments` - آخر 5-10 شحنات
- [ ] `pending_shipments` - شحنات قيد الانتظار
- [ ] `cancelled_shipments` - شحنات ملغاة

### اختياري (Optional):
- [ ] `returned_shipments` - شحنات مرتجعة
- [ ] `delayed_shipments` - شحنات متأخرة
- [ ] `total_revenue` - إجمالي الإيرادات
- [ ] `monthly_revenue` - إيرادات الشهر
- [ ] `total_customers` - إجمالي العملاء
- [ ] أي مؤشرات أخرى مفيدة للبيزنس

---

## 🧪 اختبار الـ API

### باستخدام cURL:

```bash
curl -u "CONSUMER_KEY:CONSUMER_SECRET" \
  "https://demo.onlineezzy.com/wp-json/ezzy/v1/dashboard"
```

### Response متوقع (200 OK):

```json
{
  "total_shipments": 221,
  "active_shipments": 127,
  "delivered_shipments": 94,
  "warehouse_parcels_count": 15,
  "recent_shipments": [...]
}
```

### Response في حالة خطأ (401 Unauthorized):

```json
{
  "code": "rest_forbidden",
  "message": "You must be logged in to access this endpoint.",
  "data": {
    "status": 401
  }
}
```

---

## 📝 ملاحظات مهمة

### 1. المرونة في أسماء الحقول
التطبيق يبحث في قائمة من الأسماء البديلة، لذا يمكن استخدام أي من الأسماء المذكورة.

**مثال:**
```json
// كل هذه صحيحة:
{ "total_shipments": 221 }
{ "shipments_count": 221 }
{ "shipments": { "total": 221 } }
```

### 2. دعم Nested Objects
التطبيق يفلطن الـ nested objects تلقائياً.

**مثال:**
```json
{
  "shipments": {
    "total": 221,
    "active": 127
  }
}
// يتحول إلى:
{
  "shipments.total": 221,
  "shipments.active": 127
}
```

### 3. الأولوية
إذا وُجد أكثر من حقل، التطبيق يأخذ الأول في القائمة.

**مثال:**
```json
{
  "total_shipments": 221,    // ✅ سيُستخدم هذا
  "shipments_count": 250     // ❌ سيُتجاهل
}
```

### 4. الأنواع المقبولة
- **الأرقام:** `int`, `double`, أو `string` يمكن تحويله لرقم
- **النصوص:** `string`
- **Boolean:** `true`/`false`
- **القوائم:** `array` (للشحنات الأخيرة)

---

## 🎯 الخلاصة

### للحصول على أفضل تجربة في Dashboard:

1. ✅ أرسل المؤشرات الأربعة الأساسية
2. ✅ أرسل `recent_shipments` (5-10 شحنات)
3. ✅ أضف مؤشرات إضافية حسب احتياجات البيزنس
4. ✅ استخدم أسماء واضحة ومنطقية
5. ✅ تأكد من صحة البيانات (الأرقام موجبة، التواريخ صحيحة)

### Response مثالي:

```json
{
  "total_shipments": 221,
  "active_shipments": 127,
  "delivered_shipments": 94,
  "warehouse_parcels_count": 15,
  "pending_shipments": 10,
  "cancelled_shipments": 3,
  "recent_shipments": [
    {
      "tracking_number": "y002",
      "status": "في الصندوق",
      "date": "2026-04-13"
    }
  ]
}
```

---

**تاريخ الوثيقة:** 2026-05-05  
**الإصدار:** 1.0  
**الحالة:** ✅ نهائي
