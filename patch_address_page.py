import re

with open('lib/views/screens/profile_page.dart', 'r') as f:
    text = f.read()

# Add _savedAddresses right after _savedCards
cards_idx = text.find('];', text.find('_savedCards')) + 2

addresses_code = """

  final List<Map<String, dynamic>> _savedAddresses = [
    {
      'title': 'المنزل',
      'fullName': 'يوسف كمال',
      'addressLine': 'شارع عبد الحميد شومان, رام الله',
      'city': 'رام الله',
      'phone': '+970 599 000 000',
      'isDefault': true,
    },
    {
      'title': 'العمل',
      'fullName': 'يوسف كمال',
      'addressLine': 'عمارة المهندسين, نابلس',
      'city': 'نابلس',
      'phone': '+970 599 111 111',
      'isDefault': false,
    },
  ];
"""

text = text[:cards_idx] + addresses_code + text[cards_idx:]

pattern = r"  Widget _buildAddressTab\(\) \{.*?(?=  Widget _buildPaymentMethodsTab\(\))"

new_content = """  Widget _buildAddressTab() {
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
                color: Colors.black.withOpacity(0.035),
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
                   Column(
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
                    onTap: () => _showAddOrEditAddressDialog(),
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
                            Icons.add_rounded,
                            color: Color(0xFFE71D24),
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'إضافة عنوان',
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
              if (_savedAddresses.isEmpty)
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
                    'لا توجد عناوين محفوظة حالياً',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                ..._savedAddresses.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildAddressLineCard(
                      entry.value,
                      index: entry.key,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressLineCard(Map<String, dynamic> address, {required int index}) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      address['title'] == 'العمل' ? Icons.work_outline : Icons.home_outlined,
                      color: isDefault ? const Color(0xFFE71D24) : const Color(0xFF64748B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            address['title'] ?? 'بدون عنوان',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF1E293B),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1F2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'الافتراضي',
                                style: TextStyle(
                                  color: Color(0xFFE71D24),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        address['fullName'] ?? '',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _showAddOrEditAddressDialog(address: address, index: index),
                    child: const Icon(Icons.edit_outlined, color: Color(0xFF94A3B8), size: 20),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                         _savedAddresses.removeAt(index);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                           content: Text('تم حذف العنوان بنجاح'),
                           backgroundColor: Color(0xFFE71D24),
                        ),
                      );
                    },
                    child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE71D24), size: 20),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),
          Text(
            address['addressLine'] ?? '',
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${address['city'] ?? ''}',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Text(
                address['phone'] ?? '',
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (!isDefault) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                setState(() {
                  for (var addr in _savedAddresses) {
                    addr['isDefault'] = false;
                  }
                  _savedAddresses[index]['isDefault'] = true;
                });
              },
              child: const Text(
                'تعيين كافتراضي',
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  void _showAddOrEditAddressDialog({Map<String, dynamic>? address, int? index}) {
    final bool isEdit = address != null;
    final TextEditingController titleCtrl = TextEditingController(text: address?['title'] ?? '');
    final TextEditingController nameCtrl = TextEditingController(text: address?['fullName'] ?? '');
    final TextEditingController streetCtrl = TextEditingController(text: address?['addressLine'] ?? '');
    final TextEditingController cityCtrl = TextEditingController(text: address?['city'] ?? '');
    final TextEditingController phoneCtrl = TextEditingController(text: address?['phone'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEdit ? 'تعديل العنوان' : 'إضافة عنوان جديد',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded,
                              size: 16, color: Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildAddressDialogTextField(
                      controller: titleCtrl,
                      label: 'الاسم الوصفي (المنزل، العمل، إلخ)'),
                  const SizedBox(height: 12),
                  _buildAddressDialogTextField(
                      controller: nameCtrl, label: 'الاسم الكامل'),
                  const SizedBox(height: 12),
                  _buildAddressDialogTextField(
                      controller: streetCtrl, label: 'العنوان بالتفصيل (الشارع، البناية)'),
                  const SizedBox(height: 12),
                  _buildAddressDialogTextField(
                      controller: cityCtrl, label: 'المدينة'),
                  const SizedBox(height: 12),
                  _buildAddressDialogTextField(
                      controller: phoneCtrl,
                      label: 'رقم الهاتف',
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE71D24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        if (titleCtrl.text.trim().isEmpty ||
                            nameCtrl.text.trim().isEmpty) {
                          return;
                        }
                        setState(() {
                          final newAddr = {
                            'title': titleCtrl.text.trim(),
                            'fullName': nameCtrl.text.trim(),
                            'addressLine': streetCtrl.text.trim(),
                            'city': cityCtrl.text.trim(),
                            'phone': phoneCtrl.text.trim(),
                            'isDefault': address?['isDefault'] ?? (_savedAddresses.isEmpty),
                          };
                          if (isEdit && index != null) {
                            _savedAddresses[index] = newAddr;
                          } else {
                            _savedAddresses.add(newAddr);
                          }
                        });
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        isEdit ? 'حفظ التعديلات' : 'إضافة العنوان',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddressDialogTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
      ],
    );
  }

"""

new_text = re.sub(pattern, new_content, text, flags=re.DOTALL)

with open('lib/views/screens/profile_page.dart', 'w') as f:
    f.write(new_text)

