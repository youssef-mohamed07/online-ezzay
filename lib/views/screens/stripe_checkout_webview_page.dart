import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class StripeCheckoutWebViewPage extends StatefulWidget {
  const StripeCheckoutWebViewPage({
    super.key,
    required this.initialUrl,
  });

  final String initialUrl;

  @override
  State<StripeCheckoutWebViewPage> createState() =>
      _StripeCheckoutWebViewPageState();
}

class _StripeCheckoutWebViewPageState extends State<StripeCheckoutWebViewPage> {
  WebViewController? _controller;
  int _progress = 0;
  bool _finished = false;
  String? _initError;
  bool _isOpeningBrowser = false;

  bool get _useBrowserFallback =>
      defaultTargetPlatform == TargetPlatform.iOS;

  bool _isSuccessUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('/checkout/order-received/') ||
        lower.contains('order-received');
  }

  void _finish(bool paid) {
    if (_finished) return;
    _finished = true;
    if (mounted) {
      Navigator.of(context).pop(paid);
    }
  }

  Future<void> _openInBrowser() async {
    if (_isOpeningBrowser) return;
    setState(() {
      _isOpeningBrowser = true;
    });

    final uri = Uri.parse(widget.initialUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);

    if (!mounted) return;
    setState(() {
      _isOpeningBrowser = false;
    });

    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح صفحة الدفع، حاول مرة أخرى.')),
      );
    }
  }

  Future<void> _initializeWebView() async {
    try {
      final controller = WebViewController();
      await Future.sync(
        () => controller.setJavaScriptMode(JavaScriptMode.unrestricted),
      );
      await Future.sync(
        () => controller.setNavigationDelegate(
          NavigationDelegate(
            onProgress: (progress) {
              if (!mounted) return;
              setState(() {
                _progress = progress;
              });
            },
            onNavigationRequest: (request) {
              if (_isSuccessUrl(request.url)) {
                _finish(true);
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        ),
      );
      await Future.sync(
        () => controller.loadRequest(Uri.parse(widget.initialUrl)),
      );

      if (!mounted) return;
      setState(() {
        _controller = controller;
        _initError = null;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _initError = e.message ?? 'حدث خطأ أثناء فتح صفحة الدفع.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initError = 'حدث خطأ أثناء فتح صفحة الدفع.';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (_useBrowserFallback) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openInBrowser();
      });
      return;
    }
    unawaited(_initializeWebView());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _finish(false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إتمام الدفع'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _finish(false),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: _progress < 100
                ? LinearProgressIndicator(value: _progress / 100)
                : const SizedBox.shrink(),
          ),
        ),
        body: _useBrowserFallback
            ? Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'فتحنا صفحة الدفع الآمنة. بعد إتمام الدفع ارجع للتطبيق ثم اضغط "تحققت من الدفع".',
                      style: TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isOpeningBrowser ? null : _openInBrowser,
                      child: Text(
                        _isOpeningBrowser
                            ? 'جاري فتح صفحة الدفع...'
                            : 'فتح صفحة الدفع',
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => _finish(true),
                      child: const Text('تحققت من الدفع'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => _finish(false),
                      child: const Text('إلغاء'),
                    ),
                  ],
                ),
              )
            : (_controller == null
                ? Center(
                    child: _initError == null
                        ? const CircularProgressIndicator()
                        : Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _initError!,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _openInBrowser,
                                  child: const Text('فتح الدفع في المتصفح'),
                                ),
                                TextButton(
                                  onPressed: () => _finish(false),
                                  child: const Text('رجوع'),
                                ),
                              ],
                            ),
                          ),
                  )
                : WebViewWidget(controller: _controller!)),
      ),
    );
  }
}
