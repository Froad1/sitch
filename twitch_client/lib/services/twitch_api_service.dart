import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/twitch_config.dart';
import '../models/twitch_models.dart';
import 'auth_service.dart';

/// Twitch API service for interacting with Twitch Helix API
class TwitchApiService extends ChangeNotifier {
  final AuthService _authService;
  
  bool _isLoading = false;
  String? _lastError;
  
  List<Stream> _featuredStreams = [];
  List<Video> _recentVideos = [];
  List<Subscription> _subscriptions = [];
  List<TwitchUser> _followedChannels = [];

  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  List<Stream> get featuredStreams => _featuredStreams;
  List<Video> get recentVideos => _recentVideos;
  List<Subscription> get subscriptions => _subscriptions;
  List<TwitchUser> get followedChannels => _followedChannels;

  TwitchApiService(this._authService);

  /// Get headers for API requests
  Map<String, String> _getHeaders() {
    final token = _authService.accessToken;
    return {
      'Client-Id': TwitchConfig.clientId,
      if (token != null) 'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Fetch featured/live streams
  Future<List<Stream>> getFeaturedStreams({
    int first = 20,
    List<String>? gameIds,
    List<String>? userIds,
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final uri = Uri.parse('${TwitchConfig.baseUrl}/streams').replace(
        queryParameters: {
          'first': first.toString(),
          if (gameIds != null) 'game_id': gameIds.join(','),
          if (userIds != null) 'user_id': userIds.join(','),
        },
      );

      final response = await http.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final streamsData = data['data'] as List<dynamic>;
        
        _featuredStreams = streamsData
            .map((stream) => Stream.fromJson(stream as Map<String, dynamic>))
            .toList();
        
        notifyListeners();
        return _featuredStreams;
      } else {
        throw Exception('Failed to fetch streams: ${response.statusCode}');
      }
    } catch (e) {
      _lastError = e.toString();
      debugPrint('Get featured streams error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get stream by user ID
  Future<Stream?> getStreamByUserId(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final uri = Uri.parse('${TwitchConfig.baseUrl}/streams').replace(
        queryParameters: {
          'user_id': userId,
        },
      );

      final response = await http.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final streamsData = data['data'] as List<dynamic>;
        
        if (streamsData.isNotEmpty) {
          return Stream.fromJson(streamsData[0] as Map<String, dynamic>);
        }
        return null;
      } else {
        throw Exception('Failed to fetch stream: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get stream by user error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch videos (VODs) from a channel
  Future<List<Video>> getChannelVideos({
    required String userId,
    int first = 20,
    String? type, // 'all', 'upload', 'archive', 'highlight'
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final uri = Uri.parse('${TwitchConfig.baseUrl}/videos').replace(
        queryParameters: {
          'user_id': userId,
          'first': first.toString(),
          if (type != null) 'type': type,
        },
      );

      final response = await http.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final videosData = data['data'] as List<dynamic>;
        
        _recentVideos = videosData
            .map((video) => Video.fromJson(video as Map<String, dynamic>))
            .toList();
        
        notifyListeners();
        return _recentVideos;
      } else {
        throw Exception('Failed to fetch videos: ${response.statusCode}');
      }
    } catch (e) {
      _lastError = e.toString();
      debugPrint('Get channel videos error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch user subscriptions
  Future<List<Subscription>> getSubscriptions({
    String? userId, // defaults to authenticated user
    int first = 100,
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final uri = Uri.parse('${TwitchConfig.baseUrl}/subscriptions').replace(
        queryParameters: {
          'broadcaster_id': userId ?? '',
          'first': first.toString(),
        },
      );

      final response = await http.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final subsData = data['data'] as List<dynamic>;
        
        _subscriptions = subsData
            .map((sub) => Subscription.fromJson(sub as Map<String, dynamic>))
            .toList();
        
        notifyListeners();
        return _subscriptions;
      } else {
        throw Exception('Failed to fetch subscriptions: ${response.statusCode}');
      }
    } catch (e) {
      _lastError = e.toString();
      debugPrint('Get subscriptions error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch followed channels
  Future<List<TwitchUser>> getFollowedChannels({
    String? userId, // defaults to authenticated user
    int first = 100,
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final uri = Uri.parse('${TwitchConfig.baseUrl}/users/follows').replace(
        queryParameters: {
          'from_id': userId ?? '',
          'first': first.toString(),
        },
      );

      final response = await http.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final followsData = data['data'] as List<dynamic>;
        
        // Extract target user info from follows
        _followedChannels = followsData
            .map((follow) => TwitchUser.fromJson({
              'id': follow['to_id'],
              'login': follow['to_login'],
              'display_name': follow['to_name'],
            }))
            .toList();
        
        notifyListeners();
        return _followedChannels;
      } else {
        throw Exception('Failed to fetch followed channels: ${response.statusCode}');
      }
    } catch (e) {
      _lastError = e.toString();
      debugPrint('Get followed channels error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search channels
  Future<List<TwitchUser>> searchChannels(String query, {int first = 20}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final uri = Uri.parse('${TwitchConfig.baseUrl}/search/channels').replace(
        queryParameters: {
          'query': query,
          'first': first.toString(),
        },
      );

      final response = await http.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final channelsData = data['data'] as List<dynamic>;
        
        return channelsData
            .map((channel) => TwitchUser.fromJson({
              'id': channel['broadcaster_id'],
              'login': channel['broadcaster_login'],
              'display_name': channel['broadcaster_name'],
              'profile_image_url': channel['profile_image_url'],
              'description': channel['description'],
            }))
            .toList();
      } else {
        throw Exception('Failed to search channels: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Search channels error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get games/categories
  Future<List<Game>> getTopGames({int first = 20}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final uri = Uri.parse('${TwitchConfig.baseUrl}/games/top').replace(
        queryParameters: {
          'first': first.toString(),
        },
      );

      final response = await http.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final gamesData = data['data'] as List<dynamic>;
        
        return gamesData
            .map((game) => Game.fromJson(game as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to fetch games: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get top games error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get user by login
  Future<TwitchUser?> getUserByLogin(String login) async {
    _isLoading = true;
    notifyListeners();

    try {
      final uri = Uri.parse('${TwitchConfig.baseUrl}/users').replace(
        queryParameters: {
          'login': login,
        },
      );

      final response = await http.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final usersData = data['data'] as List<dynamic>;
        
        if (usersData.isNotEmpty) {
          return TwitchUser.fromJson(usersData[0] as Map<String, dynamic>);
        }
        return null;
      } else {
        throw Exception('Failed to fetch user: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get user by login error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear cached data
  void clearCache() {
    _featuredStreams = [];
    _recentVideos = [];
    _subscriptions = [];
    _followedChannels = [];
    notifyListeners();
  }
}
