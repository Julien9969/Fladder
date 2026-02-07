import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dart_discord_presence/dart_discord_presence.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fladder/jellyfin/jellyfin_open_api.enums.swagger.dart';
import 'package:fladder/models/item_base_model.dart';
import 'package:fladder/models/items/episode_model.dart';
import 'package:fladder/models/items/item_stream_model.dart';
import 'package:fladder/models/items/movie_model.dart';
import 'package:fladder/models/playback/playback_model.dart';
import 'package:fladder/providers/api_provider.dart';
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

  // External URL for the Fladder icon (Discord allows external URLs for assets)
  static const String _largeImageUrl =
      'https://raw.githubusercontent.com/Fladder-App/Fladder/refs/heads/master/icons/production/app-icon.png';

  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _hasActivePresence = false;
  DateTime? _sessionStart;
  String? _currentLibraryId; // Cached library ID for current playback session

  DiscordRPC? _rpc;
  StreamSubscription<DiscordErrorEvent>? _errorSubscription;
  StreamSubscription<DiscordDisconnectedEvent>? _disconnectedSubscription;
  StreamSubscription<DiscordReadyEvent>? _readySubscription;

  bool get isSupported => !kIsWeb && DiscordRPC.isAvailable;

  bool get isEnabled => ref.read(discordSettingsProvider).enabled;

  Future<void> initialize() async {
    if (!isSupported || _isInitialized || _isInitializing) return;

    _isInitializing = true;

    try {
      if (!isEnabled) {
        _isInitializing = false;
        return;
      }

      _rpc = DiscordRPC();

      // Set up error handling
      _errorSubscription = _rpc!.onError.listen((event) {
        log('Discord RPC error: ${event.message} (code: ${event.errorCode})');
      });

      _disconnectedSubscription = _rpc!.onDisconnected.listen((event) {
        log('Discord RPC disconnected: ${event.message}');
        _isInitialized = false;
        _hasActivePresence = false;
      });

      // Wait for ready event
      final readyCompleter = Completer<void>();
      _readySubscription = _rpc!.onReady.listen((event) {
        log('Discord RPC ready: connected as ${event.user.username}');
        _isInitialized = true;
        if (!readyCompleter.isCompleted) {
          readyCompleter.complete();
        }
      });

      final applicationId = ref.read(discordSettingsProvider).applicationId;
      await _rpc!.initialize(applicationId);

      // Wait for ready event with timeout
      await readyCompleter.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          log('Discord RPC ready timeout - assuming connected');
          _isInitialized = true;
        },
      );

      log('Discord Rich Presence initialized');
    } on DiscordNotRunningException {
      log('Discord is not running - Rich Presence disabled');
      _rpc = null;
    } on DiscordConnectionException catch (e) {
      log('Failed to connect to Discord: ${e.message}');
      _rpc = null;
    } catch (e) {
      log('Failed to initialize Discord Rich Presence: $e');
      _rpc = null;
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> connect() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  Future<void> disconnect() async {
    if (!isSupported) return;

    try {
      await _errorSubscription?.cancel();
      await _disconnectedSubscription?.cancel();
      await _readySubscription?.cancel();
      _errorSubscription = null;
      _disconnectedSubscription = null;
      _readySubscription = null;

      await _rpc?.dispose();
      _rpc = null;
      _isInitialized = false;
      _hasActivePresence = false;
      _sessionStart = null;
      log('Discord Rich Presence disconnected');
    } catch (e) {
      log('Failed to disconnect from Discord: $e');
      // Reset state anyway
      _rpc = null;
      _isInitialized = false;
      _hasActivePresence = false;
      _sessionStart = null;
    }
  }

  Future<void> clearActivity() async {
    if (!isSupported || (_rpc == null && !_hasActivePresence)) return;

    try {
      await _rpc?.clearPresence();
      _hasActivePresence = false;
      _currentLibraryId = null; // Clear cached library ID
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

    // Get or fetch library ID (cached for the playback session)
    _currentLibraryId ??= await _getLibraryId(item);

    // Check if the library is excluded
    if (_currentLibraryId != null && settings.excludedLibraries.contains(_currentLibraryId)) {
      await clearActivity();
      return;
    }

    try {
      if (!_isInitialized || _rpc == null) {
        await initialize();
        if (_rpc == null || !_isInitialized) return;
      }

      final presenceInfo = _buildPresenceInfo(item, position, playing);

      if (presenceInfo != null) {
        // Get the image URL - use series image for episodes, movie image for movies
        final imageUrl = _getImageUrl(item) ?? _largeImageUrl;

        final presence = DiscordPresence(
          type: DiscordActivityType.watching,
          details: presenceInfo.details,
          state: presenceInfo.state,
          timestamps: _buildTimestamps(position, playing),
          largeAsset: DiscordAsset.fromUrl(imageUrl, text: presenceInfo.largeImageText),
        );

        await _rpc!.setPresence(presence);
        _hasActivePresence = true;
        log('Discord Rich Presence updated: ${presenceInfo.details} - ${presenceInfo.state}');
      } else {
        await clearActivity();
      }
    } on DiscordNotRunningException {
      log('Discord is not running');
      _isInitialized = false;
    } on DiscordConnectionException catch (e) {
      log('Discord connection lost: ${e.message}');
      _isInitialized = false;
    } catch (e) {
      log('Failed to update Discord presence: $e');
    }
  }

  String? _getImageUrl(ItemBaseModel item) {
    // For episodes, use the series (parent) image
    if (item is EpisodeModel) {
      return item.parentImages?.primary?.path ?? item.images?.primary?.path;
    }
    // For movies and other items with streaming capability, use the item's own image
    if (item is ItemStreamModel) {
      return item.images?.primary?.path;
    }
    // Fallback to the item's own image
    return item.images?.primary?.path;
  }

  DiscordTimestamps? _buildTimestamps(Duration? position, bool includeProgress) {
    if (!includeProgress || position == null) {
      _sessionStart = null;
      return null;
    }

    final now = DateTime.now();
    _sessionStart = now.subtract(position);
    return DiscordTimestamps.started(_sessionStart!);
  }

  _PresenceInfo? _buildPresenceInfo(
    ItemBaseModel? item,
    Duration? position,
    bool playing,
  ) {
    if (item == null) return null;

    String details;
    String state;
    String largeImageText = 'Fladder';

    if (item is EpisodeModel) {
      details = item.seriesName ?? item.name;
      state = 'S${item.season}:E${item.episode} - ${item.name}';
      largeImageText = 'TV Show';
    } else if (item is MovieModel) {
      details = item.name;
      final year = item.overview.yearAired;
      state = year != null ? '($year)' : '';
      largeImageText = 'Movie';
    } else {
      details = item.name;
      state = playing ? 'Playing' : 'Paused';
    }

    if (position != null) {
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

  Future<String?> _getLibraryId(ItemBaseModel item) async {
    try {
      final api = ref.read(jellyApiProvider);
      final response = await api.api.itemsItemIdAncestorsGet(itemId: item.id, userId: api.account?.id);

      if (response.isSuccessful && response.body != null) {
        // Find the collection folder (library) in ancestors
        // It's typically the last ancestor with type CollectionFolder
        final collectionFolder = response.body?.lastWhereOrNull(
          (ancestor) => ancestor.type == BaseItemKind.collectionfolder,
        );
        if (collectionFolder?.id != null) {
          log('Library ID found: ${collectionFolder!.id}');
          return collectionFolder.id;
        }
      }
    } catch (e) {
      log('Failed to get library ID from ancestors: $e');
    }

    // Fallback to parentId for direct children of libraries
    log('Using fallback parentId: ${item.parentId}');
    return item.parentId;
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
