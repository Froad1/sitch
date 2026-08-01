import 'package:flutter/foundation.dart';

/// User model representing a Twitch user
class TwitchUser {
  final String id;
  final String login;
  final String displayName;
  final String? email;
  final String? profileImageUrl;
  final String? offlineImageUrl;
  final String? description;
  final String createdAt;
  final String type;
  final String broadcasterType;

  TwitchUser({
    required this.id,
    required this.login,
    required this.displayName,
    this.email,
    this.profileImageUrl,
    this.offlineImageUrl,
    this.description,
    required this.createdAt,
    required this.type,
    required this.broadcasterType,
  });

  factory TwitchUser.fromJson(Map<String, dynamic> json) {
    return TwitchUser(
      id: json['id'] ?? '',
      login: json['login'] ?? '',
      displayName: json['display_name'] ?? '',
      email: json['email'],
      profileImageUrl: json['profile_image_url'],
      offlineImageUrl: json['offline_image_url'],
      description: json['description'],
      createdAt: json['created_at'] ?? '',
      type: json['type'] ?? '',
      broadcasterType: json['broadcaster_type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'login': login,
      'display_name': displayName,
      'email': email,
      'profile_image_url': profileImageUrl,
      'offline_image_url': offlineImageUrl,
      'description': description,
      'created_at': createdAt,
      'type': type,
      'broadcaster_type': broadcasterType,
    };
  }
}

/// Stream model representing a live stream
class Stream {
  final String id;
  final String userId;
  final String userLogin;
  final String userName;
  final String gameId;
  final String gameName;
  final int communityIds;
  final String title;
  final List<String> tags;
  final bool isMature;
  final int viewerCount;
  final DateTime startedAt;
  final String language;
  final String thumbnailUrl;

  Stream({
    required this.id,
    required this.userId,
    required this.userLogin,
    required this.userName,
    required this.gameId,
    required this.gameName,
    required this.communityIds,
    required this.title,
    required this.tags,
    required this.isMature,
    required this.viewerCount,
    required this.startedAt,
    required this.language,
    required this.thumbnailUrl,
  });

  factory Stream.fromJson(Map<String, dynamic> json) {
    return Stream(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      userLogin: json['user_login'] ?? '',
      userName: json['user_name'] ?? '',
      gameId: json['game_id'] ?? '',
      gameName: json['game_name'] ?? '',
      communityIds: json['community_ids']?.length ?? 0,
      title: json['title'] ?? '',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      isMature: json['is_mature'] ?? false,
      viewerCount: json['viewer_count'] ?? 0,
      startedAt: DateTime.parse(json['started_at']),
      language: json['language'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_login': userLogin,
      'user_name': userName,
      'game_id': gameId,
      'game_name': gameName,
      'community_ids': communityIds,
      'title': title,
      'tags': tags,
      'is_mature': isMature,
      'viewer_count': viewerCount,
      'started_at': startedAt.toIso8601String(),
      'language': language,
      'thumbnail_url': thumbnailUrl,
    };
  }

  String getThumbnailUrl({int width = 440, int height = 248}) {
    return thumbnailUrl
        .replaceFirst('{width}', width.toString())
        .replaceFirst('{height}', height.toString());
  }
}

/// Video model representing a VOD (Video On Demand)
class Video {
  final String id;
  final String streamId;
  final String userId;
  final String userLogin;
  final String userName;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime publishedAt;
  final String url;
  final String thumbnailUrl;
  final String viewable;
  final int viewCount;
  final String language;
  final String type;
  final String duration;

  Video({
    required this.id,
    required this.streamId,
    required this.userId,
    required this.userLogin,
    required this.userName,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.publishedAt,
    required this.url,
    required this.thumbnailUrl,
    required this.viewable,
    required this.viewCount,
    required this.language,
    required this.type,
    required this.duration,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] ?? '',
      streamId: json['stream_id'] ?? '',
      userId: json['user_id'] ?? '',
      userLogin: json['user_login'] ?? '',
      userName: json['user_name'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      publishedAt: DateTime.parse(json['published_at']),
      url: json['url'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? '',
      viewable: json['viewable'] ?? '',
      viewCount: json['view_count'] ?? 0,
      language: json['language'] ?? '',
      type: json['type'] ?? '',
      duration: json['duration'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stream_id': streamId,
      'user_id': userId,
      'user_login': userLogin,
      'user_name': userName,
      'title': title,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'published_at': publishedAt.toIso8601String(),
      'url': url,
      'thumbnail_url': thumbnailUrl,
      'viewable': viewable,
      'view_count': viewCount,
      'language': language,
      'type': type,
      'duration': duration,
    };
  }
}

/// Game/Category model
class Game {
  final String id;
  final String name;
  final String boxArtUrl;

  Game({
    required this.id,
    required this.name,
    required this.boxArtUrl,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      boxArtUrl: json['box_art_url'] ?? '',
    );
  }

  String getBoxArtUrl({int width = 285, int height = 380}) {
    return boxArtUrl
        .replaceFirst('{width}', width.toString())
        .replaceFirst('{height}', height.toString());
  }
}

/// Subscription model
class Subscription {
  final String broadcasterId;
  final String broadcasterLogin;
  final String broadcasterName;
  final bool isGift;
  final String gifterId;
  final String gifterLogin;
  final String gifterName;
  final String tier;
  final String planName;

  Subscription({
    required this.broadcasterId,
    required this.broadcasterLogin,
    required this.broadcasterName,
    required this.isGift,
    this.gifterId = '',
    this.gifterLogin = '',
    this.gifterName = '',
    required this.tier,
    required this.planName,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      broadcasterId: json['broadcaster_id'] ?? '',
      broadcasterLogin: json['broadcaster_login'] ?? '',
      broadcasterName: json['broadcaster_name'] ?? '',
      isGift: json['is_gift'] ?? false,
      gifterId: json['gifter_id'] ?? '',
      gifterLogin: json['gifter_login'] ?? '',
      gifterName: json['gifter_name'] ?? '',
      tier: json['tier'] ?? '',
      planName: json['plan_name'] ?? '',
    );
  }
}

/// Chat message model
class ChatMessage {
  final String id;
  final String userId;
  final String username;
  final String displayName;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? badges;
  final String? color;
  final bool isModerator;
  final bool isSubscriber;
  final bool isFounder;
  final bool isVip;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.username,
    required this.displayName,
    required this.message,
    required this.timestamp,
    this.badges,
    this.color,
    required this.isModerator,
    required this.isSubscriber,
    required this.isFounder,
    required this.isVip,
  });

  factory ChatMessage.fromIrcMessage(String rawMessage) {
    // Parse IRC message from Twitch
    // Format: @badge-info=...;badges=...;color=...;display-name=...;emotes=...;flags=...;id=...;mod=...;room-id=...;subscriber=...;tmi-sent-ts=...;turbo=...;user-id=...;user-type=... :username!username@username.tmi.twitch.tv PRIVMSG #channel :message
    
    try {
      final parts = rawMessage.split(' ');
      final tagsPart = parts.firstWhere((p) => p.startsWith('@'), orElse: () => '');
      final messagePart = rawMessage.substring(rawMessage.lastIndexOf(':'));
      
      final tags = <String, String>{};
      if (tagsPart.isNotEmpty) {
        final tagPairs = tagsPart.substring(1).split(';');
        for (final pair in tagPairs) {
          final keyValue = pair.split('=');
          if (keyValue.length == 2) {
            tags[keyValue[0]] = keyValue[1];
          }
        }
      }
      
      final username = parts.length > 2 ? parts[2].split('!')[0] : '';
      final messageId = tags['id'] ?? '';
      final userId = tags['user-id'] ?? '';
      final displayName = tags['display-name'] ?? username;
      final color = tags['color'];
      final mod = tags['mod'] == '1';
      final subscriber = tags['subscriber'] == '1';
      final founder = tags['founder'] == '1';
      final vip = tags['vip'] == '1';
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(tags['tmi-sent-ts'] ?? '0') ?? 0,
      );
      
      return ChatMessage(
        id: messageId,
        userId: userId,
        username: username,
        displayName: displayName,
        message: messagePart.length > 1 ? messagePart.substring(1) : '',
        timestamp: timestamp,
        badges: tags['badges'] != null ? tags['badges'] : null,
        color: color,
        isModerator: mod,
        isSubscriber: subscriber,
        isFounder: founder,
        isVip: vip,
      );
    } catch (e) {
      // Return empty message on parse error
      return ChatMessage(
        id: '',
        userId: '',
        username: '',
        displayName: '',
        message: rawMessage,
        timestamp: DateTime.now(),
        isModerator: false,
        isSubscriber: false,
        isFounder: false,
        isVip: false,
      );
    }
  }
}
