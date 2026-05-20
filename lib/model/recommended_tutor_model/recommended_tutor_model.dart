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
  String? bio;
  String? targetlanguage;
  String? avaragerating;
  String? country;
  String? imagepath;
  int? likeDislike;

  Tutors({
    this.id,
    this.displayName,
    this.teachesLanguages,
    this.country,
    this.topics,
    this.nextSlot,
    this.bio,
    this.targetlanguage,
    this.avaragerating,
    this.imagepath,
    this.likeDislike,
  });

  bool get isLiked => likeDislike == 1;

  static int? parseLikeDislike(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value == 1 ? 1 : 0;
    if (value is bool) return value ? 1 : 0;
    final normalized = value.toString().trim().toLowerCase();
    if (normalized == '1' || normalized == 'true' || normalized == 'yes') {
      return 1;
    }
    return 0;
  }

  Tutors.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    displayName = json['display_name'];
    teachesLanguages = json['teaches_languages'];
    topics = json['topics'].cast<String>();
    nextSlot = json['next_slot'];
    bio = json['bio'];
    targetlanguage = json['target_language'];
    avaragerating = json['average_rating'].toString();
    country = json['country'];
    imagepath = json['upload_image'];
    likeDislike = parseLikeDislike(
      json['like_dislike'] ?? json['likedislike'] ?? json['likeDislike'],
    );
  }

  Tutors copyWith({int? likeDislike}) {
    return Tutors(
      id: id,
      displayName: displayName,
      teachesLanguages: teachesLanguages,
      country: country,
      topics: topics,
      nextSlot: nextSlot,
      bio: bio,
      targetlanguage: targetlanguage,
      avaragerating: avaragerating,
      imagepath: imagepath,
      likeDislike: likeDislike ?? this.likeDislike,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['display_name'] = displayName;
    data['teaches_languages'] = teachesLanguages;
    data['topics'] = topics;
    data['next_slot'] = nextSlot;
    data['bio'] = bio;
    data['target_language'] = targetlanguage;
    data['average_rating'] = avaragerating;
    data['country'] = country;
    data['upload_image'] = imagepath;
    data['like_dislike'] = likeDislike;
    return data;
  }
}
