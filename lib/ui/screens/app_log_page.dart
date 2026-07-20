import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:youbike/core/l10n/app_localizations.dart';
import 'package:youbike/core/theme/brand_colors.dart';
import 'package:youbike/core/utils/log_service.dart';

class AppLogPage extends StatefulWidget {
  const AppLogPage({super.key});

  @override
  State<AppLogPage> createState() => _AppLogPageState();
}

class _AppLogPageState extends State<AppLogPage> {
  List<Map<String, dynamic>> _logs = [];

  @override
  void initState() {
    super.initState();
    final logService = LogService();
    logService.loadAppLogs().then((_) {
      if (mounted) setState(() => _logs = List.from(logService.appLogs));
    });
  }

  Future<void> _clearLogs() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.clear_logs_confirm_title),
        content: Text(l10n.clear_logs_confirm_content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.confirm,
                style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await LogService().clearAppLogs();
      setState(() => _logs = []);
      if (mounted) Fluttertoast.showToast(msg: l10n.logs_cleared);
    }
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'ERROR':
        return BrandColors.logError;
      case 'WARN':
        return BrandColors.logWarn;
      case 'INFO':
        return BrandColors.logInfo;
      default:
        return Colors.grey;
    }
  }

  IconData _levelIcon(String level) {
    switch (level) {
      case 'ERROR':
        return Icons.error_outline;
      case 'WARN':
        return Icons.warning_amber_outlined;
      case 'INFO':
        return Icons.info_outline;
      default:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(l10n.settings_logs),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _clearLogs,
            tooltip: l10n.clear_all_logs,
          ),
        ],
      ),
      body: SafeArea(
        child: _logs.isEmpty
            ? Center(
                child: Text(
                  l10n.no_logs,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _logs.length,
                itemBuilder: (_, i) {
                  final log = _logs[i];
                  final level = log['level'] as String? ?? 'INFO';
                  final tag = log['tag'] as String? ?? '';
                  final message = log['message'] as String? ?? '';
                  final timestamp = log['timestamp'] as String? ?? '';
                  final color = _levelColor(level);

                  return Card(
                    elevation: 0,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    color: cs.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: cs.outlineVariant, width: 0.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(_levelIcon(level), color: color, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color.withAlpha(30),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        tag,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: color,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      timestamp,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              color: cs.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  message,
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(color: cs.onSurface),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
