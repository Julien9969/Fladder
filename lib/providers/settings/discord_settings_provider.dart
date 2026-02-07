import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fladder/models/settings/discord_settings_model.dart';
import 'package:fladder/providers/shared_provider.dart';
import 'package:fladder/util/debouncer.dart';

final discordSettingsProvider = StateNotifierProvider<DiscordSettingsNotifier, DiscordSettingsModel>((ref) {
  return DiscordSettingsNotifier(ref);
});

class DiscordSettingsNotifier extends StateNotifier<DiscordSettingsModel> {
  DiscordSettingsNotifier(this.ref) : super(const DiscordSettingsModel());

  final Ref ref;

  final Debouncer _debouncer = Debouncer(const Duration(seconds: 1));

  @override
  set state(DiscordSettingsModel value) {
    super.state = value;
    _debouncer.run(() => ref.read(sharedUtilityProvider).discordSettings = state);
  }

  void initialize(DiscordSettingsModel value) {
    state = value;
  }

  void setEnabled(bool value) {
    state = state.copyWith(enabled: value);
  }

  void setApplicationId(String value) {
    state = state.copyWith(applicationId: value);
  }

  void toggleLibraryExclusion(String libraryId) {
    final currentExclusions = List<String>.from(state.excludedLibraries);
    if (currentExclusions.contains(libraryId)) {
      currentExclusions.remove(libraryId);
    } else {
      currentExclusions.add(libraryId);
    }
    state = state.copyWith(excludedLibraries: currentExclusions);
  }

  bool isLibraryExcluded(String libraryId) {
    return state.excludedLibraries.contains(libraryId);
  }
}
