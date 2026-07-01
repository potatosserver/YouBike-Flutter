import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/app_theme.dart';

class RouteDetailPanel extends StatelessWidget {
  final List<String> steps;
  final String destination;

  const RouteDetailPanel({
    super.key, 
    required this.steps, 
    required this.destination
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: appState.isDarkMode ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.directions_walk, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "前往 $destination",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 32),
          ...steps.asMap().entries.map((entry) {
            int idx = entry.key;
            String step = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: idx == 0 ? AppColors.primary : Colors.grey[300],
                        child: Text(
                          "${idx + 1}",
                          style: TextStyle(
                            fontSize: 10, 
                            color: idx == 0 ? Colors.white : Colors.black54
                          ),
                        ),
                      ),
                      if (idx != steps.length - 1)
                        Container(width: 2, height: 20, color: Colors.grey[300]),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      step,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
