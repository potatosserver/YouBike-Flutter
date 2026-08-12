import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youbike/core/l10n/app_localizations.dart';
import 'package:youbike/data/services/app_config_service.dart';
import 'package:youbike/ui/widgets/radio_dot.dart';

class RefreshIntervalSelectionScreen extends StatelessWidget {
  const RefreshIntervalSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final config = Provider.of<AppConfigService>(context);
    final cs = Theme.of(context).colorScheme;

    final options = [
      {'value': 15, 'label': l10n.refresh_interval_15s, 'warning': l10n.refresh_interval_15s_warning},
      {'value': 30, 'label': l10n.refresh_interval_30s},
      {'value': 60, 'label': l10n.refresh_interval_1m},
      {'value': 120, 'label': l10n.refresh_interval_2m},
      {'value': 180, 'label': l10n.refresh_interval_3m},
      {'value': 300, 'label': l10n.refresh_interval_5m},
    ];

    Future<void> handleSelection(int value, String label, {String? warning}) async {
      if (warning != null) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.settings_refresh_interval),
            content: Text(warning),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.confirm),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
      }
      config.setRefreshInterval(value);
      // Don't pop - stay on screen like Language/Theme selection
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(l10n.settings_refresh_interval),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        children: [
          for (int i = 0; i < options.length; i++) ...[
            RadioDot(
              label: options[i]['label'] as String,
              isSelected: config.refreshInterval == options[i]['value'],
              onTap: () => handleSelection(
                options[i]['value'] as int,
                options[i]['label'] as String,
                warning: options[i]['warning'] as String?,
              ),
            ),
            if (i < options.length - 1) const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}