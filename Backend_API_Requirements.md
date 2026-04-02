#  المستند الشامل لمتطلبات الواجهة الخلفية (APIs) المتبقية
هذا الملف يحتوي على **كافة البيانات الثابتة (Dummy Data)** المتبقية في التطبيق بأكمله والتي تحتاج إلى مسارات حية من لوحة تحكم WordPress / WooCommerce.

##  1. نظام الشحنات الخاصة بالعميل (Shipments System)
موجودة في صفحة (Shipments) وتفاصيل الشحنة shipments_page.dart.
- GET /wp-json/ezzy/v1/shipments : **قائمة شحنات المستخدم الحالية والسابقة** (يعيد tracking_number status date).
- GET /wp-json/ezzy/v1/shipments/{id} : **تفاصيل شحنة معينة بالكامل** (يعيد مسار التتبع الزمني المنتجات التكلفة).
- POST /wp-json/ezzy/v1/shipments/request : **إنشاء طلب شحنة مخصصة** (في قسم الباقات المخصصة).

##  2. الصفحة الرئيسية وعدادات لوحة التحكم (Home Dashboard)
الإحصائيات واللافتات الإعلانية في شاشة home_page.dart.
- GET /wp-json/ezzy/v1/dashboard : **عدادات الشحنات** (يعيد رقم الشحنات النشطة ورقم الطرود في المستودع).
- GET /wp-json/ezzy/v1/sliders : **البنرات الإعلانية المتحركة** لجلبها من הסيرفر بدلا من الصور المخزنة.
- GET /wp-json/ezzy/v1/track?number={id} : **التتبع السريع برقم بوليصة** مخصص لمربع البحث الصغير أعلى الرئيسية.

##  3. الإشعارات للمستخدمين (Notifications System)
- GET /wp-json/ezzy/v1/notifications : **سجل الإشعارات والتنبيهات** (تم تأكيد الدفع تم الشحن وصلت المستودع). 
otifications_page.dart

##  4. إعدادات الحساب والعناوين (Account & Global Addresses)
- POST /wp-json/ezzy/v1/change_password : **تغيير كلمة المرور** (من داخل التطبيق عن طريق old/new password). 
- GET /wp-json/ezzy/v1/warehouse-addresses : **عناوين المستودعات الدولية** (أمريكا/الصين). هل العميل يحصل على (PO Box) مختلف لكل حساب إن نعم فهذا الـ API إلزامي.  ddress_details_page.dart

##  5. الصفحات الثابتة والدعم (Static Pages & Support)
- GET /wp-json/wp/v2/pages?slug=privacy-policy : **صفحات اللوائح والشروط** (الخصوصية الأحكام من نحن) ليسهل التعديل مستقبلا من الووردبريس.
- GET /wp-json/ezzy/v1/settings : **بيانات التواصل Contact Us** (رقم الواتساب البريد ومواعيد العمل الرسمية).
- POST /wp-json/ezzy/v1/contact : **إرسال رسالة شكوى للفريق الفني** (فورم تواصل معنا الحالية contact_us_page.dart).

---
 **ملحوظة:** تم توصيل (المنتجات والسلة والدفع Stripe Checkouts وتسجيل الدخول والخروج وتعديل حساب العميل Profile) بنسبة 100% بنجاح. ما تبقى هو المدرج أعلاه لتصبح المنصة حية.
