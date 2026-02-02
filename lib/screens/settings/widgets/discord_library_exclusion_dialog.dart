import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fladder/models/view_model.dart';
import 'package:fladder/providers/settings/discord_settings_provider.dart';
import 'package:fladder/screens/shared/adaptive_dialog.dart';
import 'package:fladder/util/localization_helper.dart';

Future<void> showDiscordLibraryExclusionDialog(BuildContext context, List<ViewModel> views) {
  return showDialogAdaptive(
    context: context,
    builder: (context) => DiscordLibraryExclusionDialog(views: views),
  );
}

class DiscordLibraryExclusionDialog extends ConsumerWidget {
  const DiscordLibraryExclusionDialog({
    super.key,
    required this.views,
  });

  final List<ViewModel> views;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discordSettings = ref.watch(discordSettingsProvider);

    return AlertDialog(
      title: Text(context.localized.discordExcludedLibraries),
      content: SizedBox(
        width: 400,
        child: views.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(context.localized.discordNoLibrariesFound),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: views.length,
                itemBuilder: (context, index) {
                  final view = views[index];
                  final isExcluded = discordSettings.excludedLibraries.contains(view.id);
                  return CheckboxListTile(
                    value: isExcluded,
                    title: Text(view.name),
                    onChanged: (value) {
                      ref.read(discordSettingsProvider.notifier).toggleLibraryExclusion(view.id);
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.localized.close),
        ),
      ],
    );
  }
}
