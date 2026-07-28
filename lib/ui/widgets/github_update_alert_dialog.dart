import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youbike/core/l10n/app_localizations.dart';
import 'package:youbike/core/services/update_checker_service.dart';

class GithubUpdateAlertDialog extends StatelessWidget {
  final GithubReleaseInfo release;

  const GithubUpdateAlertDialog({super.key, required this.release});

  static Future<void> show(BuildContext context, GithubReleaseInfo release) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GithubUpdateAlertDialog(release: release),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l10n.update_available),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.update_available}: ${release.tagName}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              release.body.isNotEmpty ? release.body : l10n.release_details_available,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
        ElevatedButton(
          onPressed: () async {
            final uri = Uri.parse(release.htmlUrl);
            try {
              // 直接呼叫 launchUrl，不先檢查 canLaunchUrl
              // 在許多 Android 版本上，canLaunchUrl 會因為 queries 缺失而回傳 false
              // 但直接 launchUrl 配合 externalApplication 模式通常能成功
              await launchUrl(
                uri, 
                mode: LaunchMode.externalApplication,
              );
            } catch (e) {
              debugPrint('Error launching URL: $e');
            }
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: Text(l10n.open_github),
        ),
      ],
    );
  }
}
