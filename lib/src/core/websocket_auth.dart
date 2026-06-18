const sdkWsAuthProtocol = 'sdk-auth';
const sdkWsTicketProtocol = 'sdk-ticket';

/// Legacy WebSocket auth via session token subprotocol.
List<String> buildSdkWSProtocols(String sdkToken) {
  return [sdkWsAuthProtocol, sdkToken];
}

/// Preferred WebSocket auth via one-time ticket subprotocol.
List<String> buildSdkWSTicketProtocols(String ticket) {
  return [sdkWsTicketProtocol, ticket];
}
