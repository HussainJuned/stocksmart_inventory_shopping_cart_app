import 'package:flutter/foundation.dart';
import '../services/hive_service.dart';

class SettingsProvider extends ChangeNotifier {
  final HiveService _hiveService = HiveService();

  static const String _keyShowQuantityPopup = 'show_quantity_popup';

  bool _showQuantityPopup = true;
  bool get showQuantityPopup => _showQuantityPopup;

  SettingsProvider() {
    _load();
  }

  void _load() {
    _showQuantityPopup =
        _hiveService.getPreference(_keyShowQuantityPopup, defaultValue: true) as bool;
  }

  Future<void> setShowQuantityPopup(bool value) async {
    _showQuantityPopup = value;
    await _hiveService.setPreference(_keyShowQuantityPopup, value);
    notifyListeners();
  }
}
