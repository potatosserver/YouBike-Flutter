import 'package:flutter/material.dart';
import 'package:youbike/core/theme/brand_colors.dart';
import 'package:youbike/data/services/api_service.dart';
import 'package:youbike/core/l10n/app_localizations.dart';
import 'package:youbike/ui/widgets/app_shapes.dart';

class ElectricBikeDetailsModal extends StatefulWidget {
  final String stationId;
  final String stationName;

  const ElectricBikeDetailsModal({
    super.key,
    required this.stationId,
    required this.stationName,
  });

  @override
  State<ElectricBikeDetailsModal> createState() =>
      _ElectricBikeDetailsModalState();
}

class _ElectricBikeDetailsModalState extends State<ElectricBikeDetailsModal> {
  late Future<List<Map<String, dynamic>>> _bikesFuture;

  @override
  void initState() {
    super.initState();
    _bikesFuture = _fetchBikes();
  }

  Future<List<Map<String, dynamic>>> _fetchBikes() async {
    final api = ApiService();
    return await api.fetchElectricBikeDetails(widget.stationId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _bikesFuture,
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context);
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DragHandle(),
                const SizedBox(height: 20),
                Text(
                  '${l10n.electric_bike_details_title} ${widget.stationName}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (snapshot.connectionState == ConnectionState.waiting)
                  Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: cs.primary),
                        const SizedBox(height: 16),
                        Text(
                          l10n.getting_bike_data,
                          style: TextStyle(color: cs.onSurface),
                        ),
                      ],
                    ),
                  )
                else if (snapshot.hasError)
                  Center(
                    child: Text(
                      '${l10n.electricBikeError} ${snapshot.error}',
                      style: TextStyle(color: cs.error),
                      textAlign: TextAlign.center,
                    ),
                  )
                else if (!snapshot.hasData || snapshot.data!.isEmpty)
                  Center(
                    child: Text(
                      l10n.no_electric_bikes,
                      style: TextStyle(fontSize: 16, color: cs.onSurface),
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
                          leading: const Icon(Icons.electric_bike,
                              color: BrandColors.accentGreen),
                          title: Text(
                            '${l10n.bike_number_label} ${bike['bike_no']}',
                            style: TextStyle(color: cs.onSurface),
                          ),
                          subtitle: Text(
                            '${l10n.pillar_number_label} ${bike['pillar_no']}',
                            style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.6)),
                          ),
                          trailing: Text(
                            '${bike['battery_power']}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: BrandColors.accentGreen,
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
          ),
        );
      },
    );
  }
}
