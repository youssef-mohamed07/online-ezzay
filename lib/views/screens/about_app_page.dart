import 'package:online_ezzy/core/app_translations.dart';
import 'package:flutter/material.dart';

import 'in_app_web_page.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return InAppWebPage(
      title: 'حول التطبيق'.tr,
      url: AppWebUrls.privacyPolicy,
    );
  }
}
