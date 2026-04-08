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

  Data({
    this.tutorId,
    this.sessionId,
    this.slotId,
    this.studentId,
    this.slot,
    this.topic,
    this.status,
    this.tutorName,
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
    return data;
  }
}
