import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youbike/core/l10n/app_localizations.dart';
import 'package:youbike/core/services/update_checker_service.dart';

class GithubUpdateDialog extends StatefulWidget {
  final GithubReleaseInfo release;

  const GithubUpdateDialog({super.key, required this.release});

  static Future<void> show(BuildContext context, GithubReleaseInfo release) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GithubUpdateDialog(release: release),
    );
  }

  @override
  State<GithubUpdateDialog> createState() => _GithubUpdateDialogState();
}

enum GithubUpdateStep {
  details,
  downloading,
  readyToInstall,
  error,
  manualDownload
}

class _GithubUpdateDialogState extends State<GithubUpdateDialog> {
  GithubUpdateStep _step = GithubUpdateStep.details;
  double _progress = 0.0;
  String? _statusText;
  String? _errorText;
  String? _apkPath;
  String? _architecture;
  final UpdateCheckerService _updateService = UpdateCheckerService();

  @override
  void initState() {
    super.initState();
    _determineArchitecture();
  }

  Future<void> _determineArchitecture() async {
    final arch = await _updateService.getArchitecture();
    if (mounted) {
      setState(() {
        _architecture = arch;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.update_available),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.55,
        ),
        child: SingleChildScrollView(
          child: SizedBox(width: double.infinity, child: _buildContent(l10n)),
        ),
      ),
      actions: _buildActions(context, l10n),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    switch (_step) {
      case GithubUpdateStep.downloading:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_statusText ?? l10n.downloading_update),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: _progress),
          ],
        );
      case GithubUpdateStep.readyToInstall:
        return Text(l10n.download_completed_install);
      case GithubUpdateStep.manualDownload:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.no_compatible_apk),
            const SizedBox(height: 16),
            Text(l10n.manual_download_github),
            const SizedBox(height: 8),
            SelectableText(widget.release.htmlUrl),
          ],
        );
      case GithubUpdateStep.error:
        return Text(
          _errorText ?? l10n.update_check_failed,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        );
      case GithubUpdateStep.details:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l10n.update_available}: ${widget.release.tagName}'),
            const SizedBox(height: 16),
            if (widget.release.body.isNotEmpty)
              Text(widget.release.body)
            else
              Text(l10n.release_details_available),
          ],
        );
    }
  }

  List<Widget> _buildActions(BuildContext context, AppLocalizations l10n) {
    if (_step == GithubUpdateStep.downloading) {
      return [];
    }

    switch (_step) {
      case GithubUpdateStep.error:
        return [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text(l10n.close)),
          ElevatedButton(onPressed: _startDownload, child: Text(l10n.retry)),
        ];
      case GithubUpdateStep.readyToInstall:
        return [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text(l10n.close)),
          ElevatedButton(onPressed: _installUpdate, child: Text(l10n.install)),
        ];
      case GithubUpdateStep.manualDownload:
        return [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text(l10n.close)),
          ElevatedButton(
              onPressed: _openReleasePage, child: Text(l10n.open_github)),
        ];
      case GithubUpdateStep.details:
      default:
        return [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text(l10n.close)),
          TextButton(
              onPressed: _openReleasePage, child: Text(l10n.release_notes)),
          ElevatedButton(onPressed: _startDownload, child: Text(l10n.download)),
        ];
    }
  }

  Future<void> _startDownload() async {
    final l10n = AppLocalizations.of(context);

    if (_architecture == null) {
      setState(() {
        _step = GithubUpdateStep.manualDownload;
      });
      return;
    }

    setState(() {
      _step = GithubUpdateStep.downloading;
      _progress = 0.0;
      _statusText = l10n.preparing_download;
      _errorText = null;
    });

    try {
      final String? apkPath = await _updateService.downloadGithubUpdate(
        widget.release,
        _architecture!,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _progress = progress;
            });
          }
        },
        onStatus: (status) {
          if (mounted) {
            setState(() {
              _statusText = status;
            });
          }
        },
        onError: (message) {
          if (mounted) {
            setState(() {
              _step = GithubUpdateStep.error;
              _errorText = message;
            });
          }
        },
      );

      if (apkPath != null && mounted) {
        setState(() {
          _apkPath = apkPath;
          _step = GithubUpdateStep.readyToInstall;
          _statusText = l10n.download_completed_install;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _step = GithubUpdateStep.error;
          _errorText = error.toString();
        });
      }
    }
  }

  Future<void> _installUpdate() async {
    if (_apkPath == null) {
      await _startDownload();
      return;
    }

    await _updateService.installFromPath(_apkPath!);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _openReleasePage() async {
    final uri = Uri.parse(widget.release.htmlUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
