import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../l10n/app_localizations.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    return Material(
      color: theme.colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              l10n.loading_prefix(appState.loadingProgress.toString()),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Color(0xFF007BFF),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: theme.dividerColor,
                  width: 1,
                ),
              ),
              child: Text(
                _translateNotice(context, appState.currentNotice),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _translateNotice(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'init_starting': return l10n.init_starting;
      case 'init_locating': return l10n.init_locating;
      case 'init_syncing': return l10n.init_syncing;
      case 'init_updating': return l10n.init_updating;
      case 'init_success': return l10n.init_success;
      case 'notice_no_speed': return l10n.notice_no_speed;
      case 'notice_no_sidewalk': return l10n.notice_no_sidewalk;
      case 'notice_no_phone': return l10n.notice_no_phone;
      case 'notice_no_brake': return l10n.notice_no_brake;
      case 'notice_seat_height': return l10n.notice_seat_height;
      case 'notice_lights_work': return l10n.notice_lights_work;
      case 'notice_insurance': return l10n.notice_insurance;
      case 'notice_take_belongings': return l10n.notice_take_belongings;
      default: return key;
    }
  }
}
