import 'package:online_ezzy/core/app_translations.dart';
import 'package:flutter/material.dart';

import 'in_app_web_page.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return InAppWebPage(
      title: 'سياسة الخصوصية'.tr,
      url: AppWebUrls.privacyPolicy,
    );
  }
}
