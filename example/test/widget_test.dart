import 'package:flutter_test/flutter_test.dart';
import 'package:artemis_flutter_socket_sdk/artemis_flutter_socket_sdk.dart';

void main() {
  test('SDK configuration loading test', () async {
    // Create a test SDK configuration
    final testConfig = SDKConfigurationLoader.createDefault(
      projectId: 'test-project',
      endpoint: 'http://localhost:3112',
      apiKey: 'pk_test_key',
    );

    // Verify configuration
    expect(testConfig, isNotNull);
    expect(testConfig.connection.projectId, equals('test-project'));
    expect(testConfig.connection.endpoint, equals('http://localhost:3112'));
    expect(testConfig.connection.apiKey, equals('pk_test_key'));
    expect(testConfig.environment, equals('dev'));
    expect(testConfig.debug.enabled, isTrue);

    // Create SDK with configuration
    final sdk = AgentSDK.createWithConfig(testConfig);
    expect(sdk, isNotNull);
    expect(sdk.config, equals(testConfig));

    // Test initial state
    expect(sdk.isConnected(), isFalse);
    expect(sdk.getSessionId(), isNull);
    expect(sdk.getMessages(), isEmpty);
  });

  test('Message model serialization test', () {
    final message = Message(
      id: 'test_123',
      role: MessageRole.user,
      content: 'Hello, world!',
      timestamp: DateTime(2024, 1, 1, 12, 0, 0),
      metadata: {'key': 'value'},
    );

    // Test message properties
    expect(message.id, equals('test_123'));
    expect(message.role, equals(MessageRole.user));
    expect(message.content, equals('Hello, world!'));
    expect(message.metadata?['key'], equals('value'));

    // Test JSON serialization
    final json = message.toJson();
    expect(json['id'], equals('test_123'));
    expect(json['role'], equals('user'));
    expect(json['content'], equals('Hello, world!'));

    // Test JSON deserialization
    final restored = Message.fromJson(json);
    expect(restored.id, equals(message.id));
    expect(restored.role, equals(message.role));
    expect(restored.content, equals(message.content));
  });

  test('SDK user context test', () {
    final context = SDKUserContext(
      userId: 'user_123',
      customAttributes: {
        'plan': 'premium',
        'region': 'us-east',
      },
    );

    expect(context.userId, equals('user_123'));
    expect(context.customAttributes?['plan'], equals('premium'));
    expect(context.customAttributes?['region'], equals('us-east'));

    // Test JSON serialization
    final json = context.toJson();
    expect(json['user_id'], equals('user_123'));
    expect(json['custom_attributes'], isNotNull);

    // Test JSON deserialization
    final restored = SDKUserContext.fromJson(json);
    expect(restored.userId, equals(context.userId));
    expect(restored.customAttributes, equals(context.customAttributes));
  });

  test('Configuration validation test', () {
    // Valid configuration
    final validConfig = SDKConfigurationLoader.createDefault(
      projectId: 'test',
      endpoint: 'https://example.com',
      apiKey: 'pk_test',
    );
    expect(validConfig, isNotNull);

    // Test all config sections exist
    expect(validConfig.connection, isNotNull);
    expect(validConfig.websocket, isNotNull);
    expect(validConfig.voice, isNotNull);
    expect(validConfig.chat, isNotNull);
    expect(validConfig.storage, isNotNull);
    expect(validConfig.theme, isNotNull);
    expect(validConfig.debug, isNotNull);
    expect(validConfig.features, isNotNull);
    expect(validConfig.security, isNotNull);
  });
}
