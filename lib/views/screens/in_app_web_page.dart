import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AppWebUrls {
  static final Uri contact = Uri.parse(
    'https://onlineezzy.com/%D8%AA%D9%88%D8%A7%D8%B5%D9%84-%D9%85%D8%B9%D9%86%D8%A7/',
  );

  static final Uri privacyPolicy = Uri.parse(
    'https://onlineezzy.com/%D8%B3%D9%8A%D8%A7%D8%B3%D8%A9-%D8%A7%D9%84%D8%AE%D8%B5%D9%88%D8%B5%D9%8A%D8%A9/',
  );
}

class InAppWebPage extends StatefulWidget {
  const InAppWebPage({
    super.key,
    required this.title,
    required this.url,
  });

  final String title;
  final Uri url;

  @override
  State<InAppWebPage> createState() => _InAppWebPageState();
}

class _InAppWebPageState extends State<InAppWebPage> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _hasError = false;
              _progress = 10;
            });
          },
          onProgress: (value) {
            if (!mounted) return;
            final normalized = value < 0
                ? 0
                : (value > 100 ? 100 : value);
            setState(() => _progress = normalized);
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _progress = 100);
          },
          onWebResourceError: (_) {
            if (!mounted) return;
            setState(() => _hasError = true);
          },
        ),
      )
      ..loadRequest(widget.url);
  }

  void _reload() {
    setState(() {
      _hasError = false;
      _progress = 0;
    });
    _controller.loadRequest(widget.url);
  }

  @override
  Widget build(BuildContext context) {
    final showProgress = !_hasError && _progress < 100;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            widget.title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _reload,
              icon: const Icon(
                Icons.refresh_rounded,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            if (!_hasError)
              WebViewWidget(controller: _controller)
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        size: 48,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'تعذر تحميل الصفحة',
                        style: TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'تحقق من الاتصال وحاول مرة أخرى',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _reload,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE71D24),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),
            if (showProgress)
              LinearProgressIndicator(
                value: _progress / 100,
                minHeight: 3,
                color: const Color(0xFFE71D24),
                backgroundColor: const Color(0xFFE2E8F0),
              ),
          ],
        ),
      ),
    );
  }
}