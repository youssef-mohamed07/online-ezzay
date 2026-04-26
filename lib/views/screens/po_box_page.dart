import 'package:flutter/material.dart';
import 'in_app_web_page.dart';

class POBoxPage extends StatelessWidget {
  const POBoxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return InAppWebPage(
      title: 'صندوق بريدي',
      url: AppWebUrls.poBox,
    );
  }
}
