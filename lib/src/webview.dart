import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;

import 'package:webview_flutter/webview_flutter.dart';

/// Wrapper around the [WebView] widget.
class ChatWebView extends StatefulWidget {
  final ChatWebViewState state;

  ChatWebView(WebViewCreatedCallback webViewFn, PageFinishedCallback jsFn, {Key? key})
      : state = ChatWebViewState(webViewFn, jsFn),
      super(key: key);

  @override
  ChatWebViewState createState() => this.state;
}

class ChatWebViewState extends State<ChatWebView> {
  late WebView webView;

  ChatWebViewState(WebViewCreatedCallback webViewFn,
      PageFinishedCallback jsFn) {
    // Enable hybrid composition.
    if (Platform.isAndroid) {
      WebView.platform = SurfaceAndroidWebView();
    }

    this.webView = WebView(
      initialUrl: 'about:blank',
      javascriptMode: JavascriptMode.unrestricted,
      debuggingEnabled: !kReleaseMode,
      onWebViewCreated: webViewFn,
      onPageFinished: jsFn,
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return this.webView;
  }
}

