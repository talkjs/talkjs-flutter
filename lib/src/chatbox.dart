import 'dart:convert';
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:talkjs_flutter/src/themeoptions.dart';

import 'package:talkjs_flutter_inappwebview/talkjs_flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import './session.dart';
import './conversation.dart';
import './chatoptions.dart';
import './user.dart';
import './message.dart';
import './predicate.dart';
import './webview_common.dart';

typedef SendMessageHandler = void Function(SendMessageEvent event);
typedef TranslationToggledHandler =
    void Function(TranslationToggledEvent event);
typedef LoadingStateHandler = void Function(LoadingState state);
typedef MessageActionHandler = void Function(MessageActionEvent event);
typedef ConversationActionHandler =
    void Function(ConversationActionEvent event);
typedef NavigationHandler =
    UrlNavigationAction Function(UrlNavigationRequest navigationRequest);
typedef ErrorHandler = void Function(String error);

class SendMessageEvent {
  final ConversationData conversation;
  final UserData me;
  final SentMessage message;

  SendMessageEvent.fromJson(Map<String, dynamic> json)
    : conversation = ConversationData.fromJson(json['conversation']),
      me = UserData.fromJson(json['me']),
      message = SentMessage.fromJson(json['message']);
}

class TranslationToggledEvent {
  final ConversationData conversation;
  final bool isEnabled;

  TranslationToggledEvent.fromJson(Map<String, dynamic> json)
    : conversation = ConversationData.fromJson(json['conversation']),
      isEnabled = json['isEnabled'];
}

enum LoadingState { loading, loaded }

class MessageActionEvent {
  final String action;
  final Message message;

  MessageActionEvent.fromJson(Map<String, dynamic> json)
    : action = json['action'],
      message = Message.fromJson(json['message']);
}

class ConversationActionEvent {
  final String action;
  final ConversationData conversationData;

  ConversationActionEvent.fromJson(Map<String, dynamic> json)
    : action = json['action'],
      conversationData = ConversationData.fromJson(json['conversation']);
}

class UrlNavigationRequest {
  final String url;

  UrlNavigationRequest(this.url);
}

enum UrlNavigationAction { deny, allow }

/// A messaging UI for just a single conversation.
///
/// Create a Chatbox through [Session.createChatbox] and then call [mount] to show it.
/// There is no way for the user to switch between conversations
class ChatBox extends StatefulWidget {
  final Session session;

  final TextDirection? dir;
  final MessageFieldOptions? messageField;
  final bool? showChatHeader;
  final TranslationToggle? showTranslationToggle;
  final String? theme;
  final ThemeOptions? themeOptions;
  final TranslateConversations? translateConversations;
  final List<String> highlightedWords;
  final BaseMessagePredicate? messageFilter;
  final String? scrollToMessage;

  final Conversation? conversation;
  final bool? asGuest;

  final bool enableZoom;

  final SendMessageHandler? onSendMessage;
  final TranslationToggledHandler? onTranslationToggled;
  final LoadingStateHandler? onLoadingStateChanged;
  final Map<String, MessageActionHandler>? onCustomMessageAction;
  final Map<String, ConversationActionHandler>? onCustomConversationAction;
  final NavigationHandler? onUrlNavigation;
  final ErrorHandler? onError;

  const ChatBox({
    super.key,
    required this.session,
    this.dir,
    this.messageField,
    this.showChatHeader,
    this.showTranslationToggle,
    this.theme,
    this.themeOptions,
    this.translateConversations,
    this.highlightedWords = const [],
    this.messageFilter,
    this.conversation,
    this.asGuest,
    this.enableZoom = false,
    this.onSendMessage,
    this.onTranslationToggled,
    this.onLoadingStateChanged,
    this.onCustomMessageAction,
    this.onCustomConversationAction,
    this.onUrlNavigation,
    this.scrollToMessage,
    this.onError,
  });

  @override
  State<ChatBox> createState() => ChatBoxState();
}

class ChatBoxState extends State<ChatBox> {
  /// Used to control the underlying WebView
  InAppWebViewController? _webViewController;
  bool _webViewCreated = false;

  /// List of JavaScript statements that haven't been executed.
  final List<String> _pending = [];

  // A counter to ensure that IDs are unique
  int _idCounter = 0;

  /// A mapping of user ids to the variable name of the respective JavaScript
  /// Talk.User object.
  final Map<String, String> _users = {};
  final Map<String, User> _userObjs = {};

  /// A mapping of conversation ids to the variable name of the respective JavaScript
  /// Talk.ConversationBuilder object.
  final Map<String, String> _conversations = {};
  final Map<String, Conversation> _conversationObjs = {};

  /// Encapsulates the message entry field tied to the currently selected conversation.
  // TODO: messageField still needs to be refactored
  //late MessageField messageField;

  /// Objects stored for comparing changes
  ChatBoxOptions? _oldOptions;
  List<String> _oldHighlightedWords = [];
  BaseMessagePredicate? _oldMessageFilter;
  bool? _oldAsGuest;
  Conversation? _oldConversation;
  Set<String> _oldCustomMessageActions = {};
  Set<String> _oldCustomConversationActions = {};
  bool _oldEnableZoom = true;
  String? _oldScrollToMessage;

  late Future<String> userAgentFuture;

  @override
  void initState() {
    super.initState();

    userAgentFuture = Future.sync(() async {
      final version = await rootBundle.loadString(
        'packages/talkjs_flutter/assets/version.txt',
      );
      return 'TalkJS_Flutter/${version.trim().replaceAll('"', '')}';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('📗 chatbox.build (_webViewCreated: $_webViewCreated)');
    }

    if (!_webViewCreated) {
      // If it's the first time that the widget is built, then build everything
      _webViewCreated = true;

      if (Platform.isAndroid) {
        InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
      }

      // Here a Timer is needed, as we can't change the widget's state while the widget
      // is being constructed, and the callback may very possibly change the state
      Timer.run(() => widget.onLoadingStateChanged?.call(LoadingState.loading));

      _updateEnableZoom();

      execute('let chatBox;');
      execute('''
        function customMessageActionHandler(event) {
          window.flutter_inappwebview.callHandler("JSCCustomMessageAction", JSON.stringify(event));
        }
      ''');

      execute('''
        function customConversationActionHandler(event) {
          window.flutter_inappwebview.callHandler("JSCCustomConversationAction", JSON.stringify(event));
        }
      ''');

      // Use Web Visibility API to notify the backend when the UI/WebView is in focus
      execute(
        'document.addEventListener("visibilitychange", () => chatBox.onWindowVisibleChanged(document.visibilityState === "visible"));',
      );

      createSession(
        execute: execute,
        session: widget.session,
        variableName: getUserVariableName(widget.session.me),
      );
      _createChatBox();
      // messageFilter and highlightedWords are set as options for the chatbox
      _createConversation();

      execute(
        '''
        chatBox.mount(document.getElementById("talkjs-container")).then(() => {
          window.flutter_inappwebview.callHandler("JSCLoadingState", "loaded");

          // Notify the backend of the UI's focus state
          setTimeout(() => chatBox.onWindowVisibleChanged(document.visibilityState === "visible"), 1000);
        }); true;
      '''
            .trim(),
      );
    } else {
      // If it's not the first time that the widget is built,
      // then check what needs to be rebuilt

      if (widget.enableZoom != _oldEnableZoom) {
        _updateEnableZoom();
      }

      // TODO: If something has changed in the Session we should do something

      final chatBoxRecreated = _checkRecreateChatBox();

      if (chatBoxRecreated) {
        // messageFilter and highlightedWords are set as options for the chatbox
        _createConversation();
      } else {
        _checkMessageActionHandlers();
        _checkConversationActionHandlers();
        _checkMessageFilter();
        _checkHighlightedWords();
        _checkRecreateConversation();
      }

      // Mount the chatbox only if it's new (else the existing chatbox has already been mounted)
      if (chatBoxRecreated) {
        execute(
          '''
          chatBox.mount(document.getElementById("talkjs-container")).then(() => {
            // Notify the backend of the UI's focus state
            setTimeout(() => chatBox.onWindowVisibleChanged(document.visibilityState === "visible"), 1000);
          }); true;
        '''
              .trim(),
        );
      }
    }

    return FutureBuilder(
      future: userAgentFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return InAppWebView(
            initialSettings: InAppWebViewSettings(
              useHybridComposition: true,
              disableInputAccessoryView: true,
              transparentBackground: true,
              useShouldOverrideUrlLoading: true,
              applicationNameForUserAgent: snapshot.data,
              mediaPlaybackRequiresUserGesture: false,
              // Since iOS 16.4, this is required to enabled debugging the webview.
              isInspectable: kDebugMode,
            ),
            onWebViewCreated: _onWebViewCreated,
            onLoadStop: _onLoadStop,
            onConsoleMessage:
                (InAppWebViewController controller, ConsoleMessage message) {
                  if (kDebugMode) {
                    print(
                      "chatbox [${message.messageLevel}] ${message.message}",
                    );
                  }
                  if (message.messageLevel == ConsoleMessageLevel.ERROR) {
                    widget.onError?.call(message.message);
                  }
                },
            gestureRecognizers: {
              // We need only the VerticalDragGestureRecognizer in order to be able to scroll through the messages
              Factory(() => VerticalDragGestureRecognizer()),
            },
            onGeolocationPermissionsShowPrompt:
                (InAppWebViewController controller, String origin) async {
                  print(
                    "📘 chatbox onGeolocationPermissionsShowPrompt ($origin)",
                  );

                  final granted = await Permission.location.request().isGranted;

                  return GeolocationPermissionShowPromptResponse(
                    origin: origin,
                    allow: granted,
                    retain: true,
                  );
                },
            onPermissionRequest:
                (
                  InAppWebViewController controller,
                  PermissionRequest permissionRequest,
                ) async {
                  print("📘 chatbox onPermissionRequest");

                  var granted = false;

                  if (permissionRequest.resources.indexOf(
                        PermissionResourceType.MICROPHONE,
                      ) >=
                      0) {
                    granted = await Permission.microphone.request().isGranted;
                  }

                  return PermissionResponse(
                    resources: permissionRequest.resources,
                    action: granted
                        ? PermissionResponseAction.GRANT
                        : PermissionResponseAction.DENY,
                  );
                },
            shouldOverrideUrlLoading:
                (
                  InAppWebViewController controller,
                  NavigationAction navigationAction,
                ) async {
                  if (Platform.isAndroid ||
                      (navigationAction.navigationType ==
                          NavigationType.LINK_ACTIVATED)) {
                    // NavigationType is only present in iOS devices (Also MacOS but our SDK doesn't support it.)

                    final webUri =
                        navigationAction.request.url ?? WebUri("about:blank");

                    // If onUrlNavigation is null we default to allowing the navigation request.
                    final urlNavigationAction =
                        widget.onUrlNavigation?.call(
                          UrlNavigationRequest(webUri.rawValue),
                        ) ??
                        UrlNavigationAction.allow;

                    if (urlNavigationAction == UrlNavigationAction.deny) {
                      return NavigationActionPolicy.CANCEL;
                    }

                    if (await launchUrl(
                      webUri,
                      mode: LaunchMode.externalApplication,
                    )) {
                      // We launched the browser, so we don't navigate to the URL in the WebView
                      return NavigationActionPolicy.CANCEL;
                    } else {
                      // We couldn't launch the external browser, so as a fallback we're using the default action
                      return NavigationActionPolicy.ALLOW;
                    }
                  }

                  return NavigationActionPolicy.ALLOW;
                },
          );
        }

        // Return an empty widget otherwise
        return SizedBox.shrink();
      },
    );
  }

  void _updateEnableZoom() {
    var content = 'width=device-width, initial-scale=1.0';
    if (!widget.enableZoom) {
      content += ', user-scalable=no';
    }

    execute(
      '''document.querySelector('meta[name="viewport"]').setAttribute("content", "${content}");''',
    );

    _oldEnableZoom = widget.enableZoom;
  }

  void _createChatBox() {
    _oldOptions = ChatBoxOptions(
      dir: widget.dir,
      messageField: widget.messageField,
      showChatHeader: widget.showChatHeader,
      showTranslationToggle: widget.showTranslationToggle,
      theme: widget.theme,
      themeOptions: widget.themeOptions,
      translateConversations: widget.translateConversations,
    );

    // This statemement without the `true;` at the end results in a build that crashes on iOS 26.2 when built using Xcode 26.2
    // Building on Xcode 26.1.1 and running on iOS 26.2 does not result in a crash.
    execute('chatBox = session.createChatbox(${_oldOptions}); true;');

    _setMessageFilter();
    _setHighlightedWords();

    execute(
      'chatBox.onSendMessage((event) => window.flutter_inappwebview.callHandler("JSCSendMessage", JSON.stringify(event))); true;',
    );
    execute(
      'chatBox.onTranslationToggled((event) => window.flutter_inappwebview.callHandler("JSCTranslationToggled", JSON.stringify(event))); true;',
    );

    if (widget.onCustomMessageAction != null) {
      _oldCustomMessageActions = Set.of(widget.onCustomMessageAction!.keys);
      for (var action in _oldCustomMessageActions) {
        execute(
          'chatBox.onCustomMessageAction("$action", customMessageActionHandler); true;',
        );
      }
    } else {
      _oldCustomMessageActions = {};
    }

    if (widget.onCustomConversationAction != null) {
      _oldCustomConversationActions = Set.of(
        widget.onCustomConversationAction!.keys,
      );
      for (var action in _oldCustomConversationActions) {
        execute(
          'chatBox.onCustomConversationAction("$action", customConversationActionHandler); true;',
        );
      }
    } else {
      _oldCustomConversationActions = {};
    }
  }

  bool _checkRecreateChatBox() {
    final options = ChatBoxOptions(
      dir: widget.dir,
      messageField: widget.messageField,
      showChatHeader: widget.showChatHeader,
      showTranslationToggle: widget.showTranslationToggle,
      theme: widget.theme,
      translateConversations: widget.translateConversations,
    );

    if (options != _oldOptions) {
      execute('chatBox.destroy();');
      _createChatBox();

      return true;
    } else {
      return false;
    }
  }

  bool _checkMessageActionHandlers() {
    // If there are no handlers specified, then we don't need to create new handlers
    if (widget.onCustomMessageAction == null) {
      return false;
    }

    final customActions = Set.of(widget.onCustomMessageAction!.keys);

    if (!setEquals(customActions, _oldCustomMessageActions)) {
      var retval = false;

      // Register only the new event handlers
      //
      // Possible memory leak: old event handlers are not getting unregistered
      // This should not be a big problem in practice, as it is *very* rare that
      // custom message handlers are being constantly changed
      for (var action in customActions) {
        if (!_oldCustomMessageActions.contains(action)) {
          _oldCustomMessageActions.add(action);

          execute(
            'chatBox.onCustomMessageAction("$action", customMessageActionHandler); true;',
          );

          retval = true;
        }
      }
      return retval;
    } else {
      return false;
    }
  }

  bool _checkConversationActionHandlers() {
    // If there are no handlers specified, then we don't need to create new handlers
    if (widget.onCustomConversationAction == null) {
      return false;
    }

    final customActions = Set.of(widget.onCustomConversationAction!.keys);

    if (!setEquals(customActions, _oldCustomConversationActions)) {
      var retval = false;

      // Register only the new event handlers
      //
      // Possible memory leak: old event handlers are not getting unregistered
      // This should not be a big problem in practice, as it is *very* rare that
      // custom conversation handlers are being constantly changed
      for (var action in customActions) {
        if (!_oldCustomConversationActions.contains(action)) {
          _oldCustomConversationActions.add(action);

          execute(
            'chatBox.onCustomConversationAction("$action", customConversationActionHandler); true;',
          );

          retval = true;
        }
      }
      return retval;
    } else {
      return false;
    }
  }

  void _createConversation() {
    final Map<String, dynamic> result = {
      'asGuest': ?widget.asGuest,
      'messageId': ?widget.scrollToMessage,
    };

    _oldAsGuest = widget.asGuest;
    _oldScrollToMessage = widget.scrollToMessage;
    _oldConversation = widget.conversation;

    if (_oldConversation != null) {
      execute(
        'chatBox.select(${getConversationVariableName(_oldConversation!)}, ${json.encode(result)}); true;',
      );
    } else {
      if (result.isNotEmpty) {
        execute('chatBox.select(undefined, ${json.encode(result)}); true;');
      } else {
        execute('chatBox.select(undefined); true;');
      }
    }
  }

  bool _checkRecreateConversation() {
    if ((widget.asGuest != _oldAsGuest) ||
        (widget.conversation != _oldConversation) ||
        (widget.scrollToMessage != _oldScrollToMessage)) {
      _createConversation();

      return true;
    }

    return false;
  }

  void _setHighlightedWords() {
    _oldHighlightedWords = List.of(widget.highlightedWords);

    execute(
      'chatBox.setHighlightedWords(${json.encode(_oldHighlightedWords)}); true;',
    );
  }

  bool _checkHighlightedWords() {
    if (!listEquals(widget.highlightedWords, _oldHighlightedWords)) {
      _setHighlightedWords();

      return true;
    }

    return false;
  }

  void _setMessageFilter() {
    _oldMessageFilter = widget.messageFilter?.clone();

    if (_oldMessageFilter != null) {
      execute('chatBox.setMessageFilter(${json.encode(_oldMessageFilter)});');
    } else {
      execute('chatBox.setMessageFilter({});');
    }
  }

  bool _checkMessageFilter() {
    if (widget.messageFilter != _oldMessageFilter) {
      _setMessageFilter();

      return true;
    }

    return false;
  }

  void _onWebViewCreated(InAppWebViewController controller) async {
    if (kDebugMode) {
      print('📗 chatbox._onWebViewCreated');
    }

    controller.addJavaScriptHandler(
      handlerName: 'JSCSendMessage',
      callback: _jscSendMessage,
    );
    controller.addJavaScriptHandler(
      handlerName: 'JSCTranslationToggled',
      callback: _jscTranslationToggled,
    );
    controller.addJavaScriptHandler(
      handlerName: 'JSCLoadingState',
      callback: _jscLoadingState,
    );
    controller.addJavaScriptHandler(
      handlerName: 'JSCCustomMessageAction',
      callback: _jscCustomMessageAction,
    );
    controller.addJavaScriptHandler(
      handlerName: 'JSCCustomConversationAction',
      callback: _jscCustomConversationAction,
    );
    controller.addJavaScriptHandler(
      handlerName: 'JSCTokenFetcher',
      callback: _jscTokenFetcher,
    );

    String htmlData = await rootBundle.loadString(
      'packages/talkjs_flutter/assets/index.html',
    );
    controller.loadData(
      data: htmlData,
      baseUrl: WebUri("https://app.talkjs.com"),
    );
  }

  void _onLoadStop(InAppWebViewController controller, WebUri? url) async {
    if (kDebugMode) {
      print('📗 chatbox._onLoadStop ($url)');
    }

    if (_webViewController == null) {
      _webViewController = controller;

      // Execute any pending instructions
      for (var statement in _pending) {
        if (kDebugMode) {
          print('📗 chatbox._onLoadStop _pending: $statement');
        }

        controller.evaluateJavascript(source: statement);
      }
    }
  }

  void _jscSendMessage(List<dynamic> arguments) {
    final message = arguments[0];

    if (kDebugMode) {
      print('📗 chatbox._jscSendMessage: $message');
    }

    widget.onSendMessage?.call(SendMessageEvent.fromJson(json.decode(message)));
  }

  void _jscTranslationToggled(List<dynamic> arguments) {
    final message = arguments[0];

    if (kDebugMode) {
      print('📗 chatbox._jscTranslationToggled: $message');
    }

    widget.onTranslationToggled?.call(
      TranslationToggledEvent.fromJson(json.decode(message)),
    );
  }

  void _jscLoadingState(List<dynamic> arguments) {
    final message = arguments[0];

    if (kDebugMode) {
      print('📗 chatbox._jscLoadingState: $message');
    }

    widget.onLoadingStateChanged?.call(LoadingState.loaded);
  }

  void _jscCustomMessageAction(List<dynamic> arguments) {
    final message = arguments[0];

    if (kDebugMode) {
      print('📗 chatbox._jscCustomMessageAction: $message');
    }

    Map<String, dynamic> jsonMessage = json.decode(message);
    String action = jsonMessage['action'];

    widget.onCustomMessageAction?[action]?.call(
      MessageActionEvent.fromJson(jsonMessage),
    );
  }

  void _jscCustomConversationAction(List<dynamic> arguments) {
    final conversationData = arguments[0];

    if (kDebugMode) {
      print('📗 chatbox._jscCustomConversationAction: $conversationData');
    }

    Map<String, dynamic> jsonConversationData = json.decode(conversationData);
    String action = jsonConversationData['action'];

    widget.onCustomConversationAction?[action]?.call(
      ConversationActionEvent.fromJson(jsonConversationData),
    );
  }

  Future<String> _jscTokenFetcher(List<dynamic> arguments) {
    if (kDebugMode) {
      print('📗 chatbox._jscTokenFetcher');
    }

    return widget.session.tokenFetcher!();
  }

  /// For internal use only. Implementation detail that may change anytime.
  ///
  /// Return a string with a unique ID
  String getUniqueId() {
    final id = _idCounter;

    _idCounter += 1;

    return '_$id';
  }

  /// For internal use only. Implementation detail that may change anytime.
  ///
  /// Returns the JavaScript variable name of the Talk.User object associated
  /// with the given [User]
  String getUserVariableName(User user) {
    if (_users[user.id] == null) {
      // Generate unique variable name
      final variableName = 'user${getUniqueId()}';

      _users[user.id] = variableName;

      execute(
        'let $variableName = new Talk.User(${user.getJsonString()}); true;',
      );

      _userObjs[user.id] = User.of(user);
    } else if (_userObjs[user.id] != user) {
      final variableName = _users[user.id]!;

      execute('$variableName = new Talk.User(${user.getJsonString()}); true;');

      _userObjs[user.id] = User.of(user);
    }

    return _users[user.id]!;
  }

  /// For internal use only. Implementation detail that may change anytime.
  String getConversationVariableName(Conversation conversation) {
    if (_conversations[conversation.id] == null) {
      final variableName = 'conversation${getUniqueId()}';

      _conversations[conversation.id] = variableName;

      execute(
        'let $variableName = session.getOrCreateConversation("${conversation.id}"); true;',
      );

      _setConversationAttributes(variableName, conversation);
      _setConversationParticipants(variableName, conversation);

      _conversationObjs[conversation.id] = Conversation.of(conversation);
    } else if (_conversationObjs[conversation.id] != conversation) {
      final variableName = _conversations[conversation.id]!;

      _setConversationAttributes(variableName, conversation);

      if (!setEquals(
        conversation.participants,
        _conversationObjs[conversation.id]!.participants,
      )) {
        _setConversationParticipants(variableName, conversation);
      }

      _conversationObjs[conversation.id] = Conversation.of(conversation);
    }

    return _conversations[conversation.id]!;
  }

  void _setConversationAttributes(
    String variableName,
    Conversation conversation,
  ) {
    final Map<String, dynamic> attributes = {
      'custom': ?conversation.custom,
      'welcomeMessages': ?conversation.welcomeMessages,
      'photoUrl': ?conversation.photoUrl,
      'subject': ?conversation.subject,
    };

    if (attributes.isNotEmpty) {
      execute('$variableName.setAttributes(${json.encode(attributes)});');
    }
  }

  void _setConversationParticipants(
    String variableName,
    Conversation conversation,
  ) {
    for (var participant in conversation.participants) {
      final userVariableName = getUserVariableName(participant.user);
      final Map<String, dynamic> result = {
        'access': ?participant.access?.getValue(),
        'notify': ?participant.notify?.getValue(),
      };

      execute(
        '$variableName.setParticipant($userVariableName, ${json.encode(result)});',
      );
    }
  }

  /// For internal use only. Implementation detail that may change anytime.
  ///
  /// Evaluates the JavaScript statement given.
  void execute(String statement) {
    final controller = _webViewController;

    if (controller != null) {
      if (kDebugMode) {
        print('📗 chatbox.execute: $statement');
      }

      controller.evaluateJavascript(source: statement);
    } else {
      if (kDebugMode) {
        print('📘 chatbox.execute: $statement');
      }

      this._pending.add(statement);
    }
  }
}
