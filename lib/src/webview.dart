import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;

import 'package:webview_flutter/webview_flutter.dart';

import './ui.dart';

/// Wrapper around the [WebView] widget.
class ChatWebView extends StatefulWidget {
  final ChatWebViewState state;

  ChatWebView(ChatBox chatbox, WebViewCreatedCallback webViewFn, PageFinishedCallback jsFn)
      : state = ChatWebViewState(chatbox, webViewFn, jsFn);

  @override
  ChatWebViewState createState() => this.state;
}

class ChatWebViewState extends State<ChatWebView> {
  late WebView webView;
  ChatBox? chatbox;

  ChatWebViewState(this.chatbox, WebViewCreatedCallback webViewFn,
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

  @override
  void dispose() {
    super.dispose();

    chatbox!.disposeWebView();

    // Break circular reference
    chatbox = null;
  }
}
