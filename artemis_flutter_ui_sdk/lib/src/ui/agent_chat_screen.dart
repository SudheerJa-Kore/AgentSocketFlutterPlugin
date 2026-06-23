import 'dart:async';

import 'package:artemis_flutter_socket_sdk/artemis_flutter_socket_sdk.dart'
    hide SDKConfigurationLoader;
import 'package:flutter/material.dart';

import '../config/sdk_configuration_loader.dart';
import 'connection_status.dart';
import 'theme/color_utils.dart';
import 'widgets/chat_empty_state.dart';
import 'widgets/chat_input_area.dart';
import 'widgets/chat_status_bar.dart';
import 'widgets/message_bubble.dart';
import 'widgets/typing_indicator_bubble.dart';

/// Full-screen chat UI with connection management, message list, and input.
///
/// Prefer [AgentChatUI.open] instead of using this widget directly.
class AgentChatScreen extends StatefulWidget {
  final SDKConfiguration? configuration;
  final String? environment;
  final String? configAssetPath;
  final SDKUserContext? runtimeUserContext;
  final String title;

  const AgentChatScreen({
    super.key,
    this.configuration,
    this.environment,
    this.configAssetPath,
    this.runtimeUserContext,
    this.title = 'Chat',
  });

  @override
  State<AgentChatScreen> createState() => _AgentChatScreenState();
}

class _AgentChatScreenState extends State<AgentChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  AgentSDK? _sdk;
  List<Message> _messages = [];
  ConnectionStatus _connectionStatus = ConnectionStatus.notConnected;
  String? _initError;
  bool _isAssistantTyping = false;

  StreamSubscription<ChatEvent>? _chatSubscription;
  StreamSubscription<SDKEvent>? _sdkSubscription;

  bool get _isConnected => _connectionStatus == ConnectionStatus.connected;
  bool get _isConnecting => _connectionStatus == ConnectionStatus.connecting;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _connectionStatus = ConnectionStatus.connecting;
      _initError = null;
    });

    try {
      final SDKConfiguration config;
      if (widget.configuration != null) {
        config = widget.configuration!;
      } else {
        config = await SDKConfigurationLoader.load(
          environment: widget.environment,
          customPath: widget.configAssetPath,
        );
      }

      var sdk = AgentSDK.createWithConfig(config);
      if (widget.runtimeUserContext != null) {
        sdk = AgentSDK.createWithConfig(
          config.copyWithUserContext(widget.runtimeUserContext!),
        );
      }

      _sdk = sdk;
      _attachListeners(sdk);
      await sdk.connect();

      if (!mounted) return;
      setState(() {
        _connectionStatus = ConnectionStatus.connected;
        _messages = sdk.getMessages();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _connectionStatus = ConnectionStatus.notConnected;
        _initError = e.toString();
      });
      _showSnackBar('Failed to connect: $e');
    }
  }

  void _attachListeners(AgentSDK sdk) {
    _chatSubscription = sdk.chatEvents.listen((event) {
      if (!mounted) return;
      if (event is MessageReceivedEvent) {
        _onAssistantResponse(sdk, dismissTyping: event.message.role == MessageRole.assistant);
      } else if (event is MessageEndEvent ||
          event is MessageChunkEvent ||
          event is MessageStartEvent) {
        _onAssistantResponse(sdk);
      } else if (event is TypingIndicatorEvent) {
        setState(() => _isAssistantTyping = event.isTyping);
        if (event.isTyping) _scrollToBottom();
      } else if (event is ChatErrorEvent) {
        setState(() => _isAssistantTyping = false);
        _showSnackBar('Chat error: ${event.error}');
      }
    });

    _sdkSubscription = sdk.events.listen((event) {
      if (!mounted) return;
      if (event is SDKConnectedEvent) {
        setState(() => _connectionStatus = ConnectionStatus.connected);
      } else if (event is SDKReconnectingEvent) {
        setState(() => _connectionStatus = ConnectionStatus.connecting);
      } else if (event is SDKDisconnectedEvent) {
        setState(() => _connectionStatus = ConnectionStatus.notConnected);
        _showSnackBar('Disconnected: ${event.reason ?? "Unknown"}');
      } else if (event is SDKErrorEvent) {
        _showSnackBar('Error: ${event.error}');
      }
    });
  }

  void _onAssistantResponse(AgentSDK sdk, {bool dismissTyping = true}) {
    setState(() {
      _messages = sdk.getMessages();
      if (dismissTyping) _isAssistantTyping = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _reconnect() async {
    final sdk = _sdk;
    if (sdk == null || _isConnecting) return;

    setState(() => _connectionStatus = ConnectionStatus.connecting);
    try {
      await sdk.connect();
      if (!mounted) return;
      setState(() {
        _connectionStatus = ConnectionStatus.connected;
        _messages = sdk.getMessages();
      });
      _showSnackBar('Reconnected');
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _connectionStatus = ConnectionStatus.notConnected);
      _showSnackBar('Reconnect failed: $e');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _sendMessage() async {
    final sdk = _sdk;
    if (sdk == null) return;

    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      await sdk.sendMessage(text);
      setState(() {
        _messages = sdk.getMessages();
        _isAssistantTyping = true;
      });
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      _showSnackBar('Failed to send message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sdk = _sdk;
    final themeConfig = sdk?.config.theme;

    return Theme(
      data: themeConfig != null
          ? Theme.of(context).copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: colorFromHex(themeConfig.primaryColor),
              ),
            )
          : Theme.of(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.15,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              tooltip: 'Reconnect',
              icon: _isConnecting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              onPressed: _isConnecting ? null : _reconnect,
            ),
          ],
        ),
        body: Column(
          children: [
            ChatStatusBar(status: _connectionStatus),
            if (_initError != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _initError!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                ),
              ),
            Expanded(
              child: _messages.isEmpty && !_isAssistantTyping
                  ? const ChatEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length + (_isAssistantTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length) {
                          return TypingIndicatorBubble(theme: sdk!.config.theme);
                        }
                        return MessageBubble(
                          message: _messages[index],
                          theme: sdk!.config.theme,
                          enableMarkdown: sdk.config.features.enableMarkdown,
                          enableCarousel: sdk.config.features.enableCarousel,
                        );
                      },
                    ),
            ),
            ChatInputArea(
              controller: _messageController,
              enabled: _isConnected,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    _sdkSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _sdk?.dispose();
    super.dispose();
  }
}
