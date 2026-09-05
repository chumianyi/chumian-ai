import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_response.dart';
import '../models/pagination.dart';

/// 初眠AI API 服务 -  comprehensive API client
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static const String baseUrl = 'https://api.chumian.ai/v1';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration sendTimeout = Duration(seconds: 30);

  late Dio _dio;
  String? _token;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('api_token');
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      sendTimeout: sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-App-Version': '4.0.0',
        'X-Platform': 'android',
        if (_token != null) 'Authorization': 'Bearer $_token',
      },
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['X-Request-Id'] = _generateRequestId();
        options.headers['X-Timestamp'] = DateTime.now().millisecondsSinceEpoch.toString();
        handler.next(options);
      },
      onResponse: (response, handler) {
        handler.next(response);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ));
    _initialized = true;
  }

  String _generateRequestId() => 'REQ-${DateTime.now().millisecondsSinceEpoch}-${List.generate(8, (_) => 'abcdefghijklmnopqrstuvwxyz0123456789'[Random().nextInt(36)]).join()}';

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('api_token', token);
    } else {
      await prefs.remove('api_token');
    }
    if (_initialized) {
      _dio.options.headers['Authorization'] = token != null ? 'Bearer $token' : null;
    }
  }

  String? get token => _token;

  Future<ApiResponse<T>> _request<T>(
    String method,
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic)? parser,
  }) async {
    try {
      final response = await _dio.request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options ?? Options(method: method),
      );
      final body = response.data is String ? jsonDecode(response.data) : response.data;
      if (parser != null) {
        return ApiResponse.success(parser(body), body['message'] ?? '');
      }
      return ApiResponse.success(body as T, body['message'] ?? '');
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? -1;
      final message = e.response?.data?['message'] ?? e.message ?? 'Network error';
      return ApiResponse.error(message, statusCode);
    } catch (e) {
      return ApiResponse.error(e.toString(), -1);
    }
  }

  Future<ApiResponse<T>> _get<T>(String path, {Map<String, dynamic>? query, T Function(dynamic)? parser}) =>
      _request('GET', path, queryParameters: query, parser: parser);
  Future<ApiResponse<T>> _post<T>(String path, {Map<String, dynamic>? data, T Function(dynamic)? parser}) =>
      _request('POST', path, data: data, parser: parser);
  Future<ApiResponse<T>> _put<T>(String path, {Map<String, dynamic>? data, T Function(dynamic)? parser}) =>
      _request('PUT', path, data: data, parser: parser);
  Future<ApiResponse<T>> _delete<T>(String path, {Map<String, dynamic>? query, T Function(dynamic)? parser}) =>
      _request('DELETE', path, queryParameters: query, parser: parser);

  /// Login with username and password
  Future<ApiResponse<Map<String, dynamic>>> login(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/auth/login', data: data);
  }

  /// Register new account
  Future<ApiResponse<Map<String, dynamic>>> register(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/auth/register', data: data);
  }

  /// Logout current session
  Future<ApiResponse<Map<String, dynamic>>> logout(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/auth/logout', data: data);
  }

  /// Refresh access token
  Future<ApiResponse<Map<String, dynamic>>> refreshToken(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/auth/refresh', data: data);
  }

  /// Verify email address
  Future<ApiResponse<Map<String, dynamic>>> verifyEmail(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/auth/verify-email', data: data);
  }

  /// Resend verification email
  Future<ApiResponse<Map<String, dynamic>>> resendVerification(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/auth/resend-verification', data: data);
  }

  /// Request password reset
  Future<ApiResponse<Map<String, dynamic>>> forgotPassword(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/auth/forgot-password', data: data);
  }

  /// Reset password with token
  Future<ApiResponse<Map<String, dynamic>>> resetPassword(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/auth/reset-password', data: data);
  }

  /// Change current password
  Future<ApiResponse<Map<String, dynamic>>> changePassword(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/auth/change-password', data: data);
  }

  /// Login with GitHub OAuth
  Future<ApiResponse<Map<String, dynamic>>> githubLogin(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/auth/github', data: data);
  }

  /// Bind GitHub account
  Future<ApiResponse<Map<String, dynamic>>> githubBind(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/auth/github/bind', data: data);
  }

  /// Unbind GitHub account
  Future<ApiResponse<Map<String, dynamic>>> githubUnbind(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/auth/github/unbind', data: data);
  }

  /// Send OTP code
  Future<ApiResponse<Map<String, dynamic>>> sendOtp(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/auth/otp/send', data: data);
  }

  /// Verify OTP code
  Future<ApiResponse<Map<String, dynamic>>> verifyOtp(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/auth/otp/verify', data: data);
  }

  /// Check if username is available
  Future<ApiResponse<Map<String, dynamic>>> checkUsername(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/auth/check-username', query: query);
  }

  /// Check if email is registered
  Future<ApiResponse<Map<String, dynamic>>> checkEmail(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/auth/check-email', query: query);
  }

  /// Get all active sessions
  Future<ApiResponse<Map<String, dynamic>>> getSessions(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/auth/sessions', query: query);
  }

  /// Revoke a specific session
  Future<ApiResponse<Map<String, dynamic>>> revokeSession(String id) async {
    return _delete<Map<String, dynamic>>('/auth/sessions/$id');
  }

  /// Revoke all sessions
  Future<ApiResponse<Map<String, dynamic>>> revokeAllSessions(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/auth/sessions/revoke-all', data: data);
  }

  /// Get current user profile
  Future<ApiResponse<Map<String, dynamic>>> getProfile(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/users/me', query: query);
  }

  /// Update user profile
  Future<ApiResponse<Map<String, dynamic>>> updateProfile(Map<String, dynamic>? data) async {
    return _put<Map<String, dynamic>>('/users/me', data: data);
  }

  /// Get user by ID
  Future<ApiResponse<Map<String, dynamic>>> getUserById(String id) async {
    return _get<Map<String, dynamic>>('/users/$id');
  }

  /// Get user by username
  Future<ApiResponse<Map<String, dynamic>>> getUserByUsername(String username) async {
    return _get<Map<String, dynamic>>('/users/username/$username');
  }

  /// Search users
  Future<ApiResponse<Map<String, dynamic>>> searchUsers(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/users/search', query: query);
  }

  /// Upload avatar image
  Future<ApiResponse<Map<String, dynamic>>> uploadAvatar(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/users/me/avatar', data: data);
  }

  /// Update avatar
  Future<ApiResponse<Map<String, dynamic>>> updateAvatar(Map<String, dynamic>? data) async {
    return _put<Map<String, dynamic>>('/users/me/avatar', data: data);
  }

  /// Remove avatar
  Future<ApiResponse<Map<String, dynamic>>> deleteAvatar() async {
    return _delete<Map<String, dynamic>>('/users/me/avatar');
  }

  /// Update nickname
  Future<ApiResponse<Map<String, dynamic>>> updateNickname(Map<String, dynamic>? data) async {
    return _put<Map<String, dynamic>>('/users/me/nickname', data: data);
  }

  /// Update biography
  Future<ApiResponse<Map<String, dynamic>>> updateBio(Map<String, dynamic>? data) async {
    return _put<Map<String, dynamic>>('/users/me/bio', data: data);
  }

  /// Update birthday
  Future<ApiResponse<Map<String, dynamic>>> updateBirthday(Map<String, dynamic>? data) async {
    return _put<Map<String, dynamic>>('/users/me/birthday', data: data);
  }

  /// Update gender
  Future<ApiResponse<Map<String, dynamic>>> updateGender(Map<String, dynamic>? data) async {
    return _put<Map<String, dynamic>>('/users/me/gender', data: data);
  }

  /// Update location
  Future<ApiResponse<Map<String, dynamic>>> updateLocation(Map<String, dynamic>? data) async {
    return _put<Map<String, dynamic>>('/users/me/location', data: data);
  }

  /// Update website
  Future<ApiResponse<Map<String, dynamic>>> updateWebsite(Map<String, dynamic>? data) async {
    return _put<Map<String, dynamic>>('/users/me/website', data: data);
  }

  /// Update email
  Future<ApiResponse<Map<String, dynamic>>> updateEmail(Map<String, dynamic>? data) async {
    return _put<Map<String, dynamic>>('/users/me/email', data: data);
  }

  /// Update phone number
  Future<ApiResponse<Map<String, dynamic>>> updatePhone(Map<String, dynamic>? data) async {
    return _put<Map<String, dynamic>>('/users/me/phone', data: data);
  }

  /// Update preferred language
  Future<ApiResponse<Map<String, dynamic>>> updateLanguage(Map<String, dynamic>? data) async {
    return _put<Map<String, dynamic>>('/users/me/language', data: data);
  }

  /// Update timezone
  Future<ApiResponse<Map<String, dynamic>>> updateTimezone(Map<String, dynamic>? data) async {
    return _put<Map<String, dynamic>>('/users/me/timezone', data: data);
  }

  /// Update theme preference
  Future<ApiResponse<Map<String, dynamic>>> updateTheme(Map<String, dynamic>? data) async {
    return _put<Map<String, dynamic>>('/users/me/theme', data: data);
  }

  /// Update notification settings
  Future<ApiResponse<Map<String, dynamic>>> updateNotificationSettings(Map<String, dynamic>? data) async {
    return _put<Map<String, dynamic>>('/users/me/notifications', data: data);
  }

  /// Update privacy settings
  Future<ApiResponse<Map<String, dynamic>>> updatePrivacySettings(Map<String, dynamic>? data) async {
    return _put<Map<String, dynamic>>('/users/me/privacy', data: data);
  }

  /// Deactivate account
  Future<ApiResponse<Map<String, dynamic>>> deactivateAccount(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/users/me/deactivate', data: data);
  }

  /// Permanently delete account
  Future<ApiResponse<Map<String, dynamic>>> deleteAccount() async {
    return _delete<Map<String, dynamic>>('/users/me');
  }

  /// Export all user data
  Future<ApiResponse<Map<String, dynamic>>> exportData(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/users/me/export', data: data);
  }

  /// Get user statistics
  Future<ApiResponse<Map<String, dynamic>>> getUserStats(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/users/me/stats', query: query);
  }

  /// Get user activity log
  Future<ApiResponse<Map<String, dynamic>>> getUserActivity(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/users/me/activity', query: query);
  }

  /// Get all preferences
  Future<ApiResponse<Map<String, dynamic>>> getUserPreferences(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/users/me/preferences', query: query);
  }

  /// Set a preference
  Future<ApiResponse<Map<String, dynamic>>> setUserPreference(String key, Map<String, dynamic>? data) async {
    return _put<Map<String, dynamic>>('/users/me/preferences/$key', data: data);
  }

  /// Delete a preference
  Future<ApiResponse<Map<String, dynamic>>> deleteUserPreference(String key) async {
    return _delete<Map<String, dynamic>>('/users/me/preferences/$key');
  }

  /// Get all conversations
  Future<ApiResponse<Map<String, dynamic>>> getConversations(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/chat/conversations', query: query);
  }

  /// Create new conversation
  Future<ApiResponse<Map<String, dynamic>>> createConversation(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/chat/conversations', data: data);
  }

  /// Get conversation by ID
  Future<ApiResponse<Map<String, dynamic>>> getConversation(String id) async {
    return _get<Map<String, dynamic>>('/chat/conversations/$id');
  }

  /// Update conversation
  Future<ApiResponse<Map<String, dynamic>>> updateConversation(String id, Map<String, dynamic>? data) async {
    return _put<Map<String, dynamic>>('/chat/conversations/$id', data: data);
  }

  /// Delete conversation
  Future<ApiResponse<Map<String, dynamic>>> deleteConversation(String id) async {
    return _delete<Map<String, dynamic>>('/chat/conversations/$id');
  }

  /// Clear conversation messages
  Future<ApiResponse<Map<String, dynamic>>> clearConversation(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/chat/conversations/$id/clear', data: data);
  }

  /// Pin conversation
  Future<ApiResponse<Map<String, dynamic>>> pinConversation(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/chat/conversations/$id/pin', data: data);
  }

  /// Unpin conversation
  Future<ApiResponse<Map<String, dynamic>>> unpinConversation(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/chat/conversations/$id/unpin', data: data);
  }

  /// Archive conversation
  Future<ApiResponse<Map<String, dynamic>>> archiveConversation(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/chat/conversations/$id/archive', data: data);
  }

  /// Unarchive conversation
  Future<ApiResponse<Map<String, dynamic>>> unarchiveConversation(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/chat/conversations/$id/unarchive', data: data);
  }

  /// Mute conversation
  Future<ApiResponse<Map<String, dynamic>>> muteConversation(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/chat/conversations/$id/mute', data: data);
  }

  /// Unmute conversation
  Future<ApiResponse<Map<String, dynamic>>> unmuteConversation(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/chat/conversations/$id/unmute', data: data);
  }

  /// Get conversation messages
  Future<ApiResponse<Map<String, dynamic>>> getMessages(String id) async {
    return _get<Map<String, dynamic>>('/chat/conversations/$id/messages');
  }

  /// Send message
  Future<ApiResponse<Map<String, dynamic>>> sendMessage(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/chat/conversations/$id/messages', data: data);
  }

  /// Stream AI response
  Future<ApiResponse<Map<String, dynamic>>> streamMessage(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/chat/conversations/$id/stream', data: data);
  }

  /// Edit message
  Future<ApiResponse<Map<String, dynamic>>> editMessage(String id, Map<String, dynamic>? data) async {
    return _put<Map<String, dynamic>>('/chat/messages/$id', data: data);
  }

  /// Delete message
  Future<ApiResponse<Map<String, dynamic>>> deleteMessage(String id) async {
    return _delete<Map<String, dynamic>>('/chat/messages/$id');
  }

  /// Add reaction to message
  Future<ApiResponse<Map<String, dynamic>>> reactToMessage(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/chat/messages/$id/react', data: data);
  }

  /// Remove reaction
  Future<ApiResponse<Map<String, dynamic>>> removeReaction(String id) async {
    return _delete<Map<String, dynamic>>('/chat/messages/$id/react');
  }

  /// Copy message text
  Future<ApiResponse<Map<String, dynamic>>> copyMessage(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/chat/messages/$id/copy', data: data);
  }

  /// Share message
  Future<ApiResponse<Map<String, dynamic>>> shareMessage(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/chat/messages/$id/share', data: data);
  }

  /// Bookmark message
  Future<ApiResponse<Map<String, dynamic>>> bookmarkMessage(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/chat/messages/$id/bookmark', data: data);
  }

  /// Remove bookmark
  Future<ApiResponse<Map<String, dynamic>>> unbookmarkMessage(String id) async {
    return _delete<Map<String, dynamic>>('/chat/messages/$id/bookmark');
  }

  /// Regenerate AI response
  Future<ApiResponse<Map<String, dynamic>>> regenerateResponse(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/chat/messages/$id/regenerate', data: data);
  }

  /// Stop current generation
  Future<ApiResponse<Map<String, dynamic>>> stopGeneration(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/chat/generation/stop', data: data);
  }

  /// Get available AI models
  Future<ApiResponse<Map<String, dynamic>>> getModels(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/chat/models', query: query);
  }

  /// Set conversation model
  Future<ApiResponse<Map<String, dynamic>>> setModel(String id, Map<String, dynamic>? data) async {
    return _put<Map<String, dynamic>>('/chat/conversations/$id/model', data: data);
  }

  /// Get system prompt
  Future<ApiResponse<Map<String, dynamic>>> getSystemPrompt(String id) async {
    return _get<Map<String, dynamic>>('/chat/conversations/$id/system-prompt');
  }

  /// Set system prompt
  Future<ApiResponse<Map<String, dynamic>>> setSystemPrompt(String id, Map<String, dynamic>? data) async {
    return _put<Map<String, dynamic>>('/chat/conversations/$id/system-prompt', data: data);
  }

  /// Get temperature setting
  Future<ApiResponse<Map<String, dynamic>>> getTemperature(String id) async {
    return _get<Map<String, dynamic>>('/chat/conversations/$id/temperature');
  }

  /// Set temperature
  Future<ApiResponse<Map<String, dynamic>>> setTemperature(String id, Map<String, dynamic>? data) async {
    return _put<Map<String, dynamic>>('/chat/conversations/$id/temperature', data: data);
  }

  /// Get max tokens
  Future<ApiResponse<Map<String, dynamic>>> getMaxTokens(String id) async {
    return _get<Map<String, dynamic>>('/chat/conversations/$id/max-tokens');
  }

  /// Set max tokens
  Future<ApiResponse<Map<String, dynamic>>> setMaxTokens(String id, Map<String, dynamic>? data) async {
    return _put<Map<String, dynamic>>('/chat/conversations/$id/max-tokens', data: data);
  }

  /// Export conversation
  Future<ApiResponse<Map<String, dynamic>>> exportConversation(String id) async {
    return _get<Map<String, dynamic>>('/chat/conversations/$id/export');
  }

  /// Import conversation
  Future<ApiResponse<Map<String, dynamic>>> importConversation(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/chat/conversations/import', data: data);
  }

  /// Search messages
  Future<ApiResponse<Map<String, dynamic>>> searchMessages(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/chat/messages/search', query: query);
  }

  /// Get reply suggestions
  Future<ApiResponse<Map<String, dynamic>>> getSuggestions(String id) async {
    return _get<Map<String, dynamic>>('/chat/conversations/$id/suggestions');
  }

  /// Get chat history
  Future<ApiResponse<Map<String, dynamic>>> getHistory(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/chat/history', query: query);
  }

  /// Clear all history
  Future<ApiResponse<Map<String, dynamic>>> clearHistory() async {
    return _delete<Map<String, dynamic>>('/chat/history');
  }

  /// Get chat statistics
  Future<ApiResponse<Map<String, dynamic>>> getStats(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/chat/stats', query: query);
  }

  /// Get API usage
  Future<ApiResponse<Map<String, dynamic>>> getUsage(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/chat/usage', query: query);
  }

  /// Get quota information
  Future<ApiResponse<Map<String, dynamic>>> getQuota(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/chat/quota', query: query);
  }

  /// Generate image from prompt
  Future<ApiResponse<Map<String, dynamic>>> generateImage(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/image/generate', data: data);
  }

  /// Generate image variations
  Future<ApiResponse<Map<String, dynamic>>> generateImageVariations(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/image/variations', data: data);
  }

  /// Edit image with mask
  Future<ApiResponse<Map<String, dynamic>>> editImage(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/image/edit', data: data);
  }

  /// Upscale image
  Future<ApiResponse<Map<String, dynamic>>> upscaleImage(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/image/upscale', data: data);
  }

  /// Remove background
  Future<ApiResponse<Map<String, dynamic>>> removeBackground(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/image/remove-bg', data: data);
  }

  /// Restore old photo
  Future<ApiResponse<Map<String, dynamic>>> restoreImage(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/image/restore', data: data);
  }

  /// Enhance image quality
  Future<ApiResponse<Map<String, dynamic>>> enhanceImage(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/image/enhance', data: data);
  }

  /// Colorize black and white image
  Future<ApiResponse<Map<String, dynamic>>> colorizeImage(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/image/colorize', data: data);
  }

  /// Convert image style
  Future<ApiResponse<Map<String, dynamic>>> convertStyle(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/image/style', data: data);
  }

  /// Get image generation history
  Future<ApiResponse<Map<String, dynamic>>> getImageHistory(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/image/history', query: query);
  }

  /// Get image by ID
  Future<ApiResponse<Map<String, dynamic>>> getImage(String id) async {
    return _get<Map<String, dynamic>>('/image/$id');
  }

  /// Delete image
  Future<ApiResponse<Map<String, dynamic>>> deleteImage(String id) async {
    return _delete<Map<String, dynamic>>('/image/$id');
  }

  /// Download image
  Future<ApiResponse<Map<String, dynamic>>> downloadImage(String id) async {
    return _get<Map<String, dynamic>>('/image/$id/download');
  }

  /// Share image
  Future<ApiResponse<Map<String, dynamic>>> shareImage(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/image/$id/share', data: data);
  }

  /// Like image
  Future<ApiResponse<Map<String, dynamic>>> likeImage(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/image/$id/like', data: data);
  }

  /// Unlike image
  Future<ApiResponse<Map<String, dynamic>>> unlikeImage(String id) async {
    return _delete<Map<String, dynamic>>('/image/$id/like');
  }

  /// Bookmark image
  Future<ApiResponse<Map<String, dynamic>>> bookmarkImage(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/image/$id/bookmark', data: data);
  }

  /// Get available styles
  Future<ApiResponse<Map<String, dynamic>>> getImageStyles(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/image/styles', query: query);
  }

  /// Get available sizes
  Future<ApiResponse<Map<String, dynamic>>> getImageSizes(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/image/sizes', query: query);
  }

  /// Get available models
  Future<ApiResponse<Map<String, dynamic>>> getImageModels(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/image/models', query: query);
  }

  /// Get preset prompts
  Future<ApiResponse<Map<String, dynamic>>> getImagePresets(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/image/presets', query: query);
  }

  /// Save custom preset
  Future<ApiResponse<Map<String, dynamic>>> savePreset(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/image/presets', data: data);
  }

  /// Delete preset
  Future<ApiResponse<Map<String, dynamic>>> deletePreset(String id) async {
    return _delete<Map<String, dynamic>>('/image/presets/$id');
  }

  /// Get image gallery
  Future<ApiResponse<Map<String, dynamic>>> getGallery(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/image/gallery', query: query);
  }

  /// Get favorite images
  Future<ApiResponse<Map<String, dynamic>>> getFavorites(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/image/favorites', query: query);
  }

  /// Get trending images
  Future<ApiResponse<Map<String, dynamic>>> getTrending(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/image/trending', query: query);
  }

  /// Search images
  Future<ApiResponse<Map<String, dynamic>>> searchImages(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/image/search', query: query);
  }

  /// Get image generation stats
  Future<ApiResponse<Map<String, dynamic>>> getImageStats(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/image/stats', query: query);
  }

  /// Get image generation quota
  Future<ApiResponse<Map<String, dynamic>>> getImageQuota(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/image/quota', query: query);
  }

  /// Generate video from prompt
  Future<ApiResponse<Map<String, dynamic>>> generateVideo(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/video/generate', data: data);
  }

  /// Image to video
  Future<ApiResponse<Map<String, dynamic>>> generateVideoFromImage(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/video/image-to-video', data: data);
  }

  /// Get video generation status
  Future<ApiResponse<Map<String, dynamic>>> getVideoStatus(String id) async {
    return _get<Map<String, dynamic>>('/video/$id/status');
  }

  /// Get video by ID
  Future<ApiResponse<Map<String, dynamic>>> getVideo(String id) async {
    return _get<Map<String, dynamic>>('/video/$id');
  }

  /// Delete video
  Future<ApiResponse<Map<String, dynamic>>> deleteVideo(String id) async {
    return _delete<Map<String, dynamic>>('/video/$id');
  }

  /// Download video
  Future<ApiResponse<Map<String, dynamic>>> downloadVideo(String id) async {
    return _get<Map<String, dynamic>>('/video/$id/download');
  }

  /// Get video history
  Future<ApiResponse<Map<String, dynamic>>> getVideoHistory(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/video/history', query: query);
  }

  /// Get video models
  Future<ApiResponse<Map<String, dynamic>>> getVideoModels(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/video/models', query: query);
  }

  /// Get video presets
  Future<ApiResponse<Map<String, dynamic>>> getVideoPresets(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/video/presets', query: query);
  }

  /// Search the web
  Future<ApiResponse<Map<String, dynamic>>> webSearch(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/search/web', query: query);
  }

  /// Search images
  Future<ApiResponse<Map<String, dynamic>>> imageSearch(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/search/images', query: query);
  }

  /// Search videos
  Future<ApiResponse<Map<String, dynamic>>> videoSearch(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/search/videos', query: query);
  }

  /// Search news
  Future<ApiResponse<Map<String, dynamic>>> newsSearch(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/search/news', query: query);
  }

  /// Search academic papers
  Future<ApiResponse<Map<String, dynamic>>> academicSearch(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/search/academic', query: query);
  }

  /// Search code
  Future<ApiResponse<Map<String, dynamic>>> codeSearch(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/search/code', query: query);
  }

  /// Get search history
  Future<ApiResponse<Map<String, dynamic>>> getSearchHistory(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/search/history', query: query);
  }

  /// Clear search history
  Future<ApiResponse<Map<String, dynamic>>> clearSearchHistory() async {
    return _delete<Map<String, dynamic>>('/search/history');
  }

  /// Get search suggestions
  Future<ApiResponse<Map<String, dynamic>>> getSearchSuggestions(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/search/suggestions', query: query);
  }

  /// Get trending searches
  Future<ApiResponse<Map<String, dynamic>>> getTrendingSearches(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/search/trending', query: query);
  }

  /// Get all agents
  Future<ApiResponse<Map<String, dynamic>>> getAgents(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/agents', query: query);
  }

  /// Get agent by ID
  Future<ApiResponse<Map<String, dynamic>>> getAgent(String id) async {
    return _get<Map<String, dynamic>>('/agents/$id');
  }

  /// Create custom agent
  Future<ApiResponse<Map<String, dynamic>>> createAgent(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/agents', data: data);
  }

  /// Update agent
  Future<ApiResponse<Map<String, dynamic>>> updateAgent(String id, Map<String, dynamic>? data) async {
    return _put<Map<String, dynamic>>('/agents/$id', data: data);
  }

  /// Delete agent
  Future<ApiResponse<Map<String, dynamic>>> deleteAgent(String id) async {
    return _delete<Map<String, dynamic>>('/agents/$id');
  }

  /// Duplicate agent
  Future<ApiResponse<Map<String, dynamic>>> duplicateAgent(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/agents/$id/duplicate', data: data);
  }

  /// Publish agent to store
  Future<ApiResponse<Map<String, dynamic>>> publishAgent(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/agents/$id/publish', data: data);
  }

  /// Unpublish agent
  Future<ApiResponse<Map<String, dynamic>>> unpublishAgent(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/agents/$id/unpublish', data: data);
  }

  /// Rate agent
  Future<ApiResponse<Map<String, dynamic>>> rateAgent(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/agents/$id/rate', data: data);
  }

  /// Review agent
  Future<ApiResponse<Map<String, dynamic>>> reviewAgent(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/agents/$id/review', data: data);
  }

  /// Get agent reviews
  Future<ApiResponse<Map<String, dynamic>>> getAgentReviews(String id) async {
    return _get<Map<String, dynamic>>('/agents/$id/reviews');
  }

  /// Install agent
  Future<ApiResponse<Map<String, dynamic>>> installAgent(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/agents/$id/install', data: data);
  }

  /// Uninstall agent
  Future<ApiResponse<Map<String, dynamic>>> uninstallAgent(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/agents/$id/uninstall', data: data);
  }

  /// Get installed agents
  Future<ApiResponse<Map<String, dynamic>>> getInstalledAgents(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/agents/installed', query: query);
  }

  /// Get agent categories
  Future<ApiResponse<Map<String, dynamic>>> getAgentCategories(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/agents/categories', query: query);
  }

  /// Search agents
  Future<ApiResponse<Map<String, dynamic>>> searchAgents(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/agents/search', query: query);
  }

  /// Get trending agents
  Future<ApiResponse<Map<String, dynamic>>> getTrendingAgents(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/agents/trending', query: query);
  }

  /// Get featured agents
  Future<ApiResponse<Map<String, dynamic>>> getFeaturedAgents(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/agents/featured', query: query);
  }

  /// Get new agents
  Future<ApiResponse<Map<String, dynamic>>> getNewAgents(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/agents/new', query: query);
  }

  /// Chat with agent
  Future<ApiResponse<Map<String, dynamic>>> chatWithAgent(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/agents/$id/chat', data: data);
  }

  /// Get agent configuration
  Future<ApiResponse<Map<String, dynamic>>> getAgentConfig(String id) async {
    return _get<Map<String, dynamic>>('/agents/$id/config');
  }

  /// Update agent configuration
  Future<ApiResponse<Map<String, dynamic>>> updateAgentConfig(String id, Map<String, dynamic>? data) async {
    return _put<Map<String, dynamic>>('/agents/$id/config', data: data);
  }

  /// Get agent skills
  Future<ApiResponse<Map<String, dynamic>>> getAgentSkills(String id) async {
    return _get<Map<String, dynamic>>('/agents/$id/skills');
  }

  /// Add skill to agent
  Future<ApiResponse<Map<String, dynamic>>> addAgentSkill(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/agents/$id/skills', data: data);
  }

  /// Remove skill
  Future<ApiResponse<Map<String, dynamic>>> removeAgentSkill(String id, String skillId) async {
    return _delete<Map<String, dynamic>>('/agents/$id/skills/$skillId');
  }

  /// Get agent tools
  Future<ApiResponse<Map<String, dynamic>>> getAgentTools(String id) async {
    return _get<Map<String, dynamic>>('/agents/$id/tools');
  }

  /// Add tool to agent
  Future<ApiResponse<Map<String, dynamic>>> addAgentTool(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/agents/$id/tools', data: data);
  }

  /// Remove tool
  Future<ApiResponse<Map<String, dynamic>>> removeAgentTool(String id, String toolId) async {
    return _delete<Map<String, dynamic>>('/agents/$id/tools/$toolId');
  }

  /// Get agent knowledge base
  Future<ApiResponse<Map<String, dynamic>>> getAgentKnowledge(String id) async {
    return _get<Map<String, dynamic>>('/agents/$id/knowledge');
  }

  /// Upload knowledge document
  Future<ApiResponse<Map<String, dynamic>>> uploadKnowledge(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/agents/$id/knowledge', data: data);
  }

  /// Delete knowledge
  Future<ApiResponse<Map<String, dynamic>>> deleteKnowledge(String id, String docId) async {
    return _delete<Map<String, dynamic>>('/agents/$id/knowledge/$docId');
  }

  /// Get community feed
  Future<ApiResponse<Map<String, dynamic>>> getFeed(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/community/feed', query: query);
  }

  /// Get all posts
  Future<ApiResponse<Map<String, dynamic>>> getPosts(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/community/posts', query: query);
  }

  /// Get post by ID
  Future<ApiResponse<Map<String, dynamic>>> getPost(String id) async {
    return _get<Map<String, dynamic>>('/community/posts/$id');
  }

  /// Create new post
  Future<ApiResponse<Map<String, dynamic>>> createPost(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/community/posts', data: data);
  }

  /// Update post
  Future<ApiResponse<Map<String, dynamic>>> updatePost(String id, Map<String, dynamic>? data) async {
    return _put<Map<String, dynamic>>('/community/posts/$id', data: data);
  }

  /// Delete post
  Future<ApiResponse<Map<String, dynamic>>> deletePost(String id) async {
    return _delete<Map<String, dynamic>>('/community/posts/$id');
  }

  /// Like post
  Future<ApiResponse<Map<String, dynamic>>> likePost(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/community/posts/$id/like', data: data);
  }

  /// Unlike post
  Future<ApiResponse<Map<String, dynamic>>> unlikePost(String id) async {
    return _delete<Map<String, dynamic>>('/community/posts/$id/like');
  }

  /// Share post
  Future<ApiResponse<Map<String, dynamic>>> sharePost(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/community/posts/$id/share', data: data);
  }

  /// Bookmark post
  Future<ApiResponse<Map<String, dynamic>>> bookmarkPost(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/community/posts/$id/bookmark', data: data);
  }

  /// Remove bookmark
  Future<ApiResponse<Map<String, dynamic>>> unbookmarkPost(String id) async {
    return _delete<Map<String, dynamic>>('/community/posts/$id/bookmark');
  }

  /// Report post
  Future<ApiResponse<Map<String, dynamic>>> reportPost(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/community/posts/$id/report', data: data);
  }

  /// Get post comments
  Future<ApiResponse<Map<String, dynamic>>> getComments(String id) async {
    return _get<Map<String, dynamic>>('/community/posts/$id/comments');
  }

  /// Add comment
  Future<ApiResponse<Map<String, dynamic>>> addComment(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/community/posts/$id/comments', data: data);
  }

  /// Reply to comment
  Future<ApiResponse<Map<String, dynamic>>> replyComment(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/community/comments/$id/reply', data: data);
  }

  /// Like comment
  Future<ApiResponse<Map<String, dynamic>>> likeComment(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/community/comments/$id/like', data: data);
  }

  /// Delete comment
  Future<ApiResponse<Map<String, dynamic>>> deleteComment(String id) async {
    return _delete<Map<String, dynamic>>('/community/comments/$id');
  }

  /// Get topics
  Future<ApiResponse<Map<String, dynamic>>> getTopics(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/community/topics', query: query);
  }

  /// Get topic by ID
  Future<ApiResponse<Map<String, dynamic>>> getTopic(String id) async {
    return _get<Map<String, dynamic>>('/community/topics/$id');
  }

  /// Follow topic
  Future<ApiResponse<Map<String, dynamic>>> followTopic(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/community/topics/$id/follow', data: data);
  }

  /// Unfollow topic
  Future<ApiResponse<Map<String, dynamic>>> unfollowTopic(String id) async {
    return _delete<Map<String, dynamic>>('/community/topics/$id/follow');
  }

  /// Get trending topics
  Future<ApiResponse<Map<String, dynamic>>> getTrendingTopics(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/community/topics/trending', query: query);
  }

  /// Get community users
  Future<ApiResponse<Map<String, dynamic>>> getUsers(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/community/users', query: query);
  }

  /// Get user profile
  Future<ApiResponse<Map<String, dynamic>>> getUserProfile(String id) async {
    return _get<Map<String, dynamic>>('/community/users/$id');
  }

  /// Follow user
  Future<ApiResponse<Map<String, dynamic>>> followUser(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/community/users/$id/follow', data: data);
  }

  /// Unfollow user
  Future<ApiResponse<Map<String, dynamic>>> unfollowUser(String id) async {
    return _delete<Map<String, dynamic>>('/community/users/$id/follow');
  }

  /// Get followers
  Future<ApiResponse<Map<String, dynamic>>> getFollowers(String id) async {
    return _get<Map<String, dynamic>>('/community/users/$id/followers');
  }

  /// Get following
  Future<ApiResponse<Map<String, dynamic>>> getFollowing(String id) async {
    return _get<Map<String, dynamic>>('/community/users/$id/following');
  }

  /// Block user
  Future<ApiResponse<Map<String, dynamic>>> blockUser(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/community/users/$id/block', data: data);
  }

  /// Unblock user
  Future<ApiResponse<Map<String, dynamic>>> unblockUser(String id) async {
    return _delete<Map<String, dynamic>>('/community/users/$id/block');
  }

  /// Search community
  Future<ApiResponse<Map<String, dynamic>>> searchCommunity(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/community/search', query: query);
  }

  /// Get points balance
  Future<ApiResponse<Map<String, dynamic>>> getBalance(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/points/balance', query: query);
  }

  /// Get points history

  /// Daily check-in
  Future<ApiResponse<Map<String, dynamic>>> checkin(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/points/checkin', data: data);
  }

  /// Get check-in status
  Future<ApiResponse<Map<String, dynamic>>> getCheckinStatus(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/points/checkin/status', query: query);
  }

  /// Get check-in streak
  Future<ApiResponse<Map<String, dynamic>>> getCheckinStreak(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/points/checkin/streak', query: query);
  }

  /// Get check-in calendar
  Future<ApiResponse<Map<String, dynamic>>> getCheckinCalendar(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/points/checkin/calendar', query: query);
  }

  /// Play guess big/small
  Future<ApiResponse<Map<String, dynamic>>> guessBigSmall(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/points/games/guess', data: data);
  }

  /// Get game history
  Future<ApiResponse<Map<String, dynamic>>> getGameHistory(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/points/games/history', query: query);
  }

  /// Get game statistics
  Future<ApiResponse<Map<String, dynamic>>> getGameStats(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/points/games/stats', query: query);
  }

  /// Get points leaderboard
  Future<ApiResponse<Map<String, dynamic>>> getLeaderboard(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/points/leaderboard', query: query);
  }

  /// Get current rank
  Future<ApiResponse<Map<String, dynamic>>> getRank(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/points/rank', query: query);
  }

  /// Get current level
  Future<ApiResponse<Map<String, dynamic>>> getLevel(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/points/level', query: query);
  }

  /// Get level progress
  Future<ApiResponse<Map<String, dynamic>>> getLevelProgress(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/points/level/progress', query: query);
  }

  /// Get available rewards
  Future<ApiResponse<Map<String, dynamic>>> getRewards(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/points/rewards', query: query);
  }

  /// Redeem reward
  Future<ApiResponse<Map<String, dynamic>>> redeemReward(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/points/rewards/$id/redeem', data: data);
  }

  /// Get redemption history
  Future<ApiResponse<Map<String, dynamic>>> getRedemptionHistory(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/points/redemptions', query: query);
  }

  /// Get daily tasks
  Future<ApiResponse<Map<String, dynamic>>> getTasks(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/points/tasks', query: query);
  }

  /// Complete task
  Future<ApiResponse<Map<String, dynamic>>> completeTask(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/points/tasks/$id/complete', data: data);
  }

  /// Get achievements
  Future<ApiResponse<Map<String, dynamic>>> getAchievements(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/points/achievements', query: query);
  }

  /// Unlock achievement
  Future<ApiResponse<Map<String, dynamic>>> unlockAchievement(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/points/achievements/$id/unlock', data: data);
  }

  /// Get badges
  Future<ApiResponse<Map<String, dynamic>>> getBadges(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/points/badges', query: query);
  }

  /// Get invite code
  Future<ApiResponse<Map<String, dynamic>>> getInviteCode(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/points/invite/code', query: query);
  }

  /// Get invite statistics
  Future<ApiResponse<Map<String, dynamic>>> getInviteStats(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/points/invite/stats', query: query);
  }

  /// Invite friend
  Future<ApiResponse<Map<String, dynamic>>> inviteFriend(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/points/invite', data: data);
  }

  /// Get all songs
  Future<ApiResponse<Map<String, dynamic>>> getSongs(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/music/songs', query: query);
  }

  /// Get song by ID
  Future<ApiResponse<Map<String, dynamic>>> getSong(String id) async {
    return _get<Map<String, dynamic>>('/music/songs/$id');
  }

  /// Search songs
  Future<ApiResponse<Map<String, dynamic>>> searchSongs(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/music/search', query: query);
  }

  /// Get playlists
  Future<ApiResponse<Map<String, dynamic>>> getPlaylists(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/music/playlists', query: query);
  }

  /// Get playlist
  Future<ApiResponse<Map<String, dynamic>>> getPlaylist(String id) async {
    return _get<Map<String, dynamic>>('/music/playlists/$id');
  }

  /// Create playlist
  Future<ApiResponse<Map<String, dynamic>>> createPlaylist(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/music/playlists', data: data);
  }

  /// Update playlist
  Future<ApiResponse<Map<String, dynamic>>> updatePlaylist(String id, Map<String, dynamic>? data) async {
    return _put<Map<String, dynamic>>('/music/playlists/$id', data: data);
  }

  /// Delete playlist
  Future<ApiResponse<Map<String, dynamic>>> deletePlaylist(String id) async {
    return _delete<Map<String, dynamic>>('/music/playlists/$id');
  }

  /// Add song to playlist
  Future<ApiResponse<Map<String, dynamic>>> addSongToPlaylist(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/music/playlists/$id/songs', data: data);
  }

  /// Remove song
  Future<ApiResponse<Map<String, dynamic>>> removeSongFromPlaylist(String id, String songId) async {
    return _delete<Map<String, dynamic>>('/music/playlists/$id/songs/$songId');
  }

  /// Get albums
  Future<ApiResponse<Map<String, dynamic>>> getAlbums(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/music/albums', query: query);
  }

  /// Get album
  Future<ApiResponse<Map<String, dynamic>>> getAlbum(String id) async {
    return _get<Map<String, dynamic>>('/music/albums/$id');
  }

  /// Get artists
  Future<ApiResponse<Map<String, dynamic>>> getArtists(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/music/artists', query: query);
  }

  /// Get artist
  Future<ApiResponse<Map<String, dynamic>>> getArtist(String id) async {
    return _get<Map<String, dynamic>>('/music/artists/$id');
  }

  /// Get song lyrics
  Future<ApiResponse<Map<String, dynamic>>> getLyrics(String id) async {
    return _get<Map<String, dynamic>>('/music/songs/$id/lyrics');
  }

  /// Like song
  Future<ApiResponse<Map<String, dynamic>>> likeSong(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/music/songs/$id/like', data: data);
  }

  /// Unlike song
  Future<ApiResponse<Map<String, dynamic>>> unlikeSong(String id) async {
    return _delete<Map<String, dynamic>>('/music/songs/$id/like');
  }

  /// Get liked songs
  Future<ApiResponse<Map<String, dynamic>>> getLikedSongs(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/music/liked', query: query);
  }

  /// Get recently played
  Future<ApiResponse<Map<String, dynamic>>> getRecentlyPlayed(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/music/recent', query: query);
  }

  /// Get recommendations
  Future<ApiResponse<Map<String, dynamic>>> getRecommendations(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/music/recommendations', query: query);
  }

  /// Get radio stations
  Future<ApiResponse<Map<String, dynamic>>> getRadio(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/music/radio', query: query);
  }

  /// Get music genres
  Future<ApiResponse<Map<String, dynamic>>> getGenres(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/music/genres', query: query);
  }

  /// Get music moods
  Future<ApiResponse<Map<String, dynamic>>> getMoods(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/music/moods', query: query);
  }

  /// Get new releases
  Future<ApiResponse<Map<String, dynamic>>> getNewReleases(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/music/new', query: query);
  }

  /// Get trending songs

  /// Get top charts
  Future<ApiResponse<Map<String, dynamic>>> getTopCharts(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/music/charts', query: query);
  }

  /// Report song play
  Future<ApiResponse<Map<String, dynamic>>> reportPlay(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/music/songs/$id/play', data: data);
  }

  /// Get play statistics
  Future<ApiResponse<Map<String, dynamic>>> getPlayStats(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/music/stats', query: query);
  }

  /// Get all settings
  Future<ApiResponse<Map<String, dynamic>>> getSettings(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/settings', query: query);
  }

  /// Update settings
  Future<ApiResponse<Map<String, dynamic>>> updateSettings(Map<String, dynamic>? data) async {
    return _put<Map<String, dynamic>>('/settings', data: data);
  }

  /// Get notification settings
  Future<ApiResponse<Map<String, dynamic>>> getNotificationSettings(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/settings/notifications', query: query);
  }

  /// Update notification settings

  /// Get privacy settings
  Future<ApiResponse<Map<String, dynamic>>> getPrivacySettings(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/settings/privacy', query: query);
  }

  /// Update privacy settings

  /// Get appearance settings
  Future<ApiResponse<Map<String, dynamic>>> getAppearanceSettings(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/settings/appearance', query: query);
  }

  /// Update appearance settings
  Future<ApiResponse<Map<String, dynamic>>> updateAppearanceSettings(Map<String, dynamic>? data) async {
    return _put<Map<String, dynamic>>('/settings/appearance', data: data);
  }

  /// Get language settings
  Future<ApiResponse<Map<String, dynamic>>> getLanguageSettings(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/settings/language', query: query);
  }

  /// Update language settings
  Future<ApiResponse<Map<String, dynamic>>> updateLanguageSettings(Map<String, dynamic>? data) async {
    return _put<Map<String, dynamic>>('/settings/language', data: data);
  }

  /// Get audio settings
  Future<ApiResponse<Map<String, dynamic>>> getAudioSettings(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/settings/audio', query: query);
  }

  /// Update audio settings
  Future<ApiResponse<Map<String, dynamic>>> updateAudioSettings(Map<String, dynamic>? data) async {
    return _put<Map<String, dynamic>>('/settings/audio', data: data);
  }

  /// Get storage settings
  Future<ApiResponse<Map<String, dynamic>>> getStorageSettings(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/settings/storage', query: query);
  }

  /// Clear cache
  Future<ApiResponse<Map<String, dynamic>>> clearCache(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/settings/storage/clear-cache', data: data);
  }

  /// Get cache size
  Future<ApiResponse<Map<String, dynamic>>> getCacheSize(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/settings/storage/cache-size', query: query);
  }

  /// Get about info
  Future<ApiResponse<Map<String, dynamic>>> getAbout(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/settings/about', query: query);
  }

  /// Get current version
  Future<ApiResponse<Map<String, dynamic>>> getVersion(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/settings/version', query: query);
  }

  /// Check for updates
  Future<ApiResponse<Map<String, dynamic>>> checkUpdate(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/settings/update/check', query: query);
  }

  /// Get changelog
  Future<ApiResponse<Map<String, dynamic>>> getChangelog(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/settings/changelog', query: query);
  }

  /// Get privacy policy
  Future<ApiResponse<Map<String, dynamic>>> getPrivacyPolicy(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/settings/privacy-policy', query: query);
  }

  /// Get user agreement
  Future<ApiResponse<Map<String, dynamic>>> getUserAgreement(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/settings/user-agreement', query: query);
  }

  /// Get terms of service
  Future<ApiResponse<Map<String, dynamic>>> getTermsOfService(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/settings/terms', query: query);
  }

  /// Get cookie policy
  Future<ApiResponse<Map<String, dynamic>>> getCookiePolicy(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/settings/cookies', query: query);
  }

  /// Get data usage policy
  Future<ApiResponse<Map<String, dynamic>>> getDataUsage(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/settings/data-usage', query: query);
  }

  /// Get community guidelines
  Future<ApiResponse<Map<String, dynamic>>> getCommunityGuidelines(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/settings/guidelines', query: query);
  }

  /// Get FAQ
  Future<ApiResponse<Map<String, dynamic>>> getFaq(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/settings/faq', query: query);
  }

  /// Get help center
  Future<ApiResponse<Map<String, dynamic>>> getHelpCenter(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/settings/help', query: query);
  }

  /// Contact support
  Future<ApiResponse<Map<String, dynamic>>> contactSupport(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/settings/contact', data: data);
  }

  /// Submit feedback
  Future<ApiResponse<Map<String, dynamic>>> submitFeedback(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/settings/feedback', data: data);
  }

  /// Report a bug
  Future<ApiResponse<Map<String, dynamic>>> reportBug(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/settings/bug-report', data: data);
  }

  /// Request a feature
  Future<ApiResponse<Map<String, dynamic>>> requestFeature(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/settings/feature-request', data: data);
  }

  /// Get connected accounts
  Future<ApiResponse<Map<String, dynamic>>> getConnectedAccounts(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/settings/connected-accounts', query: query);
  }

  /// Disconnect account
  Future<ApiResponse<Map<String, dynamic>>> disconnectAccount(String provider, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/settings/connected-accounts/$provider/disconnect', data: data);
  }

  /// Get API keys
  Future<ApiResponse<Map<String, dynamic>>> getApiKeys(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/settings/api-keys', query: query);
  }

  /// Create API key
  Future<ApiResponse<Map<String, dynamic>>> createApiKey(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/settings/api-keys', data: data);
  }

  /// Revoke API key
  Future<ApiResponse<Map<String, dynamic>>> revokeApiKey(String id) async {
    return _delete<Map<String, dynamic>>('/settings/api-keys/$id');
  }

  /// Get webhooks
  Future<ApiResponse<Map<String, dynamic>>> getWebhooks(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/settings/webhooks', query: query);
  }

  /// Create webhook
  Future<ApiResponse<Map<String, dynamic>>> createWebhook(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/settings/webhooks', data: data);
  }

  /// Update webhook
  Future<ApiResponse<Map<String, dynamic>>> updateWebhook(String id, Map<String, dynamic>? data) async {
    return _put<Map<String, dynamic>>('/settings/webhooks/$id', data: data);
  }

  /// Delete webhook
  Future<ApiResponse<Map<String, dynamic>>> deleteWebhook(String id) async {
    return _delete<Map<String, dynamic>>('/settings/webhooks/$id');
  }

  /// Test webhook
  Future<ApiResponse<Map<String, dynamic>>> testWebhook(String id, Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/settings/webhooks/$id/test', data: data);
  }

  /// Export user data
  Future<ApiResponse<Map<String, dynamic>>> getExportData(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/settings/export', query: query);
  }

  /// Request account deletion
  Future<ApiResponse<Map<String, dynamic>>> requestDataDeletion(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/settings/delete-account', data: data);
  }

  /// Get active sessions
  Future<ApiResponse<Map<String, dynamic>>> getSessionInfo(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/settings/sessions', query: query);
  }

  /// Revoke session

  /// Get login history
  Future<ApiResponse<Map<String, dynamic>>> getLoginHistory(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/settings/login-history', query: query);
  }

  /// Get security logs
  Future<ApiResponse<Map<String, dynamic>>> getSecurityLogs(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/settings/security-logs', query: query);
  }

  /// Enable 2FA
  Future<ApiResponse<Map<String, dynamic>>> enableTwoFactor(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/settings/2fa/enable', data: data);
  }

  /// Disable 2FA
  Future<ApiResponse<Map<String, dynamic>>> disableTwoFactor(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/settings/2fa/disable', data: data);
  }

  /// Get 2FA status
  Future<ApiResponse<Map<String, dynamic>>> getTwoFactorStatus(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/settings/2fa/status', query: query);
  }

  /// Verify 2FA code
  Future<ApiResponse<Map<String, dynamic>>> verifyTwoFactor(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/settings/2fa/verify', data: data);
  }

  /// Get backup codes
  Future<ApiResponse<Map<String, dynamic>>> getBackupCodes(Map<String, dynamic>? query) async {
    return _get<Map<String, dynamic>>('/settings/2fa/backup-codes', query: query);
  }

  /// Regenerate backup codes
  Future<ApiResponse<Map<String, dynamic>>> regenerateBackupCodes(Map<String, dynamic>? data) async {
    return _post<Map<String, dynamic>>('/settings/2fa/backup-codes/regenerate', data: data);
  }

}
