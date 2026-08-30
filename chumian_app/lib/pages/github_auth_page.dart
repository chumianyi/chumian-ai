import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// GitHub OAuth 授权页面（App 内 WebView 直接授权，无网页中转）
/// 打开后加载 GitHub 授权页，拦截回调 URL 提取 code，通过 Navigator.pop 返回 code。
class GithubAuthPage extends StatefulWidget {
  final String authUrl;
  final String callbackUrlPrefix;

  const GithubAuthPage({
    super.key,
    required this.authUrl,
    this.callbackUrlPrefix = 'https://chumianyi.github.io/chumian-ai-auth/callback',
  });

  @override
  State<GithubAuthPage> createState() => _GithubAuthPageState();
}

class _GithubAuthPageState extends State<GithubAuthPage> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
          onWebResourceError: (error) {
            // 忽略回调页面的资源加载错误（WebView 拦截后不会真正加载）
            if (error.url != null && error.url!.startsWith(widget.callbackUrlPrefix)) {
              return;
            }
            setState(() => _error = '加载失败: ${error.description}');
          },
          onNavigationRequest: (request) {
            // 拦截回调 URL，提取 code
            if (request.url.startsWith(widget.callbackUrlPrefix)) {
              final uri = Uri.parse(request.url);
              final code = uri.queryParameters['code'];
              final error = uri.queryParameters['error'];
              if (error != null) {
                Navigator.of(context).pop({'error': error, 'error_description': uri.queryParameters['error_description']});
              } else if (code != null && code.isNotEmpty) {
                Navigator.of(context).pop({'code': code});
              } else {
                Navigator.of(context).pop({'error': 'no_code'});
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GitHub 授权'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop({'cancelled': true}),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _error = null);
                        _controller.reload();
                      },
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
