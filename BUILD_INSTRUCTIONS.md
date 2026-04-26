# تعليمات بناء التطبيق - Build Instructions

## 📱 بناء APK للأندرويد

### ✅ تم بناء APK بنجاح!

**الموقع:**
```
build/app/outputs/flutter-apk/app-release.apk
```

**الحجم:** 66.0 MB

---

## 🔨 أوامر البناء

### 1. APK عادي (للتوزيع المباشر)
```bash
flutter build apk --release
```

**الناتج:**
- `build/app/outputs/flutter-apk/app-release.apk`
- حجم واحد يعمل على جميع معماريات ARM

---

### 2. APK منفصل لكل معمارية (حجم أصغر)
```bash
flutter build apk --split-per-abi --release
```

**الناتج:**
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM)
- `app-x86_64-release.apk` (64-bit x86)

**الفائدة:** كل ملف أصغر حجماً (~20-25 MB)

---

### 3. App Bundle (للنشر على Google Play)
```bash
flutter build appbundle --release
```

**الناتج:**
- `build/app/outputs/bundle/release/app-release.aab`

**الفائدة:** 
- Google Play يوزع APK محسّن لكل جهاز
- حجم تحميل أصغر للمستخدمين

---

## 📋 معلومات التطبيق

### من `pubspec.yaml`:
```yaml
name: online_ezzy
version: 1.0.0+1
```

### من `android/app/build.gradle.kts`:
```kotlin
applicationId: com.example.online_ezzy
minSdk: 21 (Android 5.0)
targetSdk: 34 (Android 14)
versionCode: 1
versionName: 1.0.0
```

---

## 🔐 التوقيع (Signing)

### الوضع الحالي:
⚠️ **التطبيق موقّع بمفتاح Debug**

```kotlin
signingConfig = signingConfigs.getByName("debug")
```

### للنشر على Google Play:
يجب إنشاء مفتاح Release وتوقيع التطبيق به.

#### خطوات إنشاء مفتاح Release:

1. **إنشاء Keystore:**
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

2. **إنشاء ملف `android/key.properties`:**
```properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=<path-to-keystore>/upload-keystore.jks
```

3. **تعديل `android/app/build.gradle.kts`:**
```kotlin
// قبل android {
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ...
    
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

4. **إضافة إلى `.gitignore`:**
```
android/key.properties
*.jks
*.keystore
```

---

## 🚀 التوزيع

### 1. التوزيع المباشر (Direct Distribution)
- شارك ملف `app-release.apk`
- المستخدمون يحتاجون تفعيل "مصادر غير معروفة"

### 2. Google Play Store
- استخدم `app-release.aab`
- اتبع [دليل Google Play](https://support.google.com/googleplay/android-developer/answer/9859152)

### 3. Firebase App Distribution
```bash
firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-release.apk \
  --app YOUR_APP_ID \
  --groups testers
```

---

## 🧪 اختبار APK

### تثبيت على جهاز متصل:
```bash
flutter install
```

### تثبيت APK مباشرة:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### إلغاء التثبيت:
```bash
adb uninstall com.example.online_ezzy
```

---

## 📊 تحليل حجم APK

### عرض تفاصيل الحجم:
```bash
flutter build apk --analyze-size
```

### تقليل الحجم:
```bash
# تفعيل obfuscation
flutter build apk --obfuscate --split-debug-info=build/debug-info

# بناء منفصل لكل معمارية
flutter build apk --split-per-abi
```

---

## 🔍 فحص APK

### باستخدام Android Studio:
1. Build > Analyze APK
2. اختر `app-release.apk`
3. شاهد محتويات APK والحجم

### باستخدام Command Line:
```bash
# عرض محتويات APK
unzip -l build/app/outputs/flutter-apk/app-release.apk

# فحص التوقيع
jarsigner -verify -verbose -certs app-release.apk
```

---

## ⚙️ إعدادات إضافية

### تغيير اسم التطبيق:
**`android/app/src/main/AndroidManifest.xml`:**
```xml
<application
    android:label="أونلاين إيزي"
    ...>
```

### تغيير أيقونة التطبيق:
```bash
flutter pub run flutter_launcher_icons
```

### تغيير Application ID:
**`android/app/build.gradle.kts`:**
```kotlin
applicationId = "com.onlineezzy.app"
```

---

## 🐛 حل المشاكل الشائعة

### 1. خطأ في Gradle:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk
```

### 2. مشاكل في Dependencies:
```bash
flutter pub upgrade
flutter pub get
```

### 3. مشاكل في Kotlin:
تأكد من إصدار Kotlin في `android/build.gradle`:
```kotlin
plugins {
    id "org.jetbrains.kotlin.android" version "1.9.0" apply false
}
```

---

## 📝 Checklist قبل النشر

- [ ] تحديث رقم الإصدار في `pubspec.yaml`
- [ ] إنشاء مفتاح Release
- [ ] توقيع APK بمفتاح Release
- [ ] اختبار APK على أجهزة مختلفة
- [ ] فحص الأذونات في AndroidManifest
- [ ] إضافة Privacy Policy
- [ ] تحضير Screenshots للمتجر
- [ ] كتابة وصف التطبيق
- [ ] تحديد الفئة العمرية

---

## 📱 متطلبات النشر على Google Play

### معلومات مطلوبة:
1. **App Details:**
   - اسم التطبيق
   - وصف قصير (80 حرف)
   - وصف كامل (4000 حرف)
   - الفئة

2. **Graphics:**
   - أيقونة 512x512
   - Feature Graphic 1024x500
   - Screenshots (2-8 صور)

3. **Privacy Policy:**
   - رابط سياسة الخصوصية

4. **Content Rating:**
   - استبيان تصنيف المحتوى

5. **Pricing:**
   - مجاني أو مدفوع
   - الدول المتاحة

---

## 🔄 تحديث التطبيق

### زيادة رقم الإصدار:
**`pubspec.yaml`:**
```yaml
version: 1.0.1+2  # 1.0.1 = versionName, 2 = versionCode
```

### بناء إصدار جديد:
```bash
flutter build appbundle --release
```

### رفع على Google Play:
1. افتح Google Play Console
2. اذهب إلى Production
3. Create new release
4. ارفع AAB الجديد
5. أضف Release notes
6. Review and rollout

---

## 📞 الدعم

للمزيد من المعلومات:
- [Flutter Deployment Docs](https://docs.flutter.dev/deployment/android)
- [Android App Bundle](https://developer.android.com/guide/app-bundle)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
