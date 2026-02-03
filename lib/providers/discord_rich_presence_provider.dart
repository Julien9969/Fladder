import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:discord_rich_presence/discord_rich_presence.dart' as drp;
import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fladder/models/item_base_model.dart';
import 'package:fladder/models/items/episode_model.dart';
import 'package:fladder/models/items/movie_model.dart';
import 'package:fladder/models/playback/playback_model.dart';
import 'package:fladder/providers/settings/discord_settings_provider.dart';

final discordRichPresenceProvider = Provider<DiscordRichPresenceService>((ref) {
  final service = DiscordRichPresenceService(ref);
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  // Attempt to initialize once the provider is read.
  unawaited(service.initialize());
  return service;
});

class DiscordRichPresenceService {
  DiscordRichPresenceService(this.ref) {
    ref.listen(discordSettingsProvider, (previous, next) {
      final wasEnabled = previous?.enabled ?? false;
      if (next.enabled && !wasEnabled) {
        unawaited(initialize());
      } else if (!next.enabled && wasEnabled) {
        unawaited(clearActivity());
      }
    }, fireImmediately: true);
  }

  final Ref ref;

  // Discord Application ID - Create one at https://discord.com/developers/applications
  // ignore: unused_field
  static const String _applicationId = '1449114323279548416'; // Fladder Discord Application ID
  static const String _largeImageKey = 'fladder_icon';
  static const int _maxConnectionAttempts = 5;
  static const Duration _connectionRetryDelay = Duration(seconds: 1);

  bool _isInitialized = false;
  bool _isConnected = false;
  bool _hasActivePresence = false;
  DateTime? _sessionStart;

  drp.Client? _client;
  Completer<void>? _connectionCompleter;

  bool get isSupported => !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  bool get isEnabled => ref.read(discordSettingsProvider).enabled;

  Future<void> initialize() async {
    if (!isSupported || _isInitialized) return;

    try {
      if (!isEnabled) return;
      final connected = await _ensureConnection();
      if (connected) {
        _isInitialized = true;
        log('Discord Rich Presence initialized');
      }
    } catch (e) {
      log('Failed to initialize Discord Rich Presence: $e');
    }
  }

  Future<void> connect() async {
    await _ensureConnection();
  }

  Future<void> disconnect() async {
    if (!isSupported) return;

    try {
      await _client?.disconnect();
      _isConnected = false;
      _isInitialized = false;
      _hasActivePresence = false;
      _sessionStart = null;
      _client = null;
      log('Discord Rich Presence disconnected');
    } catch (e) {
      log('Failed to disconnect from Discord: $e');
    }
  }

  Future<void> clearActivity() async {
    if (!isSupported || (_client == null && !_hasActivePresence)) return;

    try {
      await disconnect();
      _hasActivePresence = false;
      log('Discord Rich Presence activity cleared');
    } catch (e) {
      log('Failed to clear Discord activity: $e');
    }
  }

  Future<void> updatePresence(PlaybackModel? playbackModel, {Duration? position, bool playing = false}) async {
    if (!isSupported || !isEnabled || playbackModel == null) {
      await clearActivity();
      return;
    }

    final settings = ref.read(discordSettingsProvider);
    final item = playbackModel.item;

    // Check if the library is excluded
    if (settings.excludedLibraries.contains(item.parentId)) {
      await clearActivity();
      return;
    }

    try {
      final connected = await _ensureConnection();
      if (!connected || _client == null) {
        return;
      }

      final presenceInfo = _buildPresenceInfo(item, settings.showMediaTitle, settings.showProgress, position, playing);

      if (presenceInfo != null) {
        final activity = drp.Activity(
          name: 'Fladder',
          details: presenceInfo.details,
          state: presenceInfo.state,
          type: drp.ActivityType.watching,
          timestamps: _buildTimestamps(position, settings.showProgress && playing),
          assets: _buildAssets(presenceInfo.largeImageText),
        );

        await _client!.setActivity(activity);
        _hasActivePresence = true;
        log('Discord Rich Presence updated: ${presenceInfo.details} - ${presenceInfo.state}');
      } else {
        await clearActivity();
      }
    } on SocketException catch (e) {
      log('Failed to update Discord presence: $e');
      await disconnect();
    } catch (e) {
      log('Failed to update Discord presence: $e');
    }
  }

  Future<bool> _ensureConnection() async {
    if (!isSupported || !isEnabled) return false;
    if (_client != null && _isConnected) return true;

    if (_connectionCompleter != null) {
      try {
        await _connectionCompleter!.future;
      } catch (_) {
        // Swallow connection errors handled elsewhere.
      }
      return _isConnected;
    }

    final completer = Completer<void>();
    _connectionCompleter = completer;

    try {
      for (var attempt = 1; attempt <= _maxConnectionAttempts; attempt++) {
        try {
          final client = drp.Client(
            clientId: _applicationId,
            onTransportClosed: _handleTransportClosed,
          );
          await client.connect();
          _client = client;
          _isConnected = true;
          _isInitialized = true;
          log('Discord Rich Presence connected');
          completer.complete();
          return true;
        } catch (e) {
          _client = null;
          _isConnected = false;
          _isInitialized = false;

          if (attempt == _maxConnectionAttempts) {
            log("Failed to connect to Discord's IPC after $attempt attempts. Is the Discord desktop app running? Error: $e");
            completer.completeError(e);
            return false;
          }

          final delay = _connectionRetryDelay * attempt;
          log("Discord IPC connection failed (attempt $attempt/$_maxConnectionAttempts). Retrying in ${delay.inMilliseconds}ms...");
          await Future.delayed(delay);
        }
      }
    } finally {
      if (_connectionCompleter == completer) {
        _connectionCompleter = null;
      }
    }

    return false;
  }

  void _handleTransportClosed() {
    _isConnected = false;
    _hasActivePresence = false;
    _sessionStart = null;
    _client = null;
  }

  drp.ActivityTimestamps? _buildTimestamps(Duration? position, bool includeProgress) {
    if (!includeProgress || position == null) {
      _sessionStart = null;
      return null;
    }

    final now = DateTime.now();
    _sessionStart = now.subtract(position);
    return drp.ActivityTimestamps(start: _sessionStart);
  }

  drp.ActivityAssets? _buildAssets(String label) {
    if (_largeImageKey.isEmpty) return null;
    return drp.ActivityAssets(
      largeImage: _largeImageKey,
      largeText: label,
    );
  }

  _PresenceInfo? _buildPresenceInfo(
    ItemBaseModel? item,
    bool showTitle,
    bool showProgress,
    Duration? position,
    bool playing,
  ) {
    if (item == null) return null;

    String details;
    String state;
    String largeImageText = 'Fladder';

    if (item is EpisodeModel) {
      if (showTitle) {
        details = item.seriesName ?? item.name;
        state = 'S${item.season}:E${item.episode} - ${item.name}';
      } else {
        details = 'Watching a TV Show';
        state = playing ? 'Playing' : 'Paused';
      }
      largeImageText = 'TV Show';
    } else if (item is MovieModel) {
      if (showTitle) {
        details = item.name;
        final year = item.overview.yearAired;
        state = year != null ? '($year)' : '';
      } else {
        details = 'Watching a Movie';
        state = playing ? 'Playing' : 'Paused';
      }
      largeImageText = 'Movie';
    } else {
      if (showTitle) {
        details = item.name;
        state = playing ? 'Playing' : 'Paused';
      } else {
        details = 'Watching Media';
        state = playing ? 'Playing' : 'Paused';
      }
    }

    if (showProgress && position != null) {
      final positionStr = _formatDuration(position);
      state = '$state • $positionStr';
    }

    return _PresenceInfo(details: details, state: state, largeImageText: largeImageText);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> dispose() async {
    await disconnect();
  }
}

class _PresenceInfo {
  const _PresenceInfo({required this.details, required this.state, required this.largeImageText});

  final String details;
  final String state;
  final String largeImageText;
}
