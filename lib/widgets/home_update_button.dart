import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../l10n/app_localizations.dart';

class HomeUpdateButton extends StatefulWidget {
  const HomeUpdateButton({super.key});

  @override
  State<HomeUpdateButton> createState() => _HomeUpdateButtonState();
}

class _HomeUpdateButtonState extends State<HomeUpdateButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleUpdate() async {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.isUpdating) return;
    
    _controller.forward(from: 0.0);
    await appState.refreshStations();
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color contentColor = isDark ? const Color(0xFF333333) : Colors.black87;
    
    final l10n = AppLocalizations.of(context)!;
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final countdown = appState.countdownRemaining;
        final isUpdating = appState.isUpdating;
        
        return GestureDetector(
          onTap: _handleUpdate,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFFE8DEF8) : const Color(0xFFFFDACB),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.rotate(
                      angle: _controller.value * 3.1415926535, 
                      child: Icon(
                        Icons.autorenew, 
                        size: 20, 
                        color: contentColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isUpdating 
                          ? l10n.updating 
                          : (countdown > 0 ? l10n.updatingIn(countdown.toString()) : l10n.update_stations),
                      style: TextStyle(
                        color: contentColor, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
