with open("lib/views/screens/contact_us_page.dart", "r", encoding="utf-8") as f:
    text = f.read()

# Change to stateful
text = text.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:online_ezzy/core/api_service.dart';")
text = text.replace("class ContactUsPage extends StatelessWidget {", "class ContactUsPage extends StatefulWidget {\n  const ContactUsPage({super.key});\n  @override\n  State<ContactUsPage> createState() => _ContactUsPageState();\n}\nclass _ContactUsPageState extends State<ContactUsPage> {")
text = text.replace("  const ContactUsPage({super.key});", "")

old_body = """        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('نحن هنا لمساعدتك!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
            SizedBox(height: 8),
            Text('يمكنك التواصل معنا عبر الطرق التالية أو عبر إرسال رسالة مباشرة من التطبيق.', style: TextStyle(color: Colors.black54, fontSize: 14)),
            SizedBox(height: 32),
            _buildContactMethod(Icons.phone_in_talk_outlined, 'رقم الهاتف'.tr, '+966 9200xxxxx'),
            SizedBox(height: 16),
            _buildContactMethod(Icons.email_outlined, 'البريد الإلكتروني', 'support@onlineezzay.com'),
            SizedBox(height: 16),
            _buildContactMethod(Icons.location_on_outlined, 'العنوان الرئيسي', 'المملكة العربية السعودية، الرياض'),
            SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.chat_bubble_outline, color: Colors.white),
              label: Text('بدء محادثة مباشرة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),"""

new_body = """        body: FutureBuilder(
          future: ApiService.getSettings(),
          builder: (context, snapshot) {
            final data = snapshot.data as Map<String, dynamic>?;
            final phone = data?['support_phone'] ?? '+966 9200xxxxx';
            final email = data?['support_email'] ?? 'support@onlineezzay.com';
            final address = data?['company_address'] ?? 'المملكة العربية السعودية، الرياض';

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('نحن هنا لمساعدتك!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                const Text('يمكنك التواصل معنا عبر الطرق التالية أو عبر إرسال رسالة مباشرة من التطبيق.', style: TextStyle(color: Colors.black54, fontSize: 14)),
                const SizedBox(height: 32),
                _buildContactMethod(Icons.phone_in_talk_outlined, 'رقم الهاتف'.tr, phone),
                const SizedBox(height: 16),
                _buildContactMethod(Icons.email_outlined, 'البريد الإلكتروني', email),
                const SizedBox(height: 16),
                _buildContactMethod(Icons.location_on_outlined, 'العنوان الرئيسي', address),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: () => _contactUsDialog(context),
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                  label: const Text('بدء محادثة مباشرة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            );
          }
        ),"""
text = text.replace(old_body, new_body)

# Add _contactUsDialog
dialog_logic = """
  void _contactUsDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final msgController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 24, left: 24, right: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('إرسال رسالة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'الاسم'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: msgController,
                    decoration: const InputDecoration(labelText: 'رسالتك'),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isSubmitting ? null : () async {
                      setSheetState(() => isSubmitting = true);
                      final res = await ApiService.contactUs({
                        'name': nameController.text,
                        'email': emailController.text,
                        'message': msgController.text,
                      });
                      setSheetState(() => isSubmitting = false);
                      Navigator.pop(context);
                      if (res != null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال رسالتك بنجاح')));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء الإرسال')));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.all(16)),
                    child: isSubmitting 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('إرسال', style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}"""
text = text.replace("}\n", dialog_logic, 1) # Only replace the outer closing brace

with open("lib/views/screens/contact_us_page.dart", "w", encoding="utf-8") as f:
    f.write(text)
