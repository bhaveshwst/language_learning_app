class ListBookingsStudentModel {
  String? responseCode;
  String? detail;
  List<Data>? data;

  ListBookingsStudentModel({this.responseCode, this.detail, this.data});

  ListBookingsStudentModel.fromJson(Map<String, dynamic> json) {
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
  String? sessionId;
  String? slotId;
  String? studentId;
  String? slot;
  String? topic;
  String? status;
  String? tutorName;
  String? bookingTimeStatus;
  String? tutorTimezone;
  String? viewTimezone;

  Data({
    this.tutorId,
    this.sessionId,
    this.slotId,
    this.studentId,
    this.slot,
    this.topic,
    this.status,
    this.tutorName,
    this.bookingTimeStatus,
    this.tutorTimezone,
    this.viewTimezone,
  });

  Data.fromJson(Map<String, dynamic> json) {
    tutorId = json['tutor_id'];
    sessionId = json['session_id'];
    slotId = (json['slot_id'] ?? json['session_id'])?.toString();
    studentId = json['student_id'];
    slot = json['slot'];
    topic = json['topic'];
    // Backend may send this as `states` (per docs) or `status`.
    status = (json['states'] ?? json['status'])?.toString();
    tutorName = json['tutor_name'];
    bookingTimeStatus = json['booking_time_status'];
    tutorTimezone = json['tutor_timezone'];
    viewTimezone = json['viewer_timezone'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['tutor_id'] = tutorId;
    data['session_id'] = sessionId;
    data['slot_id'] = slotId;
    data['student_id'] = studentId;
    data['slot'] = slot;
    data['topic'] = topic;
    data['status'] = status;
    data['tutor_name'] = tutorName;
    data['booking_time_status'] = bookingTimeStatus;
    data['tutor_timezone'] = tutorTimezone;
    data['viewer_timezone'] = viewTimezone;
    return data;
  }
}
