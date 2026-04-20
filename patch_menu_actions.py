import os
import re

file_path = "lib/views/screens/profile_page.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Replacements for the menu items
old_account_details = "_buildMenuListItem('تفاصيل الحساب'),"
new_account_details = "_buildMenuListItem('تفاصيل الحساب', onTap: _showAccountDetailsBottomSheet),"

old_downloads = "_buildMenuListItem('التنزيلات'),"
new_downloads = "_buildMenuListItem('التنزيلات', onTap: _showDownloadsBottomSheet),"

content = content.replace(old_account_details, new_account_details)
content = content.replace(old_downloads, new_downloads)

bottom_sheet_code = '''
  void _showAccountDetailsBottomSheet() {
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
                initialValue: 'يوسف',
                decoration: InputDecoration(
                  labelText: 'الاسم',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: 'example@email.com',
                decoration: InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: '+966 50 123 4567',
                decoration: InputDecoration(
                  labelText: 'رقم الهاتف',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('حفظ التغييرات', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showDownloadsBottomSheet() {
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
                'لم تقم بتحميل أي ملفات أو فواتير بعد.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
'''

content = re.sub(r'\}\s*$', bottom_sheet_code, content)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("Patch applied successfully.")
