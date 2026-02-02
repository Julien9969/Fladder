// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discord_settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DiscordSettingsModel _$DiscordSettingsModelFromJson(
        Map<String, dynamic> json) =>
    _DiscordSettingsModel(
      enabled: json['enabled'] as bool? ?? false,
      showMediaTitle: json['showMediaTitle'] as bool? ?? false,
      showProgress: json['showProgress'] as bool? ?? true,
      excludedLibraries: (json['excludedLibraries'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$DiscordSettingsModelToJson(
        _DiscordSettingsModel instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'showMediaTitle': instance.showMediaTitle,
      'showProgress': instance.showProgress,
      'excludedLibraries': instance.excludedLibraries,
    };
