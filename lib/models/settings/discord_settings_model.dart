import 'package:freezed_annotation/freezed_annotation.dart';

part 'discord_settings_model.freezed.dart';
part 'discord_settings_model.g.dart';

@Freezed(copyWith: true)
abstract class DiscordSettingsModel with _$DiscordSettingsModel {
  const DiscordSettingsModel._();

  const factory DiscordSettingsModel({
    @Default(false) bool enabled,
    @Default(false) bool showMediaTitle,
    @Default(true) bool showProgress,
    @Default([]) List<String> excludedLibraries,
  }) = _DiscordSettingsModel;

  factory DiscordSettingsModel.fromJson(Map<String, dynamic> json) => _$DiscordSettingsModelFromJson(json);
}
