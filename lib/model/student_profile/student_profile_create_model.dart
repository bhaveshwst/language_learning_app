class StudentCreateProfileModel {
  String? responseCode;
  String? detail;
  Data? data;

  StudentCreateProfileModel({this.responseCode, this.detail, this.data});

  StudentCreateProfileModel.fromJson(Map<String, dynamic> json) {
    responseCode = json['response_code'];
    detail = json['detail'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['response_code'] = responseCode;
    data['detail'] = detail;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  String? userId;
  String? displayName;
  String? timezone;
  String? primaryLanguage;
  String? targetLanguage;
  List<dynamic>? interests;
  String? bio;

  Data({
    this.userId,
    this.displayName,
    this.timezone,
    this.primaryLanguage,
    this.targetLanguage,
    this.interests,
    this.bio,
  });

  Data.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
    displayName = json['display_name'];
    timezone = json['timezone'];
    primaryLanguage = json['primary_language'];
    targetLanguage = json['target_language'];
    interests = json['interests'];
    bio = json['bio'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['user_id'] = userId;
    data['display_name'] = displayName;
    data['timezone'] = timezone;
    data['primary_language'] = primaryLanguage;
    data['target_language'] = targetLanguage;
    data['interests'] = interests;
    data['bio'] = bio;
    return data;
  }
}
