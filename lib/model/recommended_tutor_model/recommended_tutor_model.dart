class RecommendedTutorModel {
  String? responseCode;
  dynamic matchLanguage;
  dynamic matchValue;
  String? detail;
  Data? data;

  RecommendedTutorModel({
    this.responseCode,
    this.matchLanguage,
    this.matchValue,
    this.detail,
    this.data,
  });

  RecommendedTutorModel.fromJson(Map<String, dynamic> json) {
    responseCode = json['response_code'];
    matchLanguage = json['match_language'];
    matchValue = json['match_value'];
    detail = json['detail'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['response_code'] = responseCode;
    data['match_language'] = matchLanguage;
    data['match_value'] = matchValue;
    data['detail'] = detail;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  List<Tutors>? tutors;

  Data({this.tutors});

  Data.fromJson(Map<String, dynamic> json) {
    if (json['tutors'] != null) {
      tutors = <Tutors>[];
      json['tutors'].forEach((v) {
        tutors!.add(Tutors.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (tutors != null) {
      data['tutors'] = tutors!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Tutors {
  String? id;
  String? displayName;
  String? teachesLanguages;
  List<dynamic>? topics;
  String? nextSlot;

  Tutors({
    this.id,
    this.displayName,
    this.teachesLanguages,
    this.topics,
    this.nextSlot,
  });

  Tutors.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    displayName = json['display_name'];
    teachesLanguages = json['teaches_languages'];
    topics = json['topics'].cast<String>();
    nextSlot = json['next_slot'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['display_name'] = displayName;
    data['teaches_languages'] = teachesLanguages;
    data['topics'] = topics;
    data['next_slot'] = nextSlot;
    return data;
  }
}
