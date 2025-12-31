import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  RemoteConfigService._internal();
  static final instance = RemoteConfigService._internal();

  final _rc = FirebaseRemoteConfig.instance;

  Future<void> ensureLoaded() async {
    try {
      await _rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(seconds: 1),
      ));

      await _rc.setDefaults({
        'show_deals_wheel': true,
        'show_home_banner': true,
        'home_banner_image': '',
      });

      final bool updated = await _rc.fetchAndActivate();
      print("🔥 RemoteConfig updated: $updated");
      print("🔥 show_home_banner = ${_rc.getBool('show_home_banner')}");
      print("🔥 home_banner_image = ${_rc.getString('home_banner_image')}");
    } catch (e) {
      print("❌ RemoteConfig error: $e");
    }
  }

  bool get showDealsWheel => _rc.getBool('show_deals_wheel');
  bool get showHomeBanner => _rc.getBool('show_home_banner');
  String get homeBannerImage => _rc.getString('home_banner_image');
}
