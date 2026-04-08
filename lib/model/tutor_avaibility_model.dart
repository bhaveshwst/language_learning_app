class TutorAvaibilityModel {
  String? responseCode;
  String? detail;
  List<Data>? data;

  TutorAvaibilityModel({this.responseCode, this.detail, this.data});

  TutorAvaibilityModel.fromJson(Map<String, dynamic> json) {
    responseCode = json['response_code'];
    detail = json['detail'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['response_code'] = responseCode;
    data['detail'] = detail;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  String? tutorId;
  String? date;
  String? startTime;
  String? endTime;

  Data({this.tutorId, this.date, this.startTime, this.endTime});

  Data.fromJson(Map<String, dynamic> json) {
    tutorId = json['tutor_id'];
    date = json['date'];
    startTime = json['start_time'];
    endTime = json['end_time'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['tutor_id'] = tutorId;
    data['date'] = date;
    data['start_time'] = startTime;
    data['end_time'] = endTime;
    return data;
  }
}
