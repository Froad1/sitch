import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/twitch_config.dart';
import '../models/twitch_models.dart';

/// Chat service for Twitch IRC chat
class ChatService extends ChangeNotifier {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _isJoined = false;
  final List<ChatMessage> _messages = [];
  String? _currentChannel;
  Timer? _pingTimer;

  bool get isConnected => _isConnected;
  bool get isJoined => _isJoined;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  String? get currentChannel => _currentChannel;

  /// Connect to Twitch chat WebSocket
  Future<void> connect(String username, String oauthToken) async {
    if (_isConnected) {
      await disconnect();
    }

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse(TwitchConfig.chatWebSocketUrl),
      );

      _channel!.stream.listen(
        _onMessage,
        onDone: _onDisconnected,
        onError: _onError,
      );

      // Wait for connection ready
      await _channel!.ready;

      // Send CAP REQ for required capabilities
      _sendCommand('CAP REQ :twitch.tv/tags twitch.tv/commands twitch.tv/membership');
      
      // Authenticate with OAuth token
      _sendCommand('PASS oauth:$oauthToken');
      _sendCommand('NICK ${username.toLowerCase()}');

      _isConnected = true;
      notifyListeners();

      // Start ping timer to keep connection alive
      _pingTimer = Timer.periodic(
        const Duration(minutes: 2),
        (_) => _sendCommand('PING :tmi.twitch.tv'),
      );
    } catch (e) {
      debugPrint('Chat connect error: $e');
      rethrow;
    }
  }

  /// Join a chat channel
  Future<void> joinChannel(String channelName) async {
    if (!_isConnected) {
      throw Exception('Not connected to chat');
    }

    final channel = '#${channelName.toLowerCase()}';
    
    if (_currentChannel == channel && _isJoined) {
      return; // Already joined
    }

    // Leave previous channel if any
    if (_currentChannel != null && _currentChannel != channel) {
      await leaveChannel();
    }

    _sendCommand('JOIN $channel');
    _currentChannel = channel;
    _messages.clear();
    notifyListeners();
  }

  /// Leave current chat channel
  Future<void> leaveChannel() async {
    if (_currentChannel != null) {
      _sendCommand('PART ${_currentChannel!}');
      _currentChannel = null;
      _isJoined = false;
      _messages.clear();
      notifyListeners();
    }
  }

  /// Send a chat message
  void sendMessage(String message) {
    if (!_isJoined || _currentChannel == null) {
      throw Exception('Not joined to a channel');
    }

    if (message.trim().isEmpty) {
      return;
    }

    _sendCommand('PRIVMSG $_currentChannel :$message');
  }

  /// Send raw IRC command
  void _sendCommand(String command) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add('$command\r\n');
    }
  }

  /// Handle incoming WebSocket messages
  void _onMessage(dynamic data) {
    final message = data.toString();
    
    // Handle PING from server
    if (message.startsWith('PING')) {
      _sendCommand('PONG :tmi.twitch.tv');
      return;
    }

    // Handle JOIN confirmation
    if (message.contains('JOIN') && message.contains(_currentChannel ?? '')) {
      _isJoined = true;
      notifyListeners();
      return;
    }

    // Handle PART
    if (message.contains('PART') && message.contains(_currentChannel ?? '')) {
      _isJoined = false;
      notifyListeners();
      return;
    }

    // Handle PRIVMSG (chat messages)
    if (message.contains('PRIVMSG')) {
      try {
        final chatMessage = ChatMessage.fromIrcMessage(message);
        _messages.add(chatMessage);
        
        // Keep only last 100 messages in memory
        if (_messages.length > 100) {
          _messages.removeAt(0);
        }
        
        notifyListeners();
      } catch (e) {
        debugPrint('Error parsing chat message: $e');
      }
    }

    // Handle other events (clearchat, roomstate, etc.)
    if (message.contains('@room-id')) {
      // Room state update
      return;
    }
  }

  /// Handle disconnection
  void _onDisconnected() {
    _isConnected = false;
    _isJoined = false;
    _pingTimer?.cancel();
    notifyListeners();
  }

  /// Handle errors
  void _onError(dynamic error) {
    debugPrint('Chat error: $error');
    _isConnected = false;
    _isJoined = false;
    _pingTimer?.cancel();
    notifyListeners();
  }

  /// Disconnect from chat
  Future<void> disconnect() async {
    _pingTimer?.cancel();
    
    if (_channel != null) {
      await leaveChannel();
      await _channel!.sink.close();
      _channel = null;
    }

    _isConnected = false;
    _isJoined = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
