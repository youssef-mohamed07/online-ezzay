import 'package:flutter/material.dart';
import 'package:online_ezzy/core/app_translations.dart';

import 'in_app_web_page.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return InAppWebPage(
      title: 'تواصل معنا'.tr,
      url: AppWebUrls.contact,
    );
  }
}
