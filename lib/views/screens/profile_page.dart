import 'package:online_ezzy/core/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_ezzy/providers/auth_provider.dart';
import 'edit_profile_page.dart';
import 'settings_page.dart';
import 'po_box_page.dart';
import 'consultation_page.dart';
import 'auth/login_page.dart';
import 'shell_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showMainProfile =
      true; // تتحكم في التبديل بين الشاشة الرئيسية وشاشة التبويبات

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 0);
  }

  void _navigateToTab(int index) {
    setState(() {
      _showMainProfile = false;
      _tabController.index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const BackButtonIcon(), // Auto directional
            onPressed: () {
              if (!_showMainProfile) {
                setState(() {
                  _showMainProfile = true;
                });
              } else {
                // Normal back action, e.g. Navigator.pop(context);
              }
            },
          ),
          title: Text(
            'حسابي',
            style: TextStyle(
              color: Color(0xFF2C3E50),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: _showMainProfile
              ? [
                  IconButton(
                    icon: Icon(Icons.settings_outlined, color: Colors.black87),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      );
                    },
                  ),
                ]
              : null,
          bottom: _showMainProfile
              ? null
              : TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  indicator: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  tabs: const [
                    Tab(text: 'الطلبات'),
                    Tab(text: 'تفاصيل الطرود'),
                    Tab(text: 'العناوين'),
                    Tab(text: 'طرق الدفع'),
                  ],
                ),
        ),
        body: _showMainProfile
            ? _buildMainProfileView()
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildOrdersTab(),
                  _buildShipmentsTab(),
                  _buildAddressTab(),
                  _buildPaymentMethodsTab(),
                ],
              ),
      ),
    );
  }

  // ==== Main Profile Layout ====

  Widget _buildMainProfileView() {
    return ListView(
      children: [
        _buildProfileCard(isMain: true),
        _buildServicesCard(),
        _buildAccountMenuCard(),
        SizedBox(height: 16),
        Center(
          child: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (auth.isAuthenticated) {
                return TextButton(
                  onPressed: () async {
                    // Show confirmation dialog before logout
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('تسجيل الخروج', style: TextStyle(fontWeight: FontWeight.bold)),
                        content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('موافق', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await auth.logout();
                      if (!context.mounted) return;
                      // Navigate to logic page or shell page
                      // Since they can be guest, maybe navigate to shell or login.
                      Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const ShellPage()),
                          (route) => false);
                    }
                  },
                  child: const Text(
                    'تسجيل الخروج',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              } else {
                return TextButton(
                  onPressed: () {
                    // if guest is browsing and wants to login
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false);
                  },
                  child: const Text(
                    'تسجيل الدخول',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }
            }
          ),
        ),
        SizedBox(height: 32),
      ],
    );
  }

  Widget _buildAccountMenuCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'حسابي',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          SizedBox(height: 8),
          _buildMenuListItem('الطلبات', onTap: () => _navigateToTab(0)),
          const Divider(height: 1, color: Color(0xFFF4F6F9)),
          _buildMenuListItem('تفاصيل الطرود', onTap: () => _navigateToTab(1)),
          const Divider(height: 1, color: Color(0xFFF4F6F9)),
          _buildMenuListItem('العناوين', onTap: () => _navigateToTab(2)),
          const Divider(height: 1, color: Color(0xFFF4F6F9)),
          _buildMenuListItem('طرق الدفع', onTap: () => _navigateToTab(3)),
          const Divider(height: 1, color: Color(0xFFF4F6F9)),
          _buildMenuListItem('تفاصيل الحساب'),
          const Divider(height: 1, color: Color(0xFFF4F6F9)),
          _buildMenuListItem('التنزيلات'),
        ],
      ),
    );
  }

  Widget _buildMenuListItem(String title, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
      ),
      trailing: Icon(Icons.arrow_back_ios, size: 14, color: Colors.grey),
      onTap: onTap ?? () {},
    );
  }

  // ==== Reusable Top Sections ====

  Widget _buildTopProfileSection() {
    return Column(
      children: [
        _buildProfileCard(isMain: false),
        _buildServicesCard(),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildProfileCard({required bool isMain}) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.userData;
          
          final String name = user != null
              ? (user['user_display_name'] ?? user['display_name'] ?? user['username'] ?? 'مستخدم')
              : 'ضيف';
              
          final String email = user != null
              ? (user['user_email'] ?? user['email'] ?? 'غير متوفر')
              : 'غير متوفر';
              
          return Column(
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 35,
                    child: Icon(Icons.person, size: 30),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 14,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 4),
                            Text(
                              email,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfilePage(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    isMain ? 'تعديل البيانات' : 'تعديل تفاصيل الحساب',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildServicesCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'خدمات اخرى',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          SizedBox(height: 8),
          _buildMenuListItem(
            'احصل على استشارة',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConsultationPage()),
              );
            },
          ),
          const Divider(height: 1, color: Color(0xFFF4F6F9)),
          _buildMenuListItem(
            'صندوق بريدي',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const POBoxPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==== Tabs Content ====

  Widget _buildOrdersTab() {
    return ListView(
      children: [
        _buildTopProfileSection(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: const [
              Text(
                'الطلبات',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 16),
              Text(
                'فشل',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
              SizedBox(width: 16),
              Text(
                'بانتظار الدفع',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              SizedBox(width: 16),
              Text('ملغي', style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
        SizedBox(height: 12),
        _buildOrderItem('#14687', '26 أكتوبر 2025', '\$18.49', '2', true),
        _buildOrderItem('#14684', '25 أكتوبر 2025', '\$49.24', '5', true),
        _buildOrderItem('#14682', '24 أكتوبر 2025', '\$10.10', '1', true),
      ],
    );
  }

  Widget _buildOrderItem(
    String id,
    String date,
    String price,
    String items,
    bool isFailed,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(id, style: const TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: Colors.grey,
                  ),
                  SizedBox(width: 4),
                  Text(
                    date,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'عدد العناصر : $items',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              if (isFailed)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'فشل',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'عرض الطلب',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('الدفع', style: TextStyle(color: Colors.red)),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('إلغاء', style: TextStyle(color: Colors.grey)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShipmentsTab() {
    return ListView(
      children: [
        _buildTopProfileSection(),
        _buildShipmentItem(
          '8742638',
          'في الصندوق'.tr,
          true,
          'الوزن 2.5 كجم | تاريخ 12 مايو',
        ),
        _buildShipmentItem('6654429', 'في الطريق'.tr, false, null),
      ],
    );
  }

  Widget _buildShipmentItem(
    String trackingNumber,
    String status,
    bool delivered,
    String? details,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'رقم التتبع : $trackingNumber'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.inbox,
                  color: Colors.grey,
                ), // Placeholder for image
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: delivered
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: delivered ? Colors.blue : Colors.orange,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(height: 20),
          // Simple timeline replacement
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.red, size: 20),
              Container(width: 40, height: 2, color: Colors.red),
              Icon(Icons.check_circle, color: Colors.red, size: 20),
              Container(width: 40, height: 2, color: Colors.grey.shade300),
              Icon(Icons.circle, color: Colors.grey.shade300, size: 20),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'في الصندوق'.tr,
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Text(
                'في الطريق'.tr,
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Text(
                'تم التسليم'.tr,
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  minimumSize: const Size(80, 36),
                ),
                child: Text('تتبع'.tr, style: TextStyle(color: Colors.white)),
              ),
              if (details != null)
                Row(
                  children: [
                    Text(
                      'عرض التفاصيل'.tr,
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      details,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressTab() {
    return ListView(
      children: [
        _buildTopProfileSection(),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'عنوان الفاتورة',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF2C3E50),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'تعديل عنوان الفاتورة',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                ),
              ),
              SizedBox(height: 16),
              _buildAddressLine('Melusi Ncube'),
              _buildAddressLine('nrjfn'),
              _buildAddressLine('nrmm'),
              _buildAddressLine('رام الله'),
              _buildAddressLine('نابلس'),
              _buildAddressLine('00260'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(color: Colors.grey[800], fontSize: 14),
      ),
    );
  }

  Widget _buildPaymentMethodsTab() {
    return ListView(
      children: [
        _buildTopProfileSection(),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'طريقة الدفع',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  Text(
                    'تاريخ الانتهاء',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  Text(
                    'حذف',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _buildPaymentLine('تنتهي في 4242 Visa', '30/2029'),
              const Divider(),
              _buildPaymentLine('تنتهي في 4242 Visa', '30/2029'),
              const Divider(),
              _buildPaymentLine('تنتهي في 4242 Visa', '30/2029'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentLine(String method, String expiry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Text(method, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              expiry,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(Icons.delete_outline, size: 16, color: Colors.red),
          ),
        ],
      ),
    );
  }
}
