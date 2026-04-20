import re

with open('lib/views/screens/shipment_details_page.dart', 'r') as f:
    content = f.read()

# Replace stateless with stateful
pattern_class = r"""class ShipmentDetailsPage extends StatelessWidget \{.*?const ShipmentDetailsPage\(\{.*?\}\);"""
replacement_class = """import 'package:online_ezzy/providers/shipment_provider.dart';
import 'package:provider/provider.dart';

class ShipmentDetailsPage extends StatefulWidget {
  final String trackingNumber;
  final String status;
  final String weight;
  final String date;

  const ShipmentDetailsPage({
    super.key,
    required this.trackingNumber,
    required this.status,
    required this.weight,
    required this.date,
  });

  @override
  State<ShipmentDetailsPage> createState() => _ShipmentDetailsPageState();
}

class _ShipmentDetailsPageState extends State<ShipmentDetailsPage> {
  Map<String, dynamic>? _details;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final provider = context.read<ShipmentProvider>();
    final data = await provider.getShipmentDetails(widget.trackingNumber);
    if (mounted) {
      setState(() {
        _details = data;
        _isLoading = false;
      });
    }
  }

"""
content = re.sub(pattern_class, replacement_class, content, flags=re.DOTALL)

# Add widget. to all references
content = re.sub(r'(?<!\.)\b(trackingNumber|status|weight|date)\b', r'widget.\1', content)

# Change build method to show loader
pattern_build = r"(@override\s+Widget build\(BuildContext context\) \{)"
replacement_build = r"""\1
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: Text(
            'تفاصيل الشحنة'.tr,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFE71D24))),
      );
    }
"""
content = re.sub(pattern_build, replacement_build, content)

# Modify header to optionally show image
pattern_header = r"Widget _buildHeaderCard\(\) \{.*?child: Row\("
replacement_header = r"""Widget _buildHeaderCard() {
    final imageUrl = _details?['image']?.toString() ?? _details?['image_url']?.toString();
    
    return Container(
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
      child: Row("""
content = re.sub(pattern_header, replacement_header, content, flags=re.DOTALL)

# Replace the Icon container with Image if available
pattern_icon = r"Container\(\s*width: 60,\s*height: 60,\s*decoration: BoxDecoration\(\s*color: const Color\(0xFFF1F5F9\),\s*borderRadius: BorderRadius\.circular\(12\),\s*\),\s*child: Icon\(Icons\.inventory_2_outlined, color: Color\(0xFFE71D24\), size: 30\),\s*\),"
replacement_icon = r"""Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              image: imageUrl != null && imageUrl.isNotEmpty ? DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ) : null,
            ),
            child: imageUrl == null || imageUrl.isEmpty ? const Icon(Icons.inventory_2_outlined, color: Color(0xFFE71D24), size: 30) : null,
          ),"""
content = re.sub(pattern_icon, replacement_icon, content, flags=re.DOTALL)

# Modify _buildDetailsCard to include detailed dates
pattern_details = r"Widget _buildDetailsCard\(\) \{.*?_buildDetailRow\('تاريخ التحديث'\.tr, widget\.date\),"
replacement_details = r"""Widget _buildDetailsCard() {
    final statusHistory = _details?['history'] as List?;
    final lastUpdate = statusHistory != null && statusHistory.isNotEmpty ? statusHistory.last['date']?.toString() : widget.date;
    final carrier = _details?['carrier']?.toString() ?? 'أرامكس - Aramex';
    
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'معلومات إضافية'.tr,
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          _buildDetailRow('الوزن'.tr, '${widget.weight} كجم'.tr),
          const Divider(height: 30, color: Color(0xFFF1F5F9)),
          _buildDetailRow('تاريخ التحديث'.tr, lastUpdate ?? widget.date),"""
content = re.sub(pattern_details, replacement_details, content, flags=re.DOTALL)

# Replace remaining Aramex
content = content.replace("'أرامكس - Aramex'.tr", "carrier.tr")

with open('lib/views/screens/shipment_details_page.dart', 'w') as f:
    f.write(content)

