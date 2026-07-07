import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';

class ElectricBikeDetailsModal extends StatelessWidget {
  final String stationId;
  final String stationName;

  const ElectricBikeDetailsModal({
    super.key,
    required this.stationId,
    required this.stationName,
  });

  Future<List<Map<String, dynamic>>> _fetchBikes() async {
    final api = ApiService();
    return await api.fetchElectricBikeDetails(stationId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchBikes(),
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context)!;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "${l10n.electric_bike_details_title} $stationName",
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (snapshot.connectionState == ConnectionState.waiting)
                Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.getting_bike_data,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                    ],
                  ),
                )
              else if (snapshot.hasError)
                Center(
                  child: Text(
                    "${l10n.electricBikeError} ${snapshot.error}",
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                )
              else if (!snapshot.hasData || snapshot.data!.isEmpty)
                Center(
                  child: Text(
                    l10n.no_electric_bikes,
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final bike = snapshot.data![index];
                    return Card(
                      color: theme.cardColor,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.electric_bike, color: Colors.green),
                        title: Text(
                          "${l10n.bike_number_label} ${bike['bike_no']}",
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          "${l10n.pillar_number_label} ${bike['pillar_no']}",
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        trailing: Text(
                          "${bike['battery_power']}%",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }
}
