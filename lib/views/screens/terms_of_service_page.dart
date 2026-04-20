import 'package:online_ezzy/core/app_translations.dart';
import 'package:flutter/material.dart';

import 'in_app_web_page.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return InAppWebPage(
      title: 'شروط الخدمة'.tr,
      url: AppWebUrls.privacyPolicy,
    );
  }
}
