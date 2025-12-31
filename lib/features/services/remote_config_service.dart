import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  RemoteConfigService._internal();
  static final instance = RemoteConfigService._internal();

  final _rc = FirebaseRemoteConfig.instance;

  Future<void> ensureLoaded() async {
    try {
      await _rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 30),  // Increased timeout duration
        minimumFetchInterval: const Duration(minutes: 10), // Increased fetch interval
      ));

      await _rc.setDefaults({
        'show_deals_wheel': true,
        'show_home_banner': true,
        'home_banner_image': '',
      });

      // Fetch and activate configurations
      bool fetched = await _rc.fetchAndActivate();
      if (fetched) {
        print("Remote config activated successfully.");
      } else {
        print("Remote config not activated. Using default values.");
      }
    } catch (e) {
      print("Error fetching remote config: $e");
    }
  }

  bool get showDealsWheel => _rc.getBool('show_deals_wheel');
  bool get showHomeBanner => _rc.getBool('show_home_banner');
  String get homeBannerImage => _rc.getString('home_banner_image');
}
