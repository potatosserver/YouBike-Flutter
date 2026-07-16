import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import 'package:youbike/core/l10n/app_localizations.dart';

class ChangelogDialog extends StatelessWidget {
  const ChangelogDialog({super.key});

  static const _changelogUrl =
      'https://raw.githubusercontent.com/potatosserver/YouBike-Flutter/main/CHANGELOG.md';

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const ChangelogDialog(),
    );
  }

  String _ensureMarkdownLinks(String text) {
    final urlRegex = RegExp(r'(?<!\()https?://[^\s\n]+', caseSensitive: false);
    return text.replaceAllMapped(
        urlRegex, (m) => '[${m.group(0)}](${m.group(0)})');
  }

  Future<String> _loadChangelog() async {
    try {
      final response = await http.get(Uri.parse(_changelogUrl));
      if (response.statusCode == 200) {
        String content = response.body;
        final firstVersionIndex = content.indexOf('## ');
        if (firstVersionIndex != -1) {
          return content.substring(firstVersionIndex);
        }
        return content;
      }
      return 'Error loading changelog (Status: ${response.statusCode})';
    } catch (e) {
      return 'Error loading changelog: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return FutureBuilder<String>(
      future: _loadChangelog(),
      builder: (context, snapshot) {
        final content = snapshot.data ?? 'Loading...';

        return AlertDialog(
          title: Text(l10n.view_changelog),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: SingleChildScrollView(
              child: Html(
                data: md.markdownToHtml(_ensureMarkdownLinks(content)),
                onLinkTap: (url, _, __) {
                  if (url == null) return;
                  final uri = Uri.parse(url);
                  canLaunchUrl(uri).then((can) {
                    if (can)
                      launchUrl(uri, mode: LaunchMode.externalApplication);
                  });
                },
                style: {
                  "body": Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      fontSize: FontSize(14.0)),
                  "hr": Style(margin: Margins.zero),
                  "h2": Style(
                      margin: Margins.zero,
                      fontSize: FontSize(18.0),
                      fontWeight: FontWeight.bold),
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.close),
            ),
          ],
        );
      },
    );
  }
}
