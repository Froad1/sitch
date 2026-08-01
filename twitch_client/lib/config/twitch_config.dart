import 'package:flutter/foundation.dart';

class TwitchConfig {
  // Replace with your actual Twitch OAuth credentials
  static const String clientId = 'oc3x0o8xlhmi208n62je3urt4yck5w';
  static const String clientSecret = '6kqw37ugnej7swsjqkik3hs4doco1z';
  static const String redirectUri = 'http://localhost:8080/auth/callback';
  
  // OAuth scopes required for the application
  static const List<String> scopes = [
    'user:read:email',
    'user:read:follows',
    'user:read:subscriptions',
    'channel:read:stream_key',
    'chat:read',
    'chat:edit',
    'whispers:read',
    'whispers:edit',
  ];
  
  // API Endpoints
  static const String baseUrl = 'https://api.twitch.tv/helix';
  static const String authUrl = 'https://id.twitch.tv/oauth2';
  static const String ircServer = 'irc.chat.twitch.tv';
  static const int ircPort = 6667;
  static const int ircSecurePort = 6697;
  
  // WebSocket Chat
  static const String chatWebSocketUrl = 'wss://irc-ws.chat.twitch.tv:443';
}
