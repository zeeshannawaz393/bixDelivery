import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../utils/colors.dart';
import '../../utils/pending_supplies_order.dart';

class SuppliesWebViewScreen extends StatefulWidget {
  final String initialUrl;
  final String title;

  const SuppliesWebViewScreen({
    super.key,
    required this.initialUrl,
    this.title = 'Supplies',
  });

  @override
  State<SuppliesWebViewScreen> createState() => _SuppliesWebViewScreenState();
}

class _SuppliesWebViewScreenState extends State<SuppliesWebViewScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _canGoBack = false;
  Timer? _canGoBackTimer;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted) return;
            setState(() => _progress = progress);
          },
          onPageFinished: (String url) async {
            _handlePageFinished(url);
            await _refreshCanGoBack();
          },
          onWebResourceError: (_) async {
            await _refreshCanGoBack();
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));

    // Keep canGoBack reasonably fresh without being expensive.
    _canGoBackTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _refreshCanGoBack();
    });
  }

  void _handlePageFinished(String url) {
    if (!mounted || !url.contains('order_success.php')) return;
    Uri uri;
    try {
      uri = Uri.parse(url);
    } catch (_) {
      return;
    }
    final orderId = uri.queryParameters['order_id']?.trim();
    final orderNumber = orderId != null && orderId.isNotEmpty
        ? 'Supplies-$orderId'
        : '';
    PendingSuppliesOrder.set(orderNumber);
    Get.offAllNamed(
      '/home',
      arguments: <String, dynamic>{
        'tab': 0,
        'showCreateDelivery': true,
        'orderNumber': orderNumber,
      },
    );
  }

  Future<void> _refreshCanGoBack() async {
    try {
      final canGoBack = await _controller.canGoBack();
      if (!mounted) return;
      if (canGoBack != _canGoBack) {
        setState(() => _canGoBack = canGoBack);
      }
    } catch (_) {
      // Ignore - controller might not be ready during teardown.
    }
  }

  @override
  void dispose() {
    _canGoBackTimer?.cancel();
    _canGoBackTimer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_canGoBack,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_canGoBack) {
          await _controller.goBack();
          await _refreshCanGoBack();
        } else {
          if (Get.isOverlaysOpen) {
            Get.back();
          } else {
            Navigator.of(context).maybePop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: Text(widget.title),
          leading: IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close),
            tooltip: 'Close',
          ),
          actions: [
            if (_canGoBack)
              IconButton(
                onPressed: () async {
                  await _controller.goBack();
                  await _refreshCanGoBack();
                },
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                tooltip: 'Back',
              ),
          ],
        ),
        body: Column(
          children: [
            if (_progress < 100)
              LinearProgressIndicator(
                value: _progress / 100,
                minHeight: 2,
                backgroundColor: Colors.grey.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              ),
            Expanded(
              child: WebViewWidget(controller: _controller),
            ),
          ],
        ),
      ),
    );
  }
}

