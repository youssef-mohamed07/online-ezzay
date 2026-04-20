import re

with open("lib/views/screens/home_page.dart", "r", encoding="utf-8") as f:
    code = f.read()

new_card = """class _ActiveShipmentCard extends StatelessWidget {
  final Map<String, dynamic> shipment;
  _ActiveShipmentCard({required this.shipment});

  @override
  Widget build(BuildContext context) {
    final status = (shipment['status']?.toString() ?? 'في المستودع').tr;
    final id = shipment['id']?.toString() ?? 'N/A';
    final title = shipment['title']?.toString() ?? 'شحنة';

    return Container(
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
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
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
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'رقم التتبع: #$id',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          Container(
            height: 1,
            color: const Color(0xFFF1F5F9),
          ),
          
          // Timeline Section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: _buildTimelineStep(
                    'في المستودع'.tr,
                    isActive: status == 'في المستودع' || status == 'في الطريق' || status == 'تم التسليم',
                    isCompleted: status == 'في الطريق' || status == 'تم التسليم',
                  ),
                ),
                _buildTimelineLine(isCompleted: status == 'في الطريق' || status == 'تم التسليم'),
                Expanded(
                  child: _buildTimelineStep(
                    'في الطريق'.tr,
                    isActive: status == 'في الطريق' || status == 'تم التسليم',
                    isCompleted: status == 'تم التسليم',
                  ),
                ),
                _buildTimelineLine(isCompleted: status == 'تم التسليم'),
                Expanded(
                  child: _buildTimelineStep(
                    'تم التسليم'.tr,
                    isActive: status == 'تم التسليم',
                    isCompleted: status == 'تم التسليم',
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
                    onPressed: () {},
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
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
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
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
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
                : (isActive ? const Color(0xFFE71D24).withValues(alpha: 0.1) : const Color(0xFFF1F5F9)),
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
            fontWeight: isActive || isCompleted ? FontWeight.w800 : FontWeight.w600,
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
          color: isCompleted ? const Color(0xFFE71D24) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}"""

pattern = re.compile(r"class _ActiveShipmentCard extends StatelessWidget \{.*?(?=class _WarehouseOrderCard extends StatelessWidget \{)", re.DOTALL)
new_code = pattern.sub(new_card + "\n\n", code)

with open("lib/views/screens/home_page.dart", "w", encoding="utf-8") as f:
    f.write(new_code)
