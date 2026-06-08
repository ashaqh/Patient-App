import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/themes/app_theme.dart';

class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({super.key});

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(AppConstants.termsOfServiceUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.secondaryColor,
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.onPrimaryColor,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: AppTheme.secondaryColor,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
