import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;
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

  /// Set access token manually for testing purposes
  void setManualToken(String token) {
    _accessToken = token;
    _tokenExpiresAt = DateTime.now().add(const Duration(hours: 24));
    notifyListeners();
    _authStateController.add(true);
    // Save to storage for persistence
    _saveAuthToStorage();
  }

  final _authStateController = StreamController<bool>.broadcast();
  get authStateChanges => _authStateController.stream;

  AuthService() {
    _loadAuthFromStorage();
    _setupWebCallbackListener();
  }

  /// Setup listener for web OAuth callback
  void _setupWebCallbackListener() {
    if (!kIsWeb) return;

    // Listen for messages from the callback window
    web.window.addEventListener('message', ((web.MessageEvent event) {
      _handleWebMessage(event);
    }).toJS);

    // Check for stored auth code on page load (direct navigation flow)
    _checkStoredAuthCode();
  }

  /// Handle messages from OAuth callback window
  void _handleWebMessage(web.MessageEvent event) {
    try {
      final data = event.data;
      if (data == null) return;

      // Convert JS object to Dart map
      final jsObj = data.dartify() as Map<String, dynamic>?;
      if (jsObj == null) return;

      final type = jsObj['type'] as String?;
      
      switch (type) {
        case 'twitch-auth-success':
          final code = jsObj['code'] as String?;
          final state = jsObj['state'] as String?;
          
          if (code != null) {
            debugPrint('Received auth code from callback window');
            // Clean up the stored data
            web.window.localStorage.removeItem('twitch_auth_code');
            web.window.localStorage.removeItem('twitch_auth_state');
            web.window.localStorage.removeItem('twitch_auth_timestamp');
            
            // Process the code
            _exchangeCodeForToken(code);
          }
          break;
          
        case 'twitch-auth-error':
          final error = jsObj['error'] as String?;
          final errorDescription = jsObj['error_description'] as String?;
          
          debugPrint('Auth error from callback: $error - $errorDescription');
          _isLoading = false;
          notifyListeners();
          throw Exception('Authentication failed: ${errorDescription ?? error}');
          
        default:
          break;
      }
    } catch (e) {
      debugPrint('Error handling web message: $e');
    }
  }

  /// Check for stored auth code from direct navigation
  Future<void> _checkStoredAuthCode() async {
    if (!kIsWeb) return;

    try {
      final storedCode = web.window.localStorage.getItem('twitch_auth_code');
      final storedState = web.window.localStorage.getItem('twitch_auth_state');
      final timestampStr = web.window.localStorage.getItem('twitch_auth_timestamp');
      
      if (storedCode != null && storedCode.isNotEmpty) {
        // Check if the code is recent (within 5 minutes)
        if (timestampStr != null) {
          final timestamp = int.tryParse(timestampStr) ?? 0;
          final age = DateTime.now().millisecondsSinceEpoch - timestamp;
          
          if (age > 300000) { // 5 minutes
            debugPrint('Stored auth code is too old, clearing');
            _clearStoredAuthData();
            return;
          }
        }
        
        debugPrint('Found stored auth code, processing...');
        
        // Clear the stored data immediately to prevent reuse
        _clearStoredAuthData();
        
        // Process the code
        await _exchangeCodeForToken(storedCode);
      }
    } catch (e) {
      debugPrint('Error checking stored auth code: $e');
    }
  }

  /// Clear stored auth data from localStorage
  void _clearStoredAuthData() {
    if (!kIsWeb) return;
    
    web.window.localStorage.removeItem('twitch_auth_code');
    web.window.localStorage.removeItem('twitch_auth_state');
    web.window.localStorage.removeItem('twitch_auth_timestamp');
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

      debugPrint('Starting OAuth flow with URL: $authUrl');
      
      if (kIsWeb) {
        // For web, open in a new window and let the callback page handle the rest
        final windowFeatures = 'width=600,height=800,menubar=no,toolbar=no';
        web.window.open(authUrl.toString(), '_blank', windowFeatures);
        
        // The callback will be handled by _setupWebCallbackListener via localStorage or postMessage
        // We'll wait for the auth state to change via the stream
        debugPrint('Web OAuth flow started, waiting for callback...');
      } else {
        // Use flutter_web_auth_2 to handle the authentication flow for mobile/desktop
        final result = await FlutterWebAuth2.authenticate(
          url: authUrl.toString(),
          callbackUrlScheme: 'twitch',
        );
        
        debugPrint('Authentication completed, result: $result');
        
        // Parse the callback URL and handle the code
        final callbackUri = Uri.parse(result);
        await handleCallback(callbackUri);
      }
      
    } on Exception catch (e) {
      // Check if user cancelled the login
      if (e.toString().contains('user cancelled') || e.toString().contains('User closed')) {
        debugPrint('Login cancelled by user');
      } else {
        debugPrint('Login error: $e');
        rethrow;
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
    final url = Uri.parse('${TwitchConfig.authUrl}/token');
    
    final body = {
      ...params,
      'client_id': TwitchConfig.clientId,
      'client_secret': TwitchConfig.clientSecret,
    };

    debugPrint('Token request to: $url');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      debugPrint('Token response status: ${response.statusCode}');
      debugPrint('Token response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Extract token information
        _accessToken = data['access_token'] as String?;
        _refreshToken = data['refresh_token'] as String?;
        
        final expiresIn = data['expires_in'] as int?;
        if (expiresIn != null) {
          _tokenExpiresAt = DateTime.now().add(Duration(seconds: expiresIn));
        } else {
          _tokenExpiresAt = DateTime.now().add(const Duration(hours: 24));
        }

        // Fetch user data after getting the token
        if (_accessToken != null) {
          await fetchCurrentUser();
        }

        return data;
      } else {
        throw Exception('Token request failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('HTTP request error: $e');
      rethrow;
    }
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
      final url = Uri.parse('${TwitchConfig.baseUrl}/users');
      
      final response = await http.get(
        url,
        headers: {
          'Client-Id': TwitchConfig.clientId,
          'Authorization': 'Bearer $_accessToken',
        },
      );

      debugPrint('User API response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final usersList = data['data'] as List<dynamic>;
        
        if (usersList.isNotEmpty) {
          _currentUser = TwitchUser.fromJson(usersList[0] as Map<String, dynamic>);
          debugPrint('Logged in as: ${_currentUser?.displayName} (${_currentUser?.login})');
        }
        
        await _saveAuthToStorage();
        _authStateController.add(true);
        notifyListeners();
      } else {
        throw Exception('Failed to fetch user data: ${response.statusCode} - ${response.body}');
      }
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
