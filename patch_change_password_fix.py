with open('lib/views/screens/change_password_page.dart', 'r') as f:
    text = f.read()

old_submit = """    setState(() => _isLoading = false);

    if (res != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل في تغيير كلمة المرور')),
      );
    }"""

new_submit = """    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.containsKey('success') || (res['message']?.contains('تم بنجاح') ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'تم تغيير كلمة المرور بنجاح')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'فشل في تغيير كلمة المرور')),
      );
    }"""

text = text.replace(old_submit, new_submit)

with open('lib/views/screens/change_password_page.dart', 'w') as f:
    f.write(text)
