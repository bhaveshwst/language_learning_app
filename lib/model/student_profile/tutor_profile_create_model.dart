class TutorCreateProfileModel {
  String? responseCode;
  String? detail;
  Data? data;

  TutorCreateProfileModel({this.responseCode, this.detail, this.data});

  TutorCreateProfileModel.fromJson(Map<String, dynamic> json) {
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
  String? name;
  String? headline;
  String? bio;
  String? languagesTaught;
  String? languagesSpoken;
  List<dynamic>? topics;
  bool? isPublished;

  Data({
    this.userId,
    this.name,
    this.headline,
    this.bio,
    this.languagesTaught,
    this.languagesSpoken,
    this.topics,
    this.isPublished,
  });

  Data.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
    name = json['name'];
    headline = json['headline'];
    bio = json['bio'];
    languagesTaught = json['languages_taught'];
    languagesSpoken = json['languages_spoken'];
    topics = json['topics'];
    isPublished = json['is_published'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['user_id'] = userId;
    data['name'] = name;
    data['headline'] = headline;
    data['bio'] = bio;
    data['languages_taught'] = languagesTaught;
    data['languages_spoken'] = languagesSpoken;
    data['topics'] = topics;
    data['is_published'] = isPublished;
    return data;
  }
}
