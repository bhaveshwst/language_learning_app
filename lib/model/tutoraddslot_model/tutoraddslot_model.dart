class TutorAddSlotModel {
  String? responseCode;
  String? detail;
  Data? data;

  TutorAddSlotModel({this.responseCode, this.detail, this.data});

  TutorAddSlotModel.fromJson(Map<String, dynamic> json) {
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
  String? tutorId;
  String? availabilityDate;
  String? startTime;
  String? endTime;
  String? topic;
  String? shortDescription;

  Data({
    this.tutorId,
    this.availabilityDate,
    this.startTime,
    this.endTime,
    this.topic,
    this.shortDescription,
  });

  Data.fromJson(Map<String, dynamic> json) {
    tutorId = json['tutor_id'];
    availabilityDate = json['availability_date'];
    startTime = json['start_time'];
    endTime = json['end_time'];
    topic = json['topic'];
    shortDescription = json['short_description'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['tutor_id'] = tutorId;
    data['availability_date'] = availabilityDate;
    data['start_time'] = startTime;
    data['end_time'] = endTime;
    data['topic'] = topic;
    data['short_description'] = shortDescription;
    return data;
  }
}
