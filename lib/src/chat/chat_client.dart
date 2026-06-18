import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

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

  Future<void>? _historyHydrationFuture;
  String? _historyHydrationSessionId;
  int _historyHydrationGeneration = 0;

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

    ArtemisLogger.debug('Sent chat message', {
      'id': messageId,
      'content': text,
    });

    return messageId;
  }

  List<Message> getMessages() => List.unmodifiable(_messages);

  /// Fetch persisted chat history for the active session and merge it into the
  /// local message store.
  ///
  /// This is invoked automatically on every (re)connect, mirroring the web SDK.
  /// Concurrent calls for the same session are de-duplicated. Failures are
  /// swallowed (logged at debug level) so a missing history endpoint never
  /// breaks an otherwise healthy live session.
  Future<void> hydratePersistedHistory() {
    final sessionId = _resolveHistorySessionId();
    if (sessionId == null || sessionId.isEmpty) {
      ArtemisLogger.debug(
        'Persisted history hydration skipped: no active session',
      );
      return Future<void>.value();
    }

    final inflight = _historyHydrationFuture;
    if (inflight != null && _historyHydrationSessionId == sessionId) {
      ArtemisLogger.debug('Persisted history hydration already in progress', {
        'session_id': sessionId,
      });
      return inflight;
    }

    ArtemisLogger.info('Hydrating persisted history', {
      'session_id': sessionId,
    });

    final generation = _historyHydrationGeneration;
    _historyHydrationSessionId = sessionId;
    final future = _fetchPersistedHistory(sessionId).then((messages) {
      if (generation != _historyHydrationGeneration ||
          sessionId != _resolveHistorySessionId()) {
        ArtemisLogger.debug('Persisted history hydration result discarded', {
          'session_id': sessionId,
        });
        return;
      }
      ArtemisLogger.info('Persisted history fetched', {
        'session_id': sessionId,
        'fetched': messages.length,
      });
      _mergeHydratedMessages(messages);
    }).catchError((Object error) {
      ArtemisLogger.warning('Persisted history hydration skipped', {
        'session_id': sessionId,
        'error': error.toString(),
      });
    }).whenComplete(() {
      if (generation == _historyHydrationGeneration) {
        _historyHydrationFuture = null;
        _historyHydrationSessionId = null;
      }
    });

    _historyHydrationFuture = future;
    return future;
  }

  void clearMessages() {
    _historyHydrationGeneration++;
    _historyHydrationFuture = null;
    _historyHydrationSessionId = null;
    _messages.clear();
    _messageIds.clear();
    _streamingBuffers.clear();
  }

  Future<void> dispose() async {
    _historyHydrationGeneration++;
    _historyHydrationFuture = null;
    _historyHydrationSessionId = null;
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

  String? _resolveHistorySessionId() => _sessionManager.getSessionId();

  Uri _buildHistoryUri(
    String sessionId, {
    String? cursor,
    required int limit,
  }) {
    final base = Uri.parse(_sessionManager.getEndpoint());
    final projectId = _sessionManager.getProjectId();
    return base.replace(
      path: '/api/projects/${Uri.encodeComponent(projectId)}'
          '/sessions/${Uri.encodeComponent(sessionId)}/messages',
      queryParameters: {
        'direction': 'asc',
        'limit': '$limit',
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );
  }

  Future<List<Message>> _fetchPersistedHistory(String sessionId) async {
    final authToken = await _sessionManager.getAuthToken();
    final perPage = _config.chat.historyPageSize;
    final maxPages = _config.chat.maxHistoryPages;
    final hydrated = <Message>[];
    String? cursor;

    for (var page = 0; page < maxPages; page++) {
      final uri = _buildHistoryUri(sessionId, cursor: cursor, limit: perPage);
      ArtemisLogger.debug('Fetching history page', {
        'page': page,
        'url': uri.toString(),
      });

      final response = await http.get(
        uri,
        headers: {'X-SDK-Token': authToken},
      );

      ArtemisLogger.debug('History page response', {
        'page': page,
        'status': response.statusCode,
      });

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('History request failed: ${response.statusCode}');
      }

      final parsed = _parsePersistedHistoryPage(jsonDecode(response.body));
      hydrated.addAll(parsed.messages);

      if (!parsed.hasMore || parsed.nextCursor == null) {
        break;
      }
      cursor = parsed.nextCursor;
    }

    return hydrated;
  }

  _PersistedHistoryPage _parsePersistedHistoryPage(dynamic body) {
    if (body is! Map<String, dynamic> || body['messages'] is! List) {
      return const _PersistedHistoryPage(
        messages: [],
        nextCursor: null,
        hasMore: false,
      );
    }

    final messages = <Message>[];
    for (final raw in body['messages'] as List) {
      final parsed = _parsePersistedHistoryMessage(raw);
      if (parsed != null) {
        messages.add(parsed);
      }
    }

    return _PersistedHistoryPage(
      messages: messages,
      nextCursor: body['nextCursor'] is String ? body['nextCursor'] as String : null,
      hasMore: body['hasMore'] == true,
    );
  }

  Message? _parsePersistedHistoryMessage(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      return null;
    }

    final id = raw['id'];
    final role = raw['role'];
    if (id is! String || role is! String) {
      return null;
    }

    final envelope = raw['contentEnvelope'];
    final envelopeText =
        envelope is Map<String, dynamic> ? envelope['text'] as String? : null;
    final rawContent = raw['content'];
    final content = (rawContent is String && rawContent.trim().isNotEmpty)
        ? rawContent
        : (envelopeText ?? '');

    final rawTimestamp = raw['timestamp'];
    final timestamp = rawTimestamp is String
        ? (DateTime.tryParse(rawTimestamp) ?? DateTime.now())
        : DateTime.now();

    return Message(
      id: id,
      role: _roleFromString(role),
      content: content,
      timestamp: timestamp,
      metadata: raw['metadata'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(raw['metadata'] as Map)
          : null,
    );
  }

  void _mergeHydratedMessages(List<Message> messages) {
    if (messages.isEmpty) {
      return;
    }

    final existingIds = _messages.map((message) => message.id).toSet();
    final existingFingerprints = _messages.map(_fingerprint).toSet();
    final newMessages = <Message>[];

    for (final message in messages) {
      if (existingIds.contains(message.id)) {
        continue;
      }
      final fingerprint = _fingerprint(message);
      if (existingFingerprints.contains(fingerprint)) {
        continue;
      }
      existingIds.add(message.id);
      existingFingerprints.add(fingerprint);
      newMessages.add(message);
    }

    if (newMessages.isEmpty) {
      ArtemisLogger.debug('Persisted history merge: no new messages');
      return;
    }

    ArtemisLogger.info('Merging persisted history', {
      'new_messages': newMessages.length,
    });

    _messages.addAll(newMessages);
    _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final maxMessages = _config.chat.maxMessagesLocal;
    if (_messages.length > maxMessages) {
      _messages.removeRange(0, _messages.length - maxMessages);
    }

    _messageIds
      ..clear()
      ..addAll(_messages.map((message) => message.id));

    _eventController.add(HistoryLoadedEvent(getMessages()));
  }

  String _fingerprint(Message message) =>
      '${message.role}|${message.content}|${message.timestamp.toIso8601String()}';

  MessageRole _roleFromString(String role) {
    switch (role.toLowerCase()) {
      case 'user':
        return MessageRole.user;
      case 'assistant':
        return MessageRole.assistant;
      case 'system':
        return MessageRole.system;
      case 'thought':
        return MessageRole.thought;
      default:
        return MessageRole.assistant;
    }
  }
}

class _PersistedHistoryPage {
  final List<Message> messages;
  final String? nextCursor;
  final bool hasMore;

  const _PersistedHistoryPage({
    required this.messages,
    required this.nextCursor,
    required this.hasMore,
  });
}
