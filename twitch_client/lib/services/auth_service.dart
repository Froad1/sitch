import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/twitch_config.dart';
import '../models/twitch_models.dart';

/// Authentication service for Twitch OAuth 2.0
class AuthService extends ChangeNotifier {
  TwitchUser? _currentUser;
  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiresAt;
  bool _isLoading = false;

  TwitchUser? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _accessToken != null;
  bool get isLoading => _isLoading;

  StreamController<bool> _authStateController = StreamController<bool>.broadcast();
  Stream<bool> get authStateChanges => _authStateController.stream;

  AuthService() {
    _loadAuthFromStorage();
  }

  /// Load authentication data from local storage
  Future<void> _loadAuthFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('access_token');
      _refreshToken = prefs.getString('refresh_token');
      final expiresAt = prefs.getInt('token_expires_at');
      if (expiresAt != null) {
        _tokenExpiresAt = DateTime.fromMillisecondsSinceEpoch(expiresAt);
      }

      final userJson = prefs.getString('user_data');
      if (userJson != null) {
        _currentUser = TwitchUser.fromJson(jsonDecode(userJson));
      }

      // Check if token is expired
      if (_tokenExpiresAt != null && _tokenExpiresAt!.isBefore(DateTime.now())) {
        await refreshToken();
      }

      notifyListeners();
      _authStateController.add(isAuthenticated);
    } catch (e) {
      debugPrint('Error loading auth from storage: $e');
    }
  }

  /// Save authentication data to local storage
  Future<void> _saveAuthToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', _accessToken ?? '');
      if (_refreshToken != null) {
        await prefs.setString('refresh_token', _refreshToken!);
      }
      if (_tokenExpiresAt != null) {
        await prefs.setInt('token_expires_at', _tokenExpiresAt!.millisecondsSinceEpoch);
      }
      if (_currentUser != null) {
        await prefs.setString('user_data', jsonEncode(_currentUser!.toJson()));
      }
    } catch (e) {
      debugPrint('Error saving auth to storage: $e');
    }
  }

  /// Start OAuth 2.0 authorization code flow
  Future<void> login() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Generate random state for security
      final state = _generateRandomString(32);
      
      // Build authorization URL
      final authUrl = Uri.parse('${TwitchConfig.authUrl}/authorize').replace(
        queryParameters: {
          'response_type': 'code',
          'client_id': TwitchConfig.clientId,
          'redirect_uri': TwitchConfig.redirectUri,
          'scope': TwitchConfig.scopes.join(' '),
          'state': state,
        },
      );

      // Launch browser for authentication
      if (await canLaunchUrl(authUrl)) {
        await launchUrl(
          authUrl,
          mode: LaunchMode.externalApplication,
        );
        
        // Note: In a real app, you'd need to handle the callback URL
        // This is platform-specific and requires additional setup
        debugPrint('Authorization URL: $authUrl');
        debugPrint('Please complete authentication in browser and handle callback');
      } else {
        throw Exception('Could not launch authorization URL');
      }
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Handle OAuth callback with authorization code
  Future<void> handleCallback(Uri uri) async {
    final code = uri.queryParameters['code'];
    final state = uri.queryParameters['state'];
    
    if (code == null) {
      throw Exception('No authorization code received');
    }

    await _exchangeCodeForToken(code);
  }

  /// Exchange authorization code for access token
  Future<void> _exchangeCodeForToken(String code) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await Future.any([
        Future.delayed(Duration.zero).then((_) => _makeTokenRequest({
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': TwitchConfig.redirectUri,
        })),
      ]);

      await _saveAuthToStorage();
      _authStateController.add(true);
      notifyListeners();
    } catch (e) {
      debugPrint('Token exchange error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Make token request to Twitch
  Future<Map<String, dynamic>> _makeTokenRequest(Map<String, String> params) async {
    // This would normally make an HTTP request to Twitch's token endpoint
    // For security, this should be done through a backend server in production
    final url = Uri.parse('${TwitchConfig.authUrl}/token');
    
    final body = {
      ...params,
      'client_id': TwitchConfig.clientId,
      'client_secret': TwitchConfig.clientSecret,
    };

    debugPrint('Token request to: $url');
    debugPrint('Body: $body');
    
    // Placeholder - implement actual HTTP request
    throw UnimplementedError('Token request must be implemented with proper HTTP client');
  }

  /// Refresh access token
  Future<void> refreshToken() async {
    if (_refreshToken == null) {
      throw Exception('No refresh token available');
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _makeTokenRequest({
        'grant_type': 'refresh_token',
        'refresh_token': _refreshToken!,
      });

      await _saveAuthToStorage();
      _authStateController.add(true);
      notifyListeners();
    } catch (e) {
      debugPrint('Token refresh error: $e');
      await logout();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logout and clear authentication data
  Future<void> logout() async {
    try {
      _accessToken = null;
      _refreshToken = null;
      _tokenExpiresAt = null;
      _currentUser = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      notifyListeners();
      _authStateController.add(false);
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  /// Fetch current user data from Twitch API
  Future<void> fetchCurrentUser() async {
    if (_accessToken == null) {
      throw Exception('Not authenticated');
    }

    _isLoading = true;
    notifyListeners();

    try {
      // This would make an HTTP request to Twitch API
      // GET https://api.twitch.tv/helix/users
      // Headers: Authorization: Bearer <token>, Client-Id: <client_id>
      
      debugPrint('Fetching current user with token: ${_accessToken?.substring(0, 10)}...');
      
      // Placeholder - implement actual API call
      throw UnimplementedError('Fetch user must be implemented with HTTP client');
    } catch (e) {
      debugPrint('Fetch user error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Generate random string for OAuth state
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random % chars.length),
      ),
    );
  }

  @override
  void dispose() {
    _authStateController.close();
    super.dispose();
  }
}
