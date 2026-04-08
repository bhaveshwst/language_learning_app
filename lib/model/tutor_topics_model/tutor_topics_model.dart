class TutorTopicsModel {
  String? responseCode;
  String? detail;
  List<dynamic>? topics;

  TutorTopicsModel({this.responseCode, this.detail, this.topics});

  TutorTopicsModel.fromJson(Map<String, dynamic> json) {
    responseCode = json['response_code'];
    detail = json['detail'];
    topics = json['topics'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['response_code'] = responseCode;
    data['detail'] = detail;
    data['topics'] = topics;
    return data;
  }
}
