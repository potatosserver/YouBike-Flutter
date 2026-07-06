import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../l10n/l10n_helper.dart';


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
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchBikes(),
      builder: (context, snapshot) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
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
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "${L10n.t(context, 'electricBikeDetailsTitle')} $stationName",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (snapshot.connectionState == ConnectionState.waiting)
                Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(L10n.t(context, 'loading')),
                    ],
                  ),
                )
              else if (snapshot.hasError)
                Center(
                  child: Text(
                    "${L10n.t(context, 'electricBikeError')} ${snapshot.error}",
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                )
              else if (!snapshot.hasData || snapshot.data!.isEmpty)
                Center(
                  child: Text(
                    L10n.t(context, 'noElectricBikes'),
                    style: const TextStyle(fontSize: 16),
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
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.electric_bike, color: Colors.green),
                        title: Text("${L10n.t(context, 'bikeNumber')} ${bike['bike_no']}"),
                        subtitle: Text("${L10n.t(context, 'pillarNumber')} ${bike['pillar_no']}"),
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
