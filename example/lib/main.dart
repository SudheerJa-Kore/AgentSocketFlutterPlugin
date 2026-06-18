import 'package:flutter/material.dart';
import 'package:artemis_flutter_socket_sdk/abl_flutter_sdk.dart';

import 'widgets/markdown_message.dart';

enum ConnectionStatus { notConnected, connecting, connected }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize ABL SDK with configuration from assets
  final sdk = await AgentSDK.initialize();

  runApp(MyApp(sdk: sdk));
}

class MyApp extends StatelessWidget {
  final AgentSDK sdk;

  const MyApp({super.key, required this.sdk});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ABL Platform SDK Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _hexToColor(sdk.config.theme.primaryColor),
        ),
        useMaterial3: true,
      ),
      home: ChatScreen(sdk: sdk),
    );
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

class ChatScreen extends StatefulWidget {
  final AgentSDK sdk;

  const ChatScreen({super.key, required this.sdk});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  ConnectionStatus _connectionStatus = ConnectionStatus.notConnected;
  String? _sessionId;

  bool get _isConnected => _connectionStatus == ConnectionStatus.connected;
  bool get _isConnecting => _connectionStatus == ConnectionStatus.connecting;

  @override
  void initState() {
    super.initState();
    _initializeSDK();
  }

  Future<void> _initializeSDK() async {
    setState(() => _connectionStatus = ConnectionStatus.connecting);
    try {
      // Connect to platform
      _sessionId = await widget.sdk.connect();
      setState(() {
        _connectionStatus = ConnectionStatus.connected;
        _messages = widget.sdk.getMessages();
      });

      // Listen to chat events
      widget.sdk.chatEvents.listen((event) {
        if (event is MessageReceivedEvent ||
            event is MessageEndEvent ||
            event is MessageChunkEvent) {
          setState(() {
            _messages = widget.sdk.getMessages();
          });
          _scrollToBottom();
        } else if (event is ChatErrorEvent) {
          _showSnackBar('Chat error: ${event.error}');
        }
      });

      // Listen to SDK events and drive the connection status from them
      widget.sdk.events.listen((event) {
        if (event is SDKConnectedEvent) {
          setState(() {
            _connectionStatus = ConnectionStatus.connected;
            _sessionId = event.sessionId;
          });
        } else if (event is SDKReconnectingEvent) {
          setState(() {
            _connectionStatus = ConnectionStatus.connecting;
          });
        } else if (event is SDKDisconnectedEvent) {
          setState(() {
            _connectionStatus = ConnectionStatus.notConnected;
          });
          _showSnackBar('Disconnected: ${event.reason ?? "Unknown"}');
        } else if (event is SDKErrorEvent) {
          _showSnackBar('Error: ${event.error}');
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _connectionStatus = ConnectionStatus.notConnected);
      }
      _showSnackBar('Failed to initialize: $e');
    }
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
    if (_isConnecting) return;
    setState(() => _connectionStatus = ConnectionStatus.connecting);
    try {
      _sessionId = await widget.sdk.connect();
      if (!mounted) return;
      setState(() {
        _connectionStatus = ConnectionStatus.connected;
        _messages = widget.sdk.getMessages();
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      await widget.sdk.sendMessage(text);
      setState(() {
        _messages = widget.sdk.getMessages();
      });
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      _showSnackBar('Failed to send message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ABL Platform SDK Demo'),
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
          Visibility(
            visible: false,
            maintainState: true,
            child: IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showConfigInfo,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusBar(),
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : _buildMessageList(),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    final Color backgroundColor;
    final Color foregroundColor;
    final Color textColor;
    final Widget leading;
    final String label;

    switch (_connectionStatus) {
      case ConnectionStatus.connected:
        backgroundColor = Colors.green.shade100;
        foregroundColor = Colors.green.shade700;
        textColor = Colors.green.shade900;
        leading = Icon(Icons.check_circle, size: 16, color: foregroundColor);
        label = 'Connected';
        break;
      case ConnectionStatus.connecting:
        backgroundColor = Colors.blue.shade100;
        foregroundColor = Colors.blue.shade700;
        textColor = Colors.blue.shade900;
        leading = SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
          ),
        );
        label = 'Connecting…';
        break;
      case ConnectionStatus.notConnected:
        backgroundColor = Colors.orange.shade100;
        foregroundColor = Colors.orange.shade700;
        textColor = Colors.orange.shade900;
        leading = Icon(Icons.warning, size: 16, color: foregroundColor);
        label = 'Not Connected';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: backgroundColor,
      child: Row(
        children: [
          leading,
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with your AI assistant',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isUser = message.role == MessageRole.user;
    final useMarkdown =
        !isUser && widget.sdk.config.features.enableMarkdown;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(
            widget.sdk.config.theme.borderRadius,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (useMarkdown)
              MarkdownMessage(
                content: message.content,
                textColor: Colors.black87,
                linkColor: Theme.of(context).colorScheme.primary,
                codeBackgroundColor: Colors.black.withValues(alpha: 0.06),
              )
            else
              Text(
                message.content,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: isUser ? Colors.white70 : Colors.black45,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              enabled: _isConnected,
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: _isConnected ? _sendMessage : null,
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  void _showConfigInfo() {
    final config = widget.sdk.config;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('SDK Configuration'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildConfigItem('Environment', config.environment),
              _buildConfigItem('Project ID', config.connection.projectId),
              _buildConfigItem('Endpoint', config.connection.endpoint),
              _buildConfigItem(
                'Voice Enabled',
                config.features.enableVoice.toString(),
              ),
              _buildConfigItem(
                'File Upload',
                config.features.enableFileUpload.toString(),
              ),
              _buildConfigItem(
                'Debug Mode',
                config.debug.enabled.toString(),
              ),
              _buildConfigItem(
                'Log Level',
                config.debug.logLevel,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    widget.sdk.dispose();
    super.dispose();
  }
}
