import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import 'package:webview_flutter/webview_flutter.dart';

/// Wrapper around the [WebView] widget.
class ChatWebView extends StatefulWidget {
  final ChatWebViewState state;

  ChatWebView(WebViewCreatedCallback webViewFn, PageFinishedCallback jsFn, Set<JavascriptChannel> javascriptChannels, {Key? key})
      : state = ChatWebViewState(webViewFn, jsFn, javascriptChannels),
      super(key: key);

  @override
  ChatWebViewState createState() => this.state;
}

class ChatWebViewState extends State<ChatWebView> {
  late WebView webView;

  ChatWebViewState(WebViewCreatedCallback webViewFn, PageFinishedCallback jsFn, Set<JavascriptChannel> javascriptChannels) {
    // Enable hybrid composition.
    if (Platform.isAndroid) {
      WebView.platform = SurfaceAndroidWebView();
    }

    this.webView = WebView(
      initialUrl: 'about:blank',
      javascriptMode: JavascriptMode.unrestricted,
      debuggingEnabled: kDebugMode,
      onWebViewCreated: webViewFn,
      onPageFinished: jsFn,
      javascriptChannels: javascriptChannels,
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

