# Online Ezzy - Absolute Complete Backend API Architecture
*Version: 3.0 (Final Comprehensive Revision) | Date: March 2026*

---
## 🌍 1. Core Config & Localization
- **Headers:** `Accept-Language: en` or `ar`. ALL STRINGS returned by the backend MUST respect this header.
- **Enums/Dropdowns:** Must be fetched from `[GET] /api/v1/lookups` rather than hardcoded in the frontend.

---
## 🔐 2. Authentication & Auth Flow (`/api/v1/auth`)
- **[POST] `/register`**: `first_name`, `last_name`, `email`, `phone`, `password`.
- **[POST] `/verify-otp`**: `identifier`, `otp`.
- **[POST] `/login`**: `identifier` (Email/Phone), `password`, `device_token`, `os_type`.
- **[POST] `/forgot-password`** => **`/verify-reset-otp`** => **`/reset-password`**

---
## 👤 3. Profile & User Data (`/api/v1/profile`)
- **[GET] `/`**: Needs to return user info PLUS:
  - `wallet_balance`
  - `active_plan` (e.g., if subscribed to "باقة 3 طرود")
  - `pobox_status` (Active / None)
- **[POST] `/update`** (FormData): Allows updating profile fields + `avatar`.
- **[POST] `/change-password`**: Security endpoint.

---
## 📦 4. Subscription & Delivery Plans (باقات التوصيل) (`/api/v1/plans`)
*(From `packages_page.dart`)*
- **[GET] `/delivery-bundles`**: Returns available plans.
  - Data: `[{ "id": 1, "title_ar": "باقة 3 طرود", "subtitle": "مثالية للشحنات", "features": [...], "price": 30.00 }]`
- **[POST] `/subscribe-bundle`**: Subscribes user to a bundle -> Sends invoice to Cart.

---
## 🏢 5. PO Box Module (`/api/v1/pobox`)
*(From `po_box_page.dart`)*
- **[GET] `/plans`**: Returns PO Box subscription tiers.
- **[GET] `/features`**: Returns dynamic sliders for "لماذا تختارنا" and "ماذا ستحصل".
- **[POST] `/subscribe`**: Select plan id -> Adds Setup Fee to Cart.

---
## 📍 6. Addresses & Virtual Forwarding (`/api/v1/addresses`)
*(From `address_page.dart`, `us_address_page.dart`, `cn_address_page.dart`)*
- **[GET] `/user-locations`**: User's saved physical points.
- **[GET] `/virtual-routes`**: Returns available virtual hubs (عنوان الداخل, أمريكي, صيني).
- **[POST] `/calculator/us`**: (Shipping Rate Custom Calculator for US Address)
  - Body: `ship_from`, `deliver_to`, `service_provider` (DHL, Aramex), `weight`, `unit` (kg/lb).
  - Returns: Estimated Price.
- **[POST] `/purchase/us-address`**: Subscribes user to the US address (e.g., الباقة الذهبية).
- **[POST] `/purchase/cn-address`**:
  - Body: `expected_weight_range` (e.g., "< 1KG", "1-5KG"), `insurance_type` ('none', 'partial', 'full').

---
## 🛩️ 7. Shipments & Customs (`/api/v1/shipments`)
*(From `custom_shipment_page.dart` and `shipment_details_page.dart`)*
- **[GET] `/`**: Query `?status=processing|inTransit|delayed|delivered`.
  - Data returned MUST include `progress` percentage (e.g. `0.68`) for UI sliders, `eta` (Delivery Date), `origin`, `destination`, `category`.
- **[GET] `/{tracking_number}/track`**: Returns detailed Event Timeline (Date, Status, Desc) + Extra info (Shipping company, Weight).

### 7.1 Complex Manual Shipment
- **[POST] `/custom`** (FormData):
  - Sender: `name`, `phone`, `address`
  - Receiver: `name`, `phone`, `address`
  - **Parcels Array**: `[{ length, width, height }]` (Needs dynamic calculation).
  - Calculated volume/weight, tax rate, and subtotal must be cross-verified by backend.

---
## 🛒 8. Cart & Financial Services (`/api/v1/cart` & `/finance`)
*(From `cart_page.dart` & `home_page.dart` "خدمات مالية")*
- **[GET] `/cart`**: 
  - Items can be of different types: `Delivery Plans`, `US/CN Address Subscription`, `PO Box Sub`, `Financial Service (e.g., Wise Starter)`, `Custom Shipment Taxes`.
- **[POST] `/cart/checkout`**: `payment_method` (visa, googlePay, paypal, wallet).
- **[GET] `/financial-services`**: List active financial assistance/cards (Wise Starter, etc.) users can apply for.

---
## 🔔 9. Notifications (`/api/v1/notifications`)
- **[GET] `/`**: List notifications.
- **[PUT] `/{id}/read`**: Mark specific notification as read.

---
## ⚙️ 10. App Config & Static Content (`/api/v1/app`)
*(From `onboarding_page.dart`, `home_page.dart`)*
- **[GET] `/init`**:
  - Contains Onboarding screens (Title, Subtitle, Image URL).
  - Contains Home Banners (اطلب توصيل, العناوين, تتبع شحنتك).
  - Contains App settings (Tax rates, Cubic unit price calculations).
  - Contact Info (WhatsApp, email, terms_html).
