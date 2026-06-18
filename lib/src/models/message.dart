/// Message model for ABL Platform
///
/// Represents a message in a chat conversation with the AI agent.
library;

enum MessageRole {
  user,
  assistant,
  system,
  thought,
}

/// Main message class
class Message {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final List<String>? attachmentIds;

  const Message({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.metadata,
    this.attachmentIds,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      role: _roleFromString(json['role'] as String),
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
      attachmentIds: (json['attachment_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': _roleToString(role),
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
      if (attachmentIds != null) 'attachment_ids': attachmentIds,
    };
  }

  static MessageRole _roleFromString(String role) {
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

  static String _roleToString(MessageRole role) {
    switch (role) {
      case MessageRole.user:
        return 'user';
      case MessageRole.assistant:
        return 'assistant';
      case MessageRole.system:
        return 'system';
      case MessageRole.thought:
        return 'thought';
    }
  }

  Message copyWith({
    String? id,
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    List<String>? attachmentIds,
  }) {
    return Message(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      attachmentIds: attachmentIds ?? this.attachmentIds,
    );
  }

  @override
  String toString() {
    return 'Message(id: $id, role: $role, content: ${content.substring(0, content.length > 50 ? 50 : content.length)}...)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// SDK User Context
class SDKUserContext {
  final String? userId;
  final Map<String, dynamic>? customAttributes;

  const SDKUserContext({
    this.userId,
    this.customAttributes,
  });

  Map<String, dynamic> toJson() {
    return {
      if (userId != null) 'user_id': userId,
      if (customAttributes != null) 'custom_attributes': customAttributes,
    };
  }

  factory SDKUserContext.fromJson(Map<String, dynamic> json) {
    return SDKUserContext(
      userId: json['user_id'] as String?,
      customAttributes: json['custom_attributes'] as Map<String, dynamic>?,
    );
  }
}
