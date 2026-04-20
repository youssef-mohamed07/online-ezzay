import 'package:online_ezzy/core/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_ezzy/providers/auth_provider.dart';
import 'package:online_ezzy/providers/shipment_provider.dart';
import 'package:online_ezzy/core/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'edit_profile_page.dart';
import 'settings_page.dart';
import 'po_box_page.dart';
import 'consultation_page.dart';
import 'auth/login_page.dart';
import 'shell_page.dart';
import 'shipment_details_page.dart';
import 'track_page.dart';

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

  List<Map<String, dynamic>> _customerOrders = [];
  bool _isOrdersLoading = false;
  String? _ordersError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadProfileData();
    });
  }

  Future<void> _loadProfileData() async {
    final auth = context.read<AuthProvider>();
    final shipmentProvider = context.read<ShipmentProvider>();

    await shipmentProvider.loadShipments();

    final userId = _resolveUserId(auth.userData);
    if (!auth.isAuthenticated || userId == null) {
      if (!mounted) return;
      setState(() {
        _customerOrders = [];
        _ordersError = null;
        _isOrdersLoading = false;
      });
      return;
    }

    setState(() {
      _isOrdersLoading = true;
      _ordersError = null;
    });

    try {
      final orders = await ApiService.getCustomerOrders(userId);
      if (!mounted) return;
      setState(() {
        _customerOrders = orders;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _customerOrders = [];
        _ordersError = 'تعذر تحميل الطلبات';
      });
    } finally {
      if (!mounted) return;
      setState(() => _isOrdersLoading = false);
    }
  }

  String? _resolveUserId(Map<String, dynamic>? user) {
    if (user == null) return null;
    final rawId =
        user['id'] ??
        user['user_id'] ??
        user['ID'] ??
        (user['data'] is Map ? user['data']['id'] : null);
    final id = rawId?.toString().trim();
    if (id == null || id.isEmpty || id.toLowerCase() == 'null') {
      return null;
    }
    return id;
  }

  String _safeText(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'null') return '';
    return text;
  }

  String _orderStatusLabel(String status) {
    final normalized = status.trim().toLowerCase();
    switch (normalized) {
      case 'pending':
        return 'بانتظار الدفع';
      case 'processing':
        return 'قيد المعالجة';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      case 'failed':
        return 'فشل';
      case 'on-hold':
        return 'معلق';
      case 'refunded':
        return 'مسترجع';
      default:
        return status.isEmpty ? 'غير معروف' : status;
    }
  }

  String _formatOrderDate(dynamic rawDate) {
    final parsed = DateTime.tryParse(rawDate?.toString() ?? '');
    if (parsed == null) return '-';
    final d = parsed.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }

  bool _isDeliveredStatus(String status) {
    final normalized = status.toLowerCase();
    return normalized.contains('تم التسليم') ||
        normalized.contains('delivered') ||
        normalized.contains('completed');
  }

  int _resolveOrderItemsCount(Map<String, dynamic> order) {
    final lineItems = order['line_items'];
    if (lineItems is! List) return 0;

    int total = 0;
    for (final item in lineItems) {
      if (item is! Map) continue;
      total += int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
    }
    return total;
  }

  List<Map<String, dynamic>> _resolveCustomerAddresses(AuthProvider auth) {
    final user = auth.userData;
    if (user == null) return [];

    final result = <Map<String, dynamic>>[];

    void addAddressFromMap(String title, dynamic source, bool isDefault) {
      if (source is! Map) return;

      final firstName = _safeText(source['first_name']);
      final lastName = _safeText(source['last_name']);
      final fullName = '$firstName $lastName'.trim();

      final line1 = _safeText(source['address_1']);
      final line2 = _safeText(source['address_2']);
      final line = [line1, line2].where((v) => v.isNotEmpty).join(' - ');

      final city = _safeText(source['city']);
      final state = _safeText(source['state']);
      final country = _safeText(source['country']);
      final phone = _safeText(source['phone']);

      final hasData =
          fullName.isNotEmpty ||
          line.isNotEmpty ||
          city.isNotEmpty ||
          state.isNotEmpty ||
          country.isNotEmpty ||
          phone.isNotEmpty;
      if (!hasData) return;

      result.add({
        'title': title,
        'fullName': fullName.isNotEmpty ? fullName : auth.displayName,
        'addressLine': line,
        'city': [city, state, country].where((v) => v.isNotEmpty).join(' - '),
        'phone': phone,
        'isDefault': isDefault,
      });
    }

    addAddressFromMap('عنوان الفواتير', user['billing'], true);
    addAddressFromMap('عنوان الشحن', user['shipping'], result.isEmpty);

    return result;
  }

  List<Map<String, dynamic>> _resolvePaymentMethodsFromOrders() {
    final methods = <String, Map<String, dynamic>>{};

    for (final order in _customerOrders) {
      final rawTitle = _safeText(
        order['payment_method_title'] ?? order['payment_method'],
      );
      if (rawTitle.isEmpty) continue;

      final key = rawTitle.toLowerCase();
      final existing = methods[key];
      if (existing == null) {
        methods[key] = {'title': rawTitle, 'ordersCount': 1};
      } else {
        existing['ordersCount'] = (existing['ordersCount'] as int) + 1;
      }
    }

    return methods.values.toList();
  }

  List<Map<String, String>> _resolveDownloadLinks() {
    final links = <Map<String, String>>[];

    for (final order in _customerOrders) {
      final orderId = _safeText(order['id']);

      void addLink(String label, dynamic rawUrl) {
        final url = _safeText(rawUrl);
        if (!url.startsWith('http')) return;
        links.add({'title': '$label #$orderId', 'url': url});
      }

      addLink('تفاصيل الطلب', order['checkout_payment_url']);
      addLink('رابط الدفع', order['payment_url']);
      addLink('عرض الطلب', order['view_order_url']);
    }

    return links;
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (!opened && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر فتح الرابط')));
    }
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
                final navigator = Navigator.of(context);
                if (navigator.canPop()) {
                  navigator.pop();
                } else {
                  navigator.pushReplacement(
                    MaterialPageRoute(builder: (_) => const ShellPage()),
                  );
                }
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
                        title: const Text(
                          'تسجيل الخروج',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        content: const Text(
                          'هل أنت متأكد أنك تريد تسجيل الخروج؟',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text(
                              'إلغاء',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'موافق',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                        (route) => false,
                      );
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
                      (route) => false,
                    );
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
            },
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
            color: Colors.black.withValues(alpha: 0.03),
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
          _buildMenuListItem(
            'تفاصيل الحساب',
            onTap: _showAccountDetailsBottomSheet,
          ),
          const Divider(height: 1, color: Color(0xFFF4F6F9)),
          _buildMenuListItem('التنزيلات', onTap: _showDownloadsBottomSheet),
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
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final String name = auth.displayName;
          final String email = auth.primaryEmail;

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
            color: Colors.black.withValues(alpha: 0.03),
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
    if (_isOrdersLoading) {
      return ListView(
        children: const [
          SizedBox(height: 16),
          Center(child: CircularProgressIndicator(color: Color(0xFFE71D24))),
        ],
      );
    }

    if (_ordersError != null) {
      return ListView(
        children: [
          _buildTopProfileSection(),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                const Text(
                  'تعذر تحميل الطلبات',
                  style: TextStyle(
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadProfileData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE71D24),
                  ),
                  child: const Text(
                    'إعادة المحاولة',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_customerOrders.isEmpty) {
      return ListView(
        children: [
          _buildTopProfileSection(),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'لا توجد طلبات حقيقية في حسابك حالياً',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      children: [
        _buildTopProfileSection(),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'الطلبات',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        ..._customerOrders.map(_buildOrderItem),
      ],
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> order) {
    final id = '#${_safeText(order['id'])}';
    final statusRaw = _safeText(order['status']);
    final statusLabel = _orderStatusLabel(statusRaw);
    final date = _formatOrderDate(order['date_created']);
    final currency = _safeText(order['currency']).toUpperCase();
    final total = _safeText(order['total']);
    final price = total.isEmpty ? '-' : '$total $currency';
    final itemsCount = _resolveOrderItemsCount(order);
    final paymentMethod = _safeText(
      order['payment_method_title'] ?? order['payment_method'],
    );
    final isFailed = statusRaw.toLowerCase() == 'failed';

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
                    'عدد العناصر : $itemsCount',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  if (paymentMethod.isNotEmpty)
                    Text(
                      'الدفع: $paymentMethod',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              if (statusLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isFailed ? Colors.red : const Color(0xFFE2E8F0),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: isFailed ? Colors.red : const Color(0xFF475569),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showOrderDetailsSheet(order),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'عرض الطلب',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetailsSheet(Map<String, dynamic> order) {
    final lineItems = (order['line_items'] is List)
        ? List<Map<String, dynamic>>.from(
            (order['line_items'] as List).whereType<Map>(),
          )
        : <Map<String, dynamic>>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'طلب #${_safeText(order['id'])}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'الحالة: ${_orderStatusLabel(_safeText(order['status']))}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'التاريخ: ${_formatOrderDate(order['date_created'])}',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 6),
                Text(
                  'الإجمالي: ${_safeText(order['total'])} ${_safeText(order['currency']).toUpperCase()}',
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'العناصر',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 10),
                if (lineItems.isEmpty)
                  const Text(
                    'لا توجد عناصر لعرضها',
                    style: TextStyle(color: Color(0xFF64748B)),
                  )
                else
                  ...lineItems.map((item) {
                    final name = _safeText(item['name']);
                    final qty = _safeText(item['quantity']);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 16,
                            color: Color(0xFFE71D24),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$name × $qty',
                              style: const TextStyle(color: Color(0xFF334155)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShipmentsTab() {
    return Consumer<ShipmentProvider>(
      builder: (context, shipmentProvider, _) {
        if (shipmentProvider.isLoading && shipmentProvider.shipments.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFE71D24)),
          );
        }

        final shipments = shipmentProvider.shipments;
        if (shipments.isEmpty) {
          return ListView(
            children: [
              _buildTopProfileSection(),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'لا توجد شحنات حقيقية في حسابك حالياً',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        }

        return ListView(
          children: [
            _buildTopProfileSection(),
            ...shipments.map((shipment) {
              final trackingNumber =
                  _safeText(shipment['tracking_number']).isNotEmpty
                  ? _safeText(shipment['tracking_number'])
                  : _safeText(shipment['number']).isNotEmpty
                  ? _safeText(shipment['number'])
                  : _safeText(shipment['id']);

              final status = _safeText(
                shipment['current_status'] ??
                    shipment['status'] ??
                    shipment['shipment_status'],
              );
              final delivered = _isDeliveredStatus(status);
              final weight = _safeText(
                shipment['weight'] ?? shipment['total_weight'],
              );
              final date = _safeText(
                shipment['date_added'] ??
                    shipment['date'] ??
                    shipment['created_at'],
              );
              final details = [
                if (weight.isNotEmpty) 'الوزن $weight كجم',
                if (date.isNotEmpty) 'تاريخ $date',
              ].join(' | ');

              return _buildShipmentItem(
                trackingNumber,
                status.isEmpty ? 'غير معروف' : status,
                delivered,
                details.isEmpty ? null : details,
                onViewDetails: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShipmentDetailsPage(
                        trackingNumber: trackingNumber,
                        status: status,
                        weight: weight,
                        date: date,
                      ),
                    ),
                  );
                },
                onTrack: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TrackPage(initialTrackingNumber: trackingNumber),
                    ),
                  );
                },
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildShipmentItem(
    String trackingNumber,
    String status,
    bool delivered,
    String? details, {
    required VoidCallback onViewDetails,
    required VoidCallback onTrack,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFA),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFF1F1), Color(0xFFFFE4E4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    color: Color(0xFFE71D24),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'شحنة',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'رقم التتبع: #$trackingNumber',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE71D24).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE71D24),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: const TextStyle(
                          color: Color(0xFFE71D24),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(height: 1, color: const Color(0xFFF1F5F9)),

          // Timeline Section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: _buildTimelineStep(
                    'في المستودع'.tr,
                    isActive:
                        status == 'في المستودع' ||
                        status == 'في الطريق' ||
                        status == 'تم التسليم' ||
                        status == 'في الصندوق',
                    isCompleted:
                        status == 'في الطريق' ||
                        status == 'تم التسليم' ||
                        delivered,
                  ),
                ),
                _buildTimelineLine(
                  isCompleted:
                      status == 'في الطريق' ||
                      status == 'تم التسليم' ||
                      delivered,
                ),
                Expanded(
                  child: _buildTimelineStep(
                    'في الطريق'.tr,
                    isActive:
                        status == 'في الطريق' ||
                        status == 'تم التسليم' ||
                        delivered,
                    isCompleted: status == 'تم التسليم' || delivered,
                  ),
                ),
                _buildTimelineLine(
                  isCompleted: status == 'تم التسليم' || delivered,
                ),
                Expanded(
                  child: _buildTimelineStep(
                    'تم التسليم'.tr,
                    isActive: status == 'تم التسليم' || delivered,
                    isCompleted: status == 'تم التسليم' || delivered,
                  ),
                ),
              ],
            ),
          ),

          // Actions Section
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onViewDetails,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'عرض التفاصيل',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onTrack,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE71D24),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'تتبع',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (details != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
              child: Text(
                details,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(
    String label, {
    required bool isActive,
    required bool isCompleted,
  }) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFFE71D24)
                : (isActive
                      ? const Color(0xFFE71D24).withValues(alpha: 0.1)
                      : const Color(0xFFF1F5F9)),
            shape: BoxShape.circle,
            border: Border.all(
              color: isCompleted || isActive
                  ? const Color(0xFFE71D24)
                  : const Color(0xFFE2E8F0),
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : (isActive
                      ? Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE71D24),
                            shape: BoxShape.circle,
                          ),
                        )
                      : Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFCBD5E1),
                            shape: BoxShape.circle,
                          ),
                        )),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive || isCompleted
                ? FontWeight.w800
                : FontWeight.w600,
            color: isActive || isCompleted
                ? const Color(0xFF1E293B)
                : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineLine({required bool isCompleted}) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 3,
        margin: const EdgeInsets.only(bottom: 28),
        decoration: BoxDecoration(
          color: isCompleted
              ? const Color(0xFFE71D24)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildAddressTab() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final addresses = _resolveCustomerAddresses(auth);

        return ListView(
          children: [
            _buildTopProfileSection(),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.035),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'العناوين',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'العناوين المحفوظة في حسابك',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditProfilePage(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFD9DB)),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                color: Color(0xFFE71D24),
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'تحديث البيانات',
                                style: TextStyle(
                                  color: Color(0xFFE71D24),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (addresses.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Text(
                        'لا توجد عناوين حقيقية محفوظة حالياً',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    ...addresses.map(
                      (address) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildRealAddressLineCard(address),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRealAddressLineCard(Map<String, dynamic> address) {
    final bool isDefault = address['isDefault'] == true;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDefault ? const Color(0xFFFFD4D8) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDefault
                      ? const Color(0xFFFFF1F2)
                      : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  color: isDefault
                      ? const Color(0xFFE71D24)
                      : const Color(0xFF64748B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _safeText(address['title']).isEmpty
                          ? 'عنوان'
                          : _safeText(address['title']),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _safeText(address['fullName']),
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),
          Text(
            _safeText(address['addressLine']),
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _safeText(address['city']),
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          if (_safeText(address['phone']).isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 6),
                Text(
                  _safeText(address['phone']),
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsTab() {
    final methods = _resolvePaymentMethodsFromOrders();

    return ListView(
      children: [
        _buildTopProfileSection(),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'طرق الدفع',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'طرق الدفع المستخدمة في طلباتك',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox.shrink(),
                ],
              ),
              const SizedBox(height: 16),
              if (_isOrdersLoading)
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE71D24)),
                )
              else if (methods.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Text(
                    'لا توجد طرق دفع حقيقية مسجلة في طلباتك حتى الآن',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                ...methods.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildRealPaymentMethodLine(
                      title: _safeText(entry.value['title']),
                      ordersCount: (entry.value['ordersCount'] as int?) ?? 0,
                      isPrimary: entry.key == 0,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRealPaymentMethodLine({
    required String title,
    required int ordersCount,
    required bool isPrimary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPrimary ? const Color(0xFFFFD4D8) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          _buildCardBrandBadge('Pay'),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'استُخدمت في $ordersCount طلب',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (isPrimary)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'الأكثر استخداماً',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFFE71D24),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardBrandBadge(String brand) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.credit_card_rounded,
            size: 18,
            color: Color(0xFFC68A5A),
          ),
          const SizedBox(height: 2),
          Text(
            brand,
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF9A6B3A),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  void _showAccountDetailsBottomSheet() {
    final auth = context.read<AuthProvider>();
    final user = auth.userData;
    final userId = _resolveUserId(user);
    final name = auth.displayName;
    final email = auth.primaryEmail;
    final billing = user?['billing'];
    final phone = _safeText(billing is Map ? billing['phone'] : null);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'تفاصيل الحساب',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                initialValue: name,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'الاسم',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: email,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: phone,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'رقم الهاتف',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              if (userId != null)
                OutlinedButton(
                  onPressed: () async {
                    await auth.fetchCustomerDetails(userId);
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تحديث البيانات من الحساب'),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('تحديث الآن'),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    this.context,
                    MaterialPageRoute(builder: (_) => const EditProfilePage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'تعديل البيانات',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showDownloadsBottomSheet() {
    final downloads = _resolveDownloadLinks();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              if (downloads.isEmpty) ...[
                const Icon(
                  Icons.cloud_download_outlined,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'لا توجد تنزيلات متوفرة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'لا توجد روابط تنزيل فعلية في طلباتك حالياً.',
                  style: TextStyle(color: Colors.grey),
                ),
              ] else ...[
                const Text(
                  'روابط متاحة من طلباتك',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                ...downloads.map(
                  (entry) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.link_rounded,
                      color: Color(0xFFE71D24),
                    ),
                    title: Text(entry['title'] ?? 'ملف'),
                    subtitle: Text(
                      entry['url'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _openUrl(entry['url'] ?? ''),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
