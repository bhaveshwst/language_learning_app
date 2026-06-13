class VerifyOtpModel {
  String? responseCode;
  String? detail;
  Data? data;

  VerifyOtpModel({this.responseCode, this.detail, this.data});

  VerifyOtpModel.fromJson(Map<String, dynamic> json) {
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
  String? accessToken;
  String? tokenType;
  String? tutorid;
  String? studentid;

  Data({this.accessToken, this.tokenType, this.studentid, this.tutorid});

  Data.fromJson(Map<String, dynamic> json) {
    accessToken = json['access_token'];
    tokenType = json['token_type'];
    studentid = json['student_id']?.toString();
    tutorid = json['tutor_id']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['access_token'] = accessToken;
    data['token_type'] = tokenType;
    data['student_id'] = studentid;
    data['tutor_id'] = tutorid;
    return data;
  }
}
