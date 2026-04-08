import 'package:shared_preferences/shared_preferences.dart';

class PrefUtils {
  static SharedPreferences? _preferences;

  // Init SharedPreferences
  static Future init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  // Keys
  static const String accessTokenKey = "access_token";
  static const String name = "name";
  static const String timezone = "timezone";
  static const String primarylanguuage = "primary_language";
  static const String targetlanguage = "target_language";
  static const String bio = "bio";
  static const String intrested = "intrested";
  static const String isPublished = "is_published";
  static const String userTypeKey = "user_type"; // 'student' | 'tutor'
  static const String topics = "topics";
  static const String headline = "headline";
  static const String tutorid = "tutor_id";
  static const String studentid = "student_id";
  // Set Token
  static Future setToken(String token) async {
    await _preferences?.setString(accessTokenKey, token);
  }

  // Set logged-in user type (used for startup routing).
  static Future setUserType(String userType) async {
    await _preferences?.setString(userTypeKey, userType);
  }

  // Get Token
  static String getToken() {
    return _preferences?.getString(accessTokenKey) ?? "";
  }

  // Get logged-in user type (used for startup routing).
  static String getUserType() {
    return _preferences?.getString(userTypeKey) ?? "";
  }

  // Remove Token
  static Future removeToken() async {
    await _preferences?.remove(accessTokenKey);
  }

  static Future setname(String token) async {
    await _preferences?.setString(name, token);
  }
  static String getname() {
    return _preferences?.getString(name) ?? "";
  }
  static Future settimezone(String token) async {
    await _preferences?.setString(timezone, token);
  }
  static String gettimezone() {
    return _preferences?.getString(timezone) ?? "";
  }
  static Future setprimarylanguage(String token) async {
    await _preferences?.setString(primarylanguuage, token);
  }
  static String getprimarylanguage() {
    return _preferences?.getString(primarylanguuage) ?? "";
  }
  static Future settargetlanguage(String token) async {
    await _preferences?.setString(targetlanguage, token);
  }
  static String gettargetlanguage() {
    return _preferences?.getString(targetlanguage) ?? "";
  }
  static Future setbio(String token) async {
    await _preferences?.setString(bio, token);
  }
  static String getbio() {
    return _preferences?.getString(bio) ?? "";
  }
  static Future setintrested(List<String> token) async {
    await _preferences?.setStringList(intrested, token);
  }
  static List<String> getintrested() {
   return _preferences?.getStringList(intrested) ?? [];
  }

  static Future setIsPublished(bool value) async {
    await _preferences?.setBool(isPublished, value);
  }

  static bool getIsPublished() {
    return _preferences?.getBool(isPublished) ?? false;
  }

  static Future setTopics(List<String> value) async {
    await _preferences?.setStringList(topics, value);
  }
  static List<String> getTopics() {
    return _preferences?.getStringList(topics) ?? [];
  }
  static Future setHeadline(String value) async {
    await _preferences?.setString(headline, value);
  }
  static String getHeadline() {
    return _preferences?.getString(headline) ?? "";
  }
  static Future settutorid(String value) async {
    await _preferences?.setString(tutorid, value);
  }
  static String gettutorid() {
    return _preferences?.getString(tutorid) ?? "";
  }
  static Future setstudentid(String value) async {
    await _preferences?.setString(studentid, value);
  }
  static String getstudentid() {
    return _preferences?.getString(studentid) ?? "";
  }

  // Clear All Preferences
  static Future clearPrefs() async {
    await _preferences?.clear();
  }
}