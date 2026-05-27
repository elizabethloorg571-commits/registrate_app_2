import 'package:shared_preferences/shared_preferences.dart';

class SharedService {
  static String nombres = "";
  static String apellidos = "";
  static String email = "";
  static String photoUrl = "";
  static String uuid = "";
  static String celular = "";
  static String fechaCreacion = "";
  static String storeUrl = "";
  static String storeVersion = "";
  static String storeReleaseNotes = "";
  static bool isTablet = false;
  static String userUpdatedAt = "";

  static void clearData() {
    nombres = "";
    apellidos = "";
    email = "";
    photoUrl = "";
    uuid = "";
    celular = "";
    fechaCreacion = "";
    isTablet = false;
  }

  static Future<void> logOut() async {
    clearData();
    cleanData();
  }

  static Future<void> cleanData() async {
    final prefs = await SharedPreferences.getInstance();
    final bool showTour = prefs.getBool("showTour") ?? true;
    final bool isProfileViewUnseen =
        prefs.getBool('isProfileViewUnseen') ?? true;
    // final dontAskAgainRegisterDevice =
    //     prefs.getBool("dontAskAgainRegisterDevice") ?? false;
    prefs.clear();
    prefs.setBool("showTour", showTour);
    prefs.setBool('hasLoggedIn', true);
    prefs.setBool("hasOnboarded", true);
    prefs.setBool("hasSplashed", true);
    prefs.setBool('isProfileViewUnseen', isProfileViewUnseen);
    // prefs.setString("preferredLoginMode", "login");
    // prefs.setBool("dontAskAgainRegisterDevice", dontAskAgainRegisterDevice);
  }
}
