class SessionDeleteModel {
  String? responseCode;
  String? detail;

  SessionDeleteModel({this.responseCode, this.detail});

  SessionDeleteModel.fromJson(Map<String, dynamic> json) {
    responseCode = json['response_code'];
    detail = json['detail'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['response_code'] = responseCode;
    data['detail'] = detail;
    return data;
  }
}
