import 'dart:async';

import '../config/sdk_configuration.dart';
import '../events/chat_events.dart';
import '../models/message.dart';
import '../utils/logger.dart';
import '../core/session_manager.dart';
import '../transport/transport_types.dart';

/// Chat client backed by the WebSocket session transport.
class ChatClient {
  final SessionManager _sessionManager;
  final SDKConfiguration _config;

  final List<Message> _messages = [];
  final Set<String> _messageIds = {};
  final StreamController<ChatEvent> _eventController =
      StreamController<ChatEvent>.broadcast();

  StreamSubscription<TransportServerMessage>? _messageSubscription;
  bool _isTyping = false;
  final Map<String, StringBuffer> _streamingBuffers = {};

  ChatClient({
    required SessionManager sessionManager,
    required SDKConfiguration config,
  })  : _sessionManager = sessionManager,
        _config = config {
    _messageSubscription = _sessionManager.messages.listen(_handleServerMessage);
  }

  Stream<ChatEvent> get events => _eventController.stream;

  bool get isTyping => _isTyping;

  Future<String> send(
    String text, {
    Map<String, dynamic>? metadata,
    List<String>? attachmentIds,
  }) async {
    if (!_sessionManager.isConnected()) {
      throw StateError('Not connected to the platform');
    }

    final messageId = _generateId();
    final userMessage = Message(
      id: messageId,
      role: MessageRole.user,
      content: text,
      timestamp: DateTime.now(),
      metadata: metadata,
      attachmentIds: attachmentIds,
    );

    _addMessage(userMessage);
    _eventController.add(MessageReceivedEvent(userMessage));

    _sessionManager.send(
      ChatMessageTransport(
        text: text,
        messageId: messageId,
        sessionId: _sessionManager.getSessionId(),
        attachmentIds: attachmentIds,
        metadata: metadata,
      ),
    );

    ABLLogger.debug('Sent chat message', {
      'id': messageId,
      'content': text,
    });

    return messageId;
  }

  List<Message> getMessages() => List.unmodifiable(_messages);

  void clearMessages() {
    _messages.clear();
    _messageIds.clear();
    _streamingBuffers.clear();
  }

  Future<void> dispose() async {
    await _messageSubscription?.cancel();
    await _eventController.close();
    _messages.clear();
    _messageIds.clear();
    _streamingBuffers.clear();
  }

  void _handleServerMessage(TransportServerMessage message) {
    switch (message.type) {
      case 'response_start':
        _isTyping = true;
        if (_config.chat.enableTypingIndicator) {
          _eventController.add(TypingIndicatorEvent(true));
        }
        final startMessageId = message.raw['messageId'] as String? ?? '';
        if (startMessageId.isNotEmpty) {
          _streamingBuffers[startMessageId] = StringBuffer();
          _upsertStreamingMessage(
            Message(
              id: startMessageId,
              role: MessageRole.assistant,
              content: '',
              timestamp: DateTime.now(),
            ),
          );
          _eventController.add(MessageStartEvent(startMessageId));
        }
        break;

      case 'response_chunk':
        final chunkMessageId = message.raw['messageId'] as String? ?? '';
        final chunk = (message.raw['chunk'] as String?) ?? '';
        if (chunkMessageId.isEmpty || chunk.isEmpty) {
          break;
        }

        final buffer = _streamingBuffers.putIfAbsent(
          chunkMessageId,
          StringBuffer.new,
        );
        buffer.write(chunk);
        _upsertStreamingMessage(
          Message(
            id: chunkMessageId,
            role: MessageRole.assistant,
            content: buffer.toString(),
            timestamp: DateTime.now(),
          ),
        );
        _eventController.add(MessageChunkEvent(chunkMessageId, chunk));
        break;

      case 'response_end':
        _isTyping = false;
        if (_config.chat.enableTypingIndicator) {
          _eventController.add(TypingIndicatorEvent(false));
        }

        final endMessageId = message.raw['messageId'] as String? ?? _generateId();
        final envelope = message.raw['contentEnvelope'];
        final envelopeText = envelope is Map<String, dynamic>
            ? envelope['text'] as String?
            : null;
        final content = (message.raw['fullText'] as String?) ??
            (message.raw['text'] as String?) ??
            envelopeText ??
            _streamingBuffers.remove(endMessageId)?.toString() ??
            '';

        if (content.trim().isEmpty) {
          _eventController.add(
            ChatErrorEvent(
              StateError('Received empty assistant response'),
            ),
          );
          break;
        }

        final assistantMessage = Message(
          id: endMessageId,
          role: MessageRole.assistant,
          content: content,
          timestamp: DateTime.now(),
          metadata: message.raw['metadata'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(message.raw['metadata'] as Map)
              : null,
        );

        _streamingBuffers.remove(endMessageId);
        _addMessage(assistantMessage);
        _eventController.add(MessageEndEvent(endMessageId, assistantMessage));
        _eventController.add(MessageReceivedEvent(assistantMessage));
        break;

      case 'thought':
        if (!_config.chat.enableThoughts) {
          break;
        }
        final thoughtContent = (message.raw['thought'] as String?) ??
            (message.raw['content'] as String?) ??
            '';
        if (thoughtContent.isEmpty) {
          break;
        }
        _eventController.add(ThoughtEvent(thoughtContent));
        break;

      case 'error':
        final errorContent = (message.raw['content'] as String?) ?? 'Unknown error';
        _eventController.add(ChatErrorEvent(StateError(errorContent)));
        break;

      case 'status_update':
        if (_config.chat.enableTypingIndicator) {
          _eventController.add(TypingIndicatorEvent(true));
        }
        break;

      case 'status_clear':
        if (_config.chat.enableTypingIndicator) {
          _eventController.add(TypingIndicatorEvent(false));
        }
        break;
    }
  }

  void _addMessage(Message message) {
    if (_messageIds.contains(message.id)) {
      final index = _messages.indexWhere((item) => item.id == message.id);
      if (index >= 0) {
        _messages[index] = message;
      }
      return;
    }

    _messageIds.add(message.id);
    _messages.add(message);

    final maxMessages = _config.chat.maxMessagesLocal;
    if (_messages.length > maxMessages) {
      final overflow = _messages.length - maxMessages;
      for (var i = 0; i < overflow; i++) {
        _messageIds.remove(_messages[i].id);
      }
      _messages.removeRange(0, overflow);
    }
  }

  void _upsertStreamingMessage(Message message) {
    _addMessage(message);
    _eventController.add(MessageReceivedEvent(message));
  }

  String _generateId() {
    return 'msg_${DateTime.now().microsecondsSinceEpoch}';
  }
}
