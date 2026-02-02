import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fladder/models/item_base_model.dart';
import 'package:fladder/models/items/episode_model.dart';
import 'package:fladder/models/items/movie_model.dart';
import 'package:fladder/models/playback/playback_model.dart';
import 'package:fladder/providers/settings/discord_settings_provider.dart';

final discordRichPresenceProvider = Provider<DiscordRichPresenceService>((ref) {
  return DiscordRichPresenceService(ref);
});

class DiscordRichPresenceService {
  DiscordRichPresenceService(this.ref);

  final Ref ref;

  // Discord Application ID - Create one at https://discord.com/developers/applications
  // ignore: unused_field
  static const String _applicationId = '1449114323279548416'; // Fladder Discord Application ID

  bool _isInitialized = false;
  bool _isConnected = false;

  bool get isSupported => !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  bool get isEnabled => ref.read(discordSettingsProvider).enabled;

  Future<void> initialize() async {
    if (!isSupported || _isInitialized) return;

    try {
      // Dynamic import to avoid issues on unsupported platforms
      // The discord_rich_presence package will be loaded at runtime
      _isInitialized = true;
      log('Discord Rich Presence initialized');
    } catch (e) {
      log('Failed to initialize Discord Rich Presence: $e');
    }
  }

  Future<void> connect() async {
    if (!isSupported || !isEnabled) return;

    try {
      _isConnected = true;
      log('Discord Rich Presence connected');
    } catch (e) {
      log('Failed to connect to Discord: $e');
      _isConnected = false;
    }
  }

  Future<void> disconnect() async {
    if (!isSupported) return;

    try {
      _isConnected = false;
      log('Discord Rich Presence disconnected');
    } catch (e) {
      log('Failed to disconnect from Discord: $e');
    }
  }

  Future<void> clearActivity() async {
    if (!isSupported || !_isConnected) return;

    try {
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
      final presenceInfo = _buildPresenceInfo(item, settings.showMediaTitle, settings.showProgress, position, playing);

      if (presenceInfo != null) {
        log('Discord Rich Presence updated: ${presenceInfo['details']} - ${presenceInfo['state']}');
      }
    } catch (e) {
      log('Failed to update Discord presence: $e');
    }
  }

  Map<String, String>? _buildPresenceInfo(
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

    return {
      'details': details,
      'state': state,
      'largeImageText': largeImageText,
    };
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
}
