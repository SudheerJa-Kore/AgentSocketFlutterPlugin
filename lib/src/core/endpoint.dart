const _missingEndpointError =
    'SDK config endpoint is required (for example: https://runtime.example.com).';
const _invalidEndpointProtocolError =
    'SDK config endpoint must start with http://, https://, ws://, or wss://.';

String _requireEndpoint(String endpoint) {
  final candidate = endpoint.trim();
  if (candidate.isEmpty) {
    throw ArgumentError(_missingEndpointError);
  }
  return candidate.replaceAll(RegExp(r'/+$'), '');
}

/// Normalize the runtime endpoint for HTTP API calls.
String normalizeHttpEndpoint(String endpoint) {
  final candidate = _requireEndpoint(endpoint);
  final hasValidProtocol = RegExp(r'^(https?|wss?)://', caseSensitive: false)
      .hasMatch(candidate);

  if (!hasValidProtocol) {
    throw ArgumentError(_invalidEndpointProtocolError);
  }

  return candidate.replaceFirst(RegExp(r'^ws', caseSensitive: false), 'http');
}

/// Normalize the runtime endpoint for WebSocket connections.
String normalizeWebSocketEndpoint(String endpoint) {
  return normalizeHttpEndpoint(endpoint)
      .replaceFirst(RegExp(r'^http', caseSensitive: false), 'ws');
}
