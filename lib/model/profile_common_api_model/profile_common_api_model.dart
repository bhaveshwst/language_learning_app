class ProfileCommonAPI {
  String? responseCode;
  String? responseMsg;
  Data? data;

  ProfileCommonAPI({this.responseCode, this.responseMsg, this.data});

  ProfileCommonAPI.fromJson(Map<String, dynamic> json) {
    responseCode = json['response_code'];
    responseMsg = json['response_msg'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['response_code'] = responseCode;
    data['response_msg'] = responseMsg;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  List<dynamic>? language;
  List<dynamic>? timezone;
  List<dynamic>? interest;

  Data({this.language, this.timezone, this.interest});

  Data.fromJson(Map<String, dynamic> json) {
    language = json['language'];;
    timezone = json['Timezone'];;
    interest = json['Interest'];;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['language'] = language;
    data['Timezone'] = timezone;
    data['Interest'] = interest;
    return data;
  }
}
