class ListTutorSlotModel {
  String? responseCode;
  String? detail;
  List<Data>? data;

  ListTutorSlotModel({this.responseCode, this.detail, this.data});

  ListTutorSlotModel.fromJson(Map<String, dynamic> json) {
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
  String? slotid;
  String? startTime;
  String? endTime;
  String? topics;
  String? status;

  Data({this.tutorId, this.date, this.slotid, this.startTime, this.endTime, this.topics, this.status});

  Data.fromJson(Map<String, dynamic> json) {
    tutorId = json['tutor_id'];
    slotid = json['slot_id'];
    date = json['date'];
    startTime = json['start_time'];
    endTime = json['end_time'];
    final rawTopics = json['topics'] ?? json['topic'];
    if (rawTopics is List) {
      topics = rawTopics.map((e) => e?.toString()).whereType<String>().join(', ');
    } else {
      topics = rawTopics?.toString();
    }
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['tutor_id'] = tutorId;
    data['slot_id'] = slotid;
    data['date'] = date;
    data['start_time'] = startTime;
    data['end_time'] = endTime;
    data['topics'] = topics;
    data['status'] = status;
    return data;
  }
}
