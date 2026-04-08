class BookSessionModel {
  String? responseCode;
  String? detail;
  Data? data;

  BookSessionModel({this.responseCode, this.detail, this.data});

  BookSessionModel.fromJson(Map<String, dynamic> json) {
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
  String? bookingId;
  String? tutorId;
  String? slotId;
  String? startstime;
  String? endstime;
  String? status;
  String? topic;
  String? date;

  Data({
    this.bookingId,
    this.tutorId,
    this.slotId,
    this.startstime,
    this.endstime,
    this.topic,
    this.date,
    this.status,
  });

  Data.fromJson(Map<String, dynamic> json) {
    bookingId = json['booking_id'];
    tutorId = json['tutor_id'];
    slotId = json['slot_id'];
    startstime = json['start_at'];
    endstime = json['end_at'];
    topic = json['topic'];
    date = json['date'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['booking_id'] = bookingId;
    data['tutor_id'] = tutorId;
    data['slot_id'] = slotId;
    data['start_at'] = startstime;
    data['end_at'] = endstime;
    data['topic'] = topic;
    data['date'] = date;
    data['status'] = status;
    return data;
  }
}
