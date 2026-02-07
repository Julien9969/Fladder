library dart_discord_presence;

import 'dart:async';
import 'dart:io';

import 'package:discord_rich_presence/discord_rich_presence.dart' as drp;

/// Base class for Discord RPC related exceptions.
class DiscordRPCException implements Exception {
  DiscordRPCException(this.message);
  final String message;
  @override
  String toString() => message;
}

class DiscordNotRunningException extends DiscordRPCException {
  DiscordNotRunningException(super.message);
}

class DiscordConnectionException extends DiscordRPCException {
  DiscordConnectionException(super.message);
}

class DiscordStateException extends DiscordRPCException {
  DiscordStateException(super.message);
}

class DiscordUser {
  const DiscordUser({required this.userId, required this.username, String? displayName})
      : displayName = displayName ?? username;

  final String userId;
  final String username;
  final String displayName;
}

class DiscordReadyEvent {
  const DiscordReadyEvent(this.user);
  final DiscordUser user;
}

class DiscordDisconnectedEvent {
  const DiscordDisconnectedEvent({required this.message});
  final String message;
}

class DiscordErrorEvent {
  const DiscordErrorEvent({required this.message});
  final String message;
}

enum DiscordActivityType { playing, streaming, listening, watching, competing }

class DiscordAsset {
  const DiscordAsset._({this.key, this.url, this.text});

  final String? key;
  final String? url;
  final String? text;

  factory DiscordAsset.fromKey(String key, {String? text}) => DiscordAsset._(key: key, text: text);

  factory DiscordAsset.fromUrl(String url, {String? text}) => DiscordAsset._(url: url, text: text);

  drp.ActivityAssets? toActivityAssets() {
    if (url != null) {
      return drp.ActivityAssets.fromExternalLink(url!, text: text);
    }

    if (key != null) {
      return drp.ActivityAssets(
        largeImage: key,
        largeText: text,
      );
    }

    return null;
  }
}

class DiscordTimestamps {
  const DiscordTimestamps._({this.start, this.end});

  final DateTime? start;
  final DateTime? end;

  factory DiscordTimestamps.started(DateTime start) => DiscordTimestamps._(start: start);

  factory DiscordTimestamps.range(DateTime start, DateTime end) =>
      DiscordTimestamps._(start: start, end: end);

  drp.ActivityTimestamps? toActivityTimestamps() {
    if (start == null && end == null) return null;
    return drp.ActivityTimestamps(start: start, end: end);
  }
}

class DiscordPresence {
  const DiscordPresence({
    this.type = DiscordActivityType.playing,
    this.state,
    this.details,
    this.timestamps,
    this.largeAsset,
  });

  final DiscordActivityType type;
  final String? state;
  final String? details;
  final DiscordTimestamps? timestamps;
  final DiscordAsset? largeAsset;

  const DiscordPresence.empty()
      : type = DiscordActivityType.playing,
        state = null,
        details = null,
        timestamps = null,
        largeAsset = null;
}

class DiscordRPC {
  DiscordRPC();

  static bool get isAvailable => Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  final _readyController = StreamController<DiscordReadyEvent>.broadcast();
  final _disconnectedController = StreamController<DiscordDisconnectedEvent>.broadcast();
  final _errorController = StreamController<DiscordErrorEvent>.broadcast();

  Stream<DiscordReadyEvent> get onReady => _readyController.stream;
  Stream<DiscordDisconnectedEvent> get onDisconnected => _disconnectedController.stream;
  Stream<DiscordErrorEvent> get onError => _errorController.stream;

  drp.Client? _client;
  bool _initialized = false;
  String? _applicationId;

  Future<void> initialize(String applicationId) async {
    if (!isAvailable) {
      throw DiscordNotRunningException('Discord RPC not available on this platform.');
    }

    if (_initialized) return;

    final client = drp.Client(clientId: applicationId);
    try {
      await client.connect();
      _client = client;
      _applicationId = applicationId;
      _initialized = true;
      _readyController.add(DiscordReadyEvent(const DiscordUser(userId: 'unknown', username: 'Discord User')));
    } catch (error) {
      await client.disconnect();
      if (error is SocketException) {
        throw DiscordNotRunningException(error.message);
      }
      if (error is String && error.contains("Couldn't connect")) {
        throw DiscordNotRunningException(error);
      }
      throw DiscordConnectionException(error.toString());
    }
  }

  Future<void> setPresence(DiscordPresence presence) async {
    if (!_initialized || _client == null) {
      throw DiscordStateException('Discord RPC has not been initialized.');
    }

    final activity = drp.Activity(
      name: 'Fladder',
      details: presence.details,
      state: presence.state,
      type: _mapActivityType(presence.type),
      timestamps: presence.timestamps?.toActivityTimestamps(),
      assets: presence.largeAsset?.toActivityAssets(),
    );

    try {
      await _client!.setActivity(activity);
    } catch (error) {
      _errorController.add(DiscordErrorEvent(message: error.toString()));
      throw DiscordConnectionException('Failed to update Discord presence: $error');
    }
  }

  Future<void> clearPresence() async {
    if (_client == null) return;
    try {
      await _client!.disconnect();
    } catch (error) {
      _errorController.add(DiscordErrorEvent(message: error.toString()));
    } finally {
      _client = null;
      _initialized = false;
      _disconnectedController.add(const DiscordDisconnectedEvent(message: 'Presence cleared'));
      if (_applicationId != null) {
        // Attempt to reconnect lazily on next initialize call.
      }
    }
  }

  Future<void> dispose() async {
    await clearPresence();
    await Future.wait([
      _readyController.close(),
      _disconnectedController.close(),
      _errorController.close(),
    ]);
  }

  drp.ActivityType _mapActivityType(DiscordActivityType type) {
    switch (type) {
      case DiscordActivityType.streaming:
        return drp.ActivityType.streaming;
      case DiscordActivityType.listening:
        return drp.ActivityType.listening;
      case DiscordActivityType.watching:
        return drp.ActivityType.watching;
      case DiscordActivityType.competing:
        return drp.ActivityType.competing;
      case DiscordActivityType.playing:
        return drp.ActivityType.playing;
    }
  }
}
