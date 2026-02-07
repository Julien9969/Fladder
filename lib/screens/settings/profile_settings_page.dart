import 'package:flutter/material.dart';

import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fladder/jellyfin/jellyfin_open_api.enums.swagger.dart' as enums;
import 'package:fladder/models/seerr_credentials_model.dart';
import 'package:fladder/providers/connectivity_provider.dart';
import 'package:fladder/providers/cultures_provider.dart';
import 'package:fladder/providers/discord_rich_presence_provider.dart';
import 'package:fladder/providers/seerr_user_provider.dart';
import 'package:fladder/providers/settings/discord_settings_provider.dart';
import 'package:fladder/providers/user_provider.dart';
import 'package:fladder/providers/views_provider.dart';
import 'package:fladder/screens/settings/settings_list_tile.dart';
import 'package:fladder/screens/settings/settings_scaffold.dart';
import 'package:fladder/screens/settings/widgets/discord_library_exclusion_dialog.dart';
import 'package:fladder/screens/settings/widgets/password_reset_dialog.dart';
import 'package:fladder/screens/settings/widgets/seerr_connection_dialog.dart';
import 'package:fladder/screens/settings/widgets/settings_label_divider.dart';
import 'package:fladder/screens/settings/widgets/settings_list_group.dart';
import 'package:fladder/screens/shared/authenticate_button_options.dart';
import 'package:fladder/screens/shared/input_fields.dart';
import 'package:fladder/seerr/seerr_models.dart';
import 'package:fladder/util/jellyfin_extension.dart';
import 'package:fladder/util/localization_helper.dart';
import 'package:fladder/widgets/shared/enum_selection.dart';
import 'package:fladder/widgets/shared/item_actions.dart';

@RoutePage()
class ProfileSettingsPage extends ConsumerStatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends ConsumerState<ProfileSettingsPage> {
  String _seerrStatusLabel(
    BuildContext context,
    SeerrCredentialsModel? credentials,
    SeerrUserModel? seerrUser,
  ) {
    if (credentials == null || credentials.serverUrl.isEmpty) return context.localized.seerrNotConfigured;

    if (credentials.sessionCookie.isNotEmpty || credentials.apiKey.isNotEmpty) {
      if (seerrUser == null) {
        return context.localized.seerrLoadingUser;
      }
      final displayName =
          seerrUser.displayName ?? seerrUser.username ?? seerrUser.email ?? context.localized.seerrUnknownUser;
      return context.localized.loggedInAs(displayName);
    }

    return context.localized.none;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final seerrUser = ref.watch(seerrUserProvider);
    final cultures = ref.watch(culturesProvider);
    final discordSettings = ref.watch(discordSettingsProvider);
    final discordService = ref.watch(discordRichPresenceProvider);
    final views = ref.watch(viewsProvider).views;
    final allowedSubModes = {
      enums.SubtitlePlaybackMode.$default,
      enums.SubtitlePlaybackMode.smart,
      enums.SubtitlePlaybackMode.onlyforced,
      enums.SubtitlePlaybackMode.always,
      enums.SubtitlePlaybackMode.none,
    };
    return SettingsScaffold(
      label: context.localized.settingsProfileTitle,
      items: [
        ...settingsListGroup(
          context,
          SettingsLabelDivider(label: context.localized.settingsSecurity),
          [
            SettingsListTile(
              label: Text(context.localized.settingSecurityApplockTitle),
              subLabel: Text(user?.authMethod.name(context) ?? ""),
              onTap: () => showAuthOptionsDialogue(
                context,
                user!,
                (newUser) {
                  ref.read(userProvider.notifier).updateUser(newUser);
                },
              ),
            ),
            SettingsListTile(
              label: Text(context.localized.password),
              onTap: () => openPasswordResetDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...settingsListGroup(
          context,
          SettingsLabelDivider(label: context.localized.subtitles),
          [
            SettingsListTile(
              label: Text(context.localized.settingsProfileSubtitleLanguage),
              trailing: Builder(
                builder: (context) {
                  final currentCulture = cultures.firstWhereOrNull(
                    (element) =>
                        element.threeLetterISOLanguageName?.toLowerCase() ==
                        user?.userConfiguration?.subtitleLanguagePreference?.toLowerCase(),
                  );
                  return EnumBox(
                    current: user?.userConfiguration?.subtitleLanguagePreference == null
                        ? context.localized.none
                        : currentCulture?.displayName ?? context.localized.unknown,
                    itemBuilder: (context) => [
                      ItemActionButton(
                        selected: user?.userConfiguration?.subtitleLanguagePreference == null,
                        label: Text(context.localized.none),
                        action: () {
                          ref.read(userProvider.notifier).updateSubtitleLanguagePreference(null);
                        },
                      ),
                      ...cultures.map(
                        (e) => ItemActionButton(
                          selected: e.threeLetterISOLanguageName?.toLowerCase() ==
                              user?.userConfiguration?.subtitleLanguagePreference?.toLowerCase(),
                          label: Text(e.displayName ?? e.name ?? context.localized.unknown),
                          action: () {
                            ref
                                .read(userProvider.notifier)
                                .updateSubtitleLanguagePreference(e.threeLetterISOLanguageName?.toLowerCase());
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            SettingsListTile(
              label: Text(context.localized.settingsProfileSubtitleMode),
              trailing: EnumBox(
                current: user?.userConfiguration?.subtitleMode?.label(context) ?? context.localized.none,
                itemBuilder: (context) => allowedSubModes
                    .map(
                      (mode) => ItemActionButton(
                        selected: user?.userConfiguration?.subtitleMode == mode,
                        label: Text(mode.label(context)),
                        action: () {
                          ref.read(userProvider.notifier).updateSubtitleMode(mode);
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...settingsListGroup(
          context,
          SettingsLabelDivider(label: context.localized.advanced),
          [
            SettingsListTile(
              label: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 8,
                children: [
                  if (user?.credentials.localUrl?.isNotEmpty == true)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: ref.watch(localConnectionAvailableProvider)
                            ? Colors.greenAccent
                            : Theme.of(context).colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(context.localized.settingsLocalUrlTitle),
                ],
              ),
              subLabel: Text(user?.credentials.localUrl ?? context.localized.none),
              onTap: () {
                openSimpleTextInput(
                  context,
                  user?.credentials.localUrl,
                  (value) => ref.read(userProvider.notifier).setLocalURL(value),
                  context.localized.settingsLocalUrlSetTitle,
                  context.localized.settingsLocalUrlSetDesc,
                );
              },
            ),
            SettingsListTile(
              label: Text(context.localized.seerr),
              subLabel: Text(_seerrStatusLabel(context, user?.seerrCredentials, seerrUser)),
              onTap: () => showSeerrConnectionDialog(context),
            ),
          ],
        ),
        if (discordService.isSupported) ...[
          const SizedBox(height: 16),
          ...settingsListGroup(
            context,
            SettingsLabelDivider(label: context.localized.discordRichPresence),
            [
              SettingsListTile(
                label: Text(context.localized.discordEnabled),
                subLabel: Text(context.localized.discordEnabledDesc),
                trailing: Switch(
                  value: discordSettings.enabled,
                  onChanged: (value) {
                    ref.read(discordSettingsProvider.notifier).setEnabled(value);
                  },
                ),
                onTap: () {
                  ref.read(discordSettingsProvider.notifier).setEnabled(!discordSettings.enabled);
                },
              ),
              SettingsListTile(
                label: const Text('Application ID'),
                subLabel: Text(discordSettings.applicationId),
                onTap: discordSettings.enabled
                    ? () {
                        showDialog(
                          context: context,
                          builder: (context) => _ApplicationIdDialog(
                            currentId: discordSettings.applicationId,
                            onSave: (newId) {
                              ref.read(discordSettingsProvider.notifier).setApplicationId(newId);
                            },
                          ),
                        );
                      }
                    : null,
              ),
              SettingsListTile(
                label: Text(context.localized.discordExcludedLibraries),
                subLabel: Text(
                  discordSettings.excludedLibraries.isEmpty
                      ? context.localized.none
                      : context.localized.discordExcludedLibrariesCount(discordSettings.excludedLibraries.length),
                ),
                onTap: discordSettings.enabled ? () => showDiscordLibraryExclusionDialog(context, views) : null,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ApplicationIdDialog extends StatefulWidget {
  final String currentId;
  final void Function(String) onSave;

  const _ApplicationIdDialog({
    required this.currentId,
    required this.onSave,
  });

  @override
  State<_ApplicationIdDialog> createState() => _ApplicationIdDialogState();
}

class _ApplicationIdDialogState extends State<_ApplicationIdDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Discord Application ID'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter your Discord Application ID. You can create one at:',
          ),
          const SizedBox(height: 8),
          const SelectableText(
            'https://discord.com/developers/applications',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Application ID',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            widget.onSave(_controller.text.trim());
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
