import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

import 'package:talkjs_webview_flutter/webview_flutter.dart';

import './session.dart';
import './conversation.dart';
import './chatoptions.dart';
import './user.dart';
import './message.dart';
import './predicate.dart';
import './notification.dart';

typedef SendMessageHandler = void Function(SendMessageEvent event);
typedef TranslationToggledHandler = void Function(TranslationToggledEvent event);
typedef LoadingStateHandler = void Function(LoadingState state);
typedef MessageActionHandler = void Function(MessageActionEvent event);

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
  final TranslateConversations? translateConversations;
  final List<String> highlightedWords = const <String>[];
  final MessagePredicate messageFilter;

  final Conversation? conversation;
  final bool? asGuest;

  final SendMessageHandler? onSendMessage;
  final TranslationToggledHandler? onTranslationToggled;
  final LoadingStateHandler? onLoadingStateChanged;
  final Map<String, MessageActionHandler>? onCustomMessageAction;

  const ChatBox({
    Key? key,
    required this.session,
    this.dir,
    this.messageField,
    this.showChatHeader,
    this.showTranslationToggle,
    this.theme,
    this.translateConversations,
    //this.highlightedWords = const <String>[], // Commented out due to bug #1953
    this.messageFilter = const MessagePredicate(),
    this.conversation,
    this.asGuest,
    this.onSendMessage,
    this.onTranslationToggled,
    this.onLoadingStateChanged,
    this.onCustomMessageAction,
  }) : super(key: key);

  @override
  State<ChatBox> createState() => ChatBoxState();
}

class ChatBoxState extends State<ChatBox> {
  /// Used to control the underlying WebView
  WebViewController? _webViewController;
  bool _webViewCreated = false;

  /// List of JavaScript statements that haven't been executed.
  final _pending = <String>[];

  // A counter to ensure that IDs are unique
  int _idCounter = 0;

  /// A mapping of user ids to the variable name of the respective JavaScript
  /// Talk.User object.
  final _users = <String, String>{};
  final _userObjs = <String, User>{};

  /// A mapping of conversation ids to the variable name of the respective JavaScript
  /// Talk.ConversationBuilder object.
  final _conversations = <String, String>{};
  final _conversationObjs = <String, Conversation>{};

  /// Encapsulates the message entry field tied to the currently selected conversation.
  // TODO: messageField still needs to be refactored
  //late MessageField messageField;

  /// Objects stored for comparing changes
  ChatBoxOptions? _oldOptions;
  List<String> _oldHighlightedWords = [];
  MessagePredicate _oldMessageFilter = const MessagePredicate();
  bool? _oldAsGuest;
  Conversation? _oldConversation;
  Set<String> _oldCustomActions = {};

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('📗 chatbox.build (_webViewCreated: $_webViewCreated)');
    }

    if (!_webViewCreated) {
      // If it's the first time that the widget is built, then build everything
      _webViewCreated = true;

      // Here a Timer is needed, as we can't change the widget's state while the widget
      // is being constructed, and the callback may very possibly change the state
      Timer.run(() => widget.onLoadingStateChanged?.call(LoadingState.loading));

      execute('let chatBox;');
      execute('''
        function customMessageActionHandler(event) {
          JSCCustomMessageAction.postMessage(JSON.stringify(event));
        }
      ''');

      _createSession();
      _createChatBox();
      // messageFilter and highlightedWords are set as options for the chatbox
      _createConversation();

      execute('chatBox.mount(document.getElementById("talkjs-container")).then(() => JSCLoadingState.postMessage("loaded"));');
    } else {
      // If it's not the first time that the widget is built,
      // then check what needs to be rebuilt

      // TODO: If something has changed in the Session we should do something

      final chatBoxRecreated = _checkRecreateChatBox();

      if (chatBoxRecreated) {
      // messageFilter and highlightedWords are set as options for the chatbox
        _createConversation();
      } else {
        _checkActionHandlers();
        _checkMessageFilter();
        _checkHighlightedWords();
        _checkRecreateConversation();
      }

      // Mount the chatbox only if it's new (else the existing chatbox has already been mounted)
      if (chatBoxRecreated) {
        execute('chatBox.mount(document.getElementById("talkjs-container"));');
      }
    }

    return WebView(
      initialUrl: 'about:blank',
      javascriptMode: JavascriptMode.unrestricted,
      debuggingEnabled: kDebugMode,
      onWebViewCreated: _webViewCreatedCallback,
      onPageFinished: _onPageFinished,
      javascriptChannels: <JavascriptChannel>{
        JavascriptChannel(name: 'JSCSendMessage', onMessageReceived: _jscSendMessage),
        JavascriptChannel(name: 'JSCTranslationToggled', onMessageReceived: _jscTranslationToggled),
        JavascriptChannel(name: 'JSCLoadingState', onMessageReceived: _jscLoadingState),
        JavascriptChannel(name: 'JSCCustomMessageAction', onMessageReceived: _jscCustomMessageAction),
      },
      gestureRecognizers: {
        // We need only the VerticalDragGestureRecognizer in order to be able to scroll through the messages
        Factory(() => VerticalDragGestureRecognizer()),
      },
    );
  }

  void _createSession() {
    // Initialize Session object
    final options = <String, dynamic>{};

    options['appId'] = widget.session.appId;

    if (widget.session.signature != null) {
      options["signature"] = widget.session.signature;
    }

    execute('const options = ${json.encode(options)};');

    final variableName = getUserVariableName(widget.session.me);
    execute('options["me"] = $variableName;');

    execute('const session = new Talk.Session(options);');

    // TODO: This part has to be moved in the Session once we have the data layer SDK ready
    if (widget.session.enablePushNotifications) {
      if (fcmToken != null) {
        execute('session.setPushRegistration({provider: "fcm", pushRegistrationId: "$fcmToken"});');
      }

      if (apnsToken != null) {
        execute('session.setPushRegistration({provider: "apns", pushRegistrationId: "$apnsToken"});');
      }
    } else {
      if (fcmToken != null) {
        execute('session.unsetPushRegistration({provider: "fcm", pushRegistrationId: "$fcmToken"});');
      }

      if (apnsToken != null) {
        execute('session.unsetPushRegistration({provider: "apns", pushRegistrationId: "$apnsToken"});');
      }
    }
  }

  void _createChatBox() {
    _oldOptions = ChatBoxOptions(
      dir: widget.dir,
      messageField: widget.messageField,
      showChatHeader: widget.showChatHeader,
      showTranslationToggle: widget.showTranslationToggle,
      theme: widget.theme,
      translateConversations: widget.translateConversations,
    );

    _oldHighlightedWords = List<String>.of(widget.highlightedWords);
    _oldMessageFilter = MessagePredicate.of(widget.messageFilter);

    execute('chatBox = session.createChatbox(${_oldOptions!.getJsonString(this)});');

    execute('chatBox.onSendMessage((event) => JSCSendMessage.postMessage(JSON.stringify(event)));');
    execute('chatBox.onTranslationToggled((event) => JSCTranslationToggled.postMessage(JSON.stringify(event)));');

    if (widget.onCustomMessageAction != null) {
      _oldCustomActions = Set<String>.of(widget.onCustomMessageAction!.keys);
      for (var action in _oldCustomActions) {
        execute('chatBox.onCustomMessageAction("$action", customMessageActionHandler);');
      }
    } else {
      _oldCustomActions = {};
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

  bool _checkActionHandlers() {
    // If there are no handlers specified, then we don't need to create new handlers
    if (widget.onCustomMessageAction == null) {
      return false;
    }

    var customActions = Set<String>.of(widget.onCustomMessageAction!.keys);

    if (!setEquals(customActions, _oldCustomActions)) {
      var retval = false;

      // Register only the new event handlers
      //
      // Possible memory leak: old event handlers are not getting unregistered
      // This should not be a big problem in practice, as it is *very* rare that
      // custom message handlers are being constantly changed
      for (var action in customActions) {
        if (!_oldCustomActions.contains(action)) {
          _oldCustomActions.add(action);

          execute('chatBox.onCustomMessageAction("$action", customMessageActionHandler);');

          retval = true;
        }
      }

      return retval;
    } else {
      return false;
    }
  }

  void _createConversation() {
      final result = <String, dynamic>{};

      _oldAsGuest = widget.asGuest;
      if (_oldAsGuest != null) {
        result['asGuest'] = _oldAsGuest;
      }

      _oldConversation = widget.conversation;
      if (_oldConversation != null) {
        execute('chatBox.select(${getConversationVariableName(_oldConversation!)}, ${json.encode(result)});');
      } else {
        if (result.isNotEmpty) {
          execute('chatBox.select(undefined, ${json.encode(result)});');
        } else {
          execute('chatBox.select(undefined);');
        }
      }
  }

  bool _checkRecreateConversation() {
    if ((widget.asGuest != _oldAsGuest) || (widget.conversation != _oldConversation)) {
      _createConversation();

      return true;
    }

    return false;
  }

  void _setHighlightedWords() {
      _oldHighlightedWords = List<String>.of(widget.highlightedWords);

      execute('chatBox.setHighlightedWords(${json.encode(_oldHighlightedWords)});');
  }

  bool _checkHighlightedWords() {
    if (!listEquals(widget.highlightedWords, _oldHighlightedWords)) {
      _setHighlightedWords();

      return true;
    }

    return false;
  }

  void _setMessageFilter() {
      _oldMessageFilter = MessagePredicate.of(widget.messageFilter);

      execute('chatBox.setMessageFilter(${json.encode(_oldMessageFilter)});');
  }

  bool _checkMessageFilter() {
    if (widget.messageFilter != _oldMessageFilter) {
      _setMessageFilter();

      return true;
    }

    return false;
  }

  void _webViewCreatedCallback(WebViewController webViewController) async {
    if (kDebugMode) {
      print('📗 chatbox._webViewCreatedCallback');
    }

    String htmlData = await rootBundle.loadString('packages/talkjs_flutter/assets/index.html');
    Uri uri = Uri.dataFromString(htmlData, mimeType: 'text/html', encoding: Encoding.getByName('utf-8'));
    webViewController.loadUrl(uri.toString());

    _webViewController = webViewController;
  }

  void _onPageFinished(String url) {
    if (kDebugMode) {
      print('📗 chatbox._onPageFinished');
    }

    if (url != 'about:blank') {
      // Wait for TalkJS to be ready
      // Not all WebViews support top level await, so it's better to use an
      // async IIFE
      final js = '(async function () { await Talk.ready; }());';

      if (kDebugMode) {
        print('📗 chatbox._onPageFinished: $js');
      }

      _webViewController!.runJavascript(js);

      // Execute any pending instructions
      for (var statement in _pending) {
        if (kDebugMode) {
          print('📗 chatbox._onPageFinished _pending: $statement');
        }

        _webViewController!.runJavascript(statement);
      }
    }
  }

  void _jscSendMessage(JavascriptMessage message) {
    if (kDebugMode) {
      print('📗 chatbox._jscSendMessage: ${message.message}');
    }

    widget.onSendMessage?.call(SendMessageEvent.fromJson(json.decode(message.message)));
  }

  void _jscTranslationToggled(JavascriptMessage message) {
    if (kDebugMode) {
      print('📗 chatbox._jscTranslationToggled: ${message.message}');
    }

    widget.onTranslationToggled?.call(TranslationToggledEvent.fromJson(json.decode(message.message)));
  }

  void _jscLoadingState(JavascriptMessage message) {
    if (kDebugMode) {
      print('📗 chatbox._jscLoadingState: ${message.message}');
    }

    widget.onLoadingStateChanged?.call(LoadingState.loaded);
  }

  void _jscCustomMessageAction(JavascriptMessage message) {
    if (kDebugMode) {
      print('📗 chatbox._jscCustomMessageAction: ${message.message}');
    }

    Map<String, dynamic> jsonMessage = json.decode(message.message);
    String action = jsonMessage['action'];

    widget.onCustomMessageAction?[action]?.call(MessageActionEvent.fromJson(jsonMessage));
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

      execute('let $variableName = new Talk.User(${user.getJsonString()});');

      _userObjs[user.id] = User.of(user);
    } else if (_userObjs[user.id] != user) {
      final variableName = _users[user.id]!;

      execute('$variableName = new Talk.User(${user.getJsonString()});');

      _userObjs[user.id] = User.of(user);
    }

    return _users[user.id]!;
  }

  /// For internal use only. Implementation detail that may change anytime.
  String getConversationVariableName(Conversation conversation) {
    if (_conversations[conversation.id] == null) {
      final variableName = 'conversation${getUniqueId()}';

      _conversations[conversation.id] = variableName;

      execute('let $variableName = session.getOrCreateConversation("${conversation.id}")');

      _setConversationAttributes(variableName, conversation);
      _setConversationParticipants(variableName, conversation);

      _conversationObjs[conversation.id] = Conversation.of(conversation);
    } else if (_conversationObjs[conversation.id] != conversation) {
      final variableName = _conversations[conversation.id]!;

      _setConversationAttributes(variableName, conversation);

      if (!setEquals(conversation.participants, _conversationObjs[conversation.id]!.participants)) {
        _setConversationParticipants(variableName, conversation);
      }

      _conversationObjs[conversation.id] = Conversation.of(conversation);
    }

    return _conversations[conversation.id]!;
  }

  void _setConversationAttributes(String variableName, Conversation conversation) {
    final attributes = <String, dynamic>{};

    if (conversation.custom != null) {
      attributes['custom'] = conversation.custom;
    }

    if (conversation.welcomeMessages != null) {
      attributes['welcomeMessages'] = conversation.welcomeMessages;
    }

    if (conversation.photoUrl != null) {
      attributes['photoUrl'] = conversation.photoUrl;
    }

    if (conversation.subject != null) {
      attributes['subject'] = conversation.subject;
    }

    if (attributes.isNotEmpty) {
      execute('$variableName.setAttributes(${json.encode(attributes)});');
    }
  }

  void _setConversationParticipants(String variableName, Conversation conversation) {
    for (var participant in conversation.participants) {
      final userVariableName = getUserVariableName(participant.user);
      final result = <String, dynamic>{};

      if (participant.access != null) {
        result['access'] = participant.access!.getValue();
      }

      if (participant.notify != null) {
        result['notify'] = participant.notify;
      }

      execute('$variableName.setParticipant($userVariableName, ${json.encode(result)});');
    }
  }

  /// For internal use only. Implementation detail that may change anytime.
  ///
  /// Sets the options for ChatBoxOptions for the properties where there exists
  /// both a declarative option and an imperative method
  void setExtraOptions(Map<String, dynamic> result) {
    result['highlightedWords'] = widget.highlightedWords;
    result['messageFilter'] = widget.messageFilter;
  }

  /// For internal use only. Implementation detail that may change anytime.
  ///
  /// Evaluates the JavaScript statement given.
  void execute(String statement) {
    final controller = _webViewController;

    if (kDebugMode) {
      print('📘 chatbox.execute: $statement');
    }

    if (controller != null) {
      controller.runJavascript(statement);
    } else {
      this._pending.add(statement);
    }
  }
}

