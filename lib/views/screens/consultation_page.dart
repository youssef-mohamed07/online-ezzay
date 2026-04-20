import 'package:flutter/material.dart';

import 'in_app_web_page.dart';

class ConsultationPage extends StatelessWidget {
  const ConsultationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return InAppWebPage(
      title: 'احصل على استشارة',
      url: AppWebUrls.contact,
    );
  }
}