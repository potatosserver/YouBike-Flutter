import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youbike/core/models/bike_filter_mode.dart';
import 'package:youbike/providers/bike_station_view_model.dart';

class BikeFilterDialog extends StatefulWidget {
  const BikeFilterDialog({super.key});

  @override
  State<BikeFilterDialog> createState() => _BikeFilterDialogState();
}

class _BikeFilterDialogState extends State<BikeFilterDialog> {
  late BikeFilterMode _tempMode;
  late int _tempMinBike;
  late int _tempMinSpace;
  late bool _tempApplyToSearch;

  @override
  void initState() {
    super.initState();
    final vm = Provider.of<BikeStationViewModel>(context, listen: false);
    _tempMode = vm.filterMode;
    _tempMinBike = vm.minBikeCount;
    _tempMinSpace = vm.minEmptySpaces;
    _tempApplyToSearch = vm.applyFilterToSearch;
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<BikeStationViewModel>(context, listen: false);

    return AlertDialog(
      title: const Text('篩選條件'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 搜尋模式套用開關
            SwitchListTile(
              title: const Text('搜尋時也套用'),
              subtitle: const Text('開啟後搜尋結果也會依照下方條件過濾'),
              value: _tempApplyToSearch,
              onChanged: (val) => setState(() => _tempApplyToSearch = val),
            ),
            const Divider(),
            // 車種篩選
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
                child: Text('車種', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            RadioGroup<BikeFilterMode>(
              groupValue: _tempMode,
              onChanged: (val) => setState(() {
                _tempMode = val!;
                // 切換車種模式時重置車輛門檻（不同模式門檻語意不同）
                _tempMinBike = 0;
              }),
              child: const Column(
                children: [
                  RadioListTile<BikeFilterMode>(
                    title: Text('全部車種'),
                    value: BikeFilterMode.all,
                  ),
                  RadioListTile<BikeFilterMode>(
                    title: Text('僅一般車'),
                    value: BikeFilterMode.regularOnly,
                  ),
                  RadioListTile<BikeFilterMode>(
                    title: Text('僅電輔車'),
                    value: BikeFilterMode.electricOnly,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 最低車輛數 — label 依模式變動
            _buildNumberStepper(
              label: _bikeLabelForMode(_tempMode),
              value: _tempMinBike,
              onChanged: (val) => setState(() => _tempMinBike = val),
            ),
            const SizedBox(height: 16),
            // 最低空位數
            _buildNumberStepper(
              label: '最低空位數',
              value: _tempMinSpace,
              onChanged: (val) => setState(() => _tempMinSpace = val),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _tempMode = BikeFilterMode.all;
              _tempMinBike = 0;
              _tempMinSpace = 0;
              _tempApplyToSearch = false;
            });
          },
          child: const Text('重設'),
        ),
        FilledButton(
          onPressed: () {
            vm.setFilter(
              mode: _tempMode,
              minBike: _tempMinBike,
              minSpace: _tempMinSpace,
              applyToSearch: _tempApplyToSearch,
            );
            Navigator.pop(context);
          },
          child: const Text('套用'),
        ),
      ],
    );
  }

  String _bikeLabelForMode(BikeFilterMode mode) {
    switch (mode) {
      case BikeFilterMode.regularOnly:
        return '最低一般車數';
      case BikeFilterMode.electricOnly:
        return '最低電輔車數';
      case BikeFilterMode.all:
        return '最低車輛數（一般+電輔）';
    }
  }

  Widget _buildNumberStepper({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
            ),
            Text('$value', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => onChanged(value + 1),
            ),
          ],
        ),
      ],
    );
  }
}
