class TutorSessionListModel {
  String? responseCode;
  String? detail;
  List<Data>? data;

  TutorSessionListModel({this.responseCode, this.detail, this.data});

  TutorSessionListModel.fromJson(Map<String, dynamic> json) {
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
  String? studentId;
  String? date;
  String? startTime;
  String? endTime;
  String? studentName;
  String? bookingTimeStatus;
  String? slotId;
  String? studentTimezone;
  String? studentprofile;

  Data({
    this.tutorId,
    this.studentId,
    this.date,
    this.startTime,
    this.endTime,
    this.studentName,
    this.bookingTimeStatus,
    this.slotId,
    this.studentTimezone,
    this.studentprofile,
  });

  Data.fromJson(Map<String, dynamic> json) {
    tutorId = json['tutor_id'];
    studentId = json['student_id'];
    date = json['date'];
    startTime = json['start_time'];
    endTime = json['end_time'];
    studentName = json['student_name'];
    bookingTimeStatus = json['booking_time_status'];
    slotId = json['slot_id'];
    studentTimezone = json['student_timezone'];
    studentprofile = json['student_profile'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['tutor_id'] = tutorId;
    data['student_id'] = studentId;
    data['date'] = date;
    data['start_time'] = startTime;
    data['end_time'] = endTime;
    data['student_name'] = studentName;
    data['booking_time_status'] = bookingTimeStatus;
    data['slot_id'] = slotId;
    data['student_timezone'] = studentTimezone;
    data['student_profile'] = studentprofile;
    return data;
  }
}
