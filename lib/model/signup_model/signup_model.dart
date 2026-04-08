class SignupModel {
  String? responseCode;
  String? detail;

  SignupModel({this.responseCode, this.detail,});

  SignupModel.fromJson(Map<String, dynamic> json) {
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