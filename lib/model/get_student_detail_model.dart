class GetStudentDetailsModel {
  String? responseCode;
  int? zegoAppID;
  String? detail;
  Data? data;

  GetStudentDetailsModel({this.responseCode, this.detail, this.data, this.zegoAppID});

  GetStudentDetailsModel.fromJson(Map<String, dynamic> json) {
    responseCode = json['response_code'];
    zegoAppID = json['zego_app_id'];
    detail = json['detail'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['response_code'] = responseCode;
    data['zego_app_id'] = zegoAppID;
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
  String? imagepath;

  Data({
    this.userId,
    this.displayName,
    this.timezone,
    this.primaryLanguage,
    this.targetLanguage,
    this.interests,
    this.bio,
    this.imagepath,
  });

  Data.fromJson(Map<String, dynamic> json) {
    userId = json['user_id']?.toString();
    displayName = json['display_name'];
    timezone = json['timezone'];
    primaryLanguage = json['primary_language'];
    targetLanguage = json['target_language'];
    interests = json['interests'];
    bio = json['bio'];
    imagepath = json['upload_image'];
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
    data['upload_image'] = imagepath;
    return data;
  }
}
