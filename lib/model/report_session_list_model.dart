class ReportSessionListModel {
  String? responseCode;
  String? detail;
  List<ReportSessionListItem>? data;

  ReportSessionListModel({this.responseCode, this.detail, this.data});

  ReportSessionListModel.fromJson(Map<String, dynamic> json) {
    responseCode = json['response_code']?.toString();
    detail = json['detail']?.toString();
    if (json['data'] is List) {
      data = (json['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(ReportSessionListItem.fromJson)
          .toList();
    } else {
      data = <ReportSessionListItem>[];
    }
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['response_code'] = responseCode;
    map['detail'] = detail;
    map['data'] = (data ?? <ReportSessionListItem>[])
        .map((e) => e.toJson())
        .toList();
    return map;
  }
}

class ReportSessionListItem {
  String? reportId;
  String? studentId;
  String? tutorId;
  String? tutorName;
  String? sessionId;
  String? reason;
  String? status;
  String? createdAt;

  ReportSessionListItem({
    this.reportId,
    this.studentId,
    this.tutorId,
    this.tutorName,
    this.sessionId,
    this.reason,
    this.status,
    this.createdAt,
  });

  ReportSessionListItem.fromJson(Map<String, dynamic> json) {
    reportId = json['report_id']?.toString();
    studentId = json['student_id']?.toString();
    tutorId = json['tutor_id']?.toString();
    tutorName = json['tutor_name']?.toString();
    sessionId = json['session_id']?.toString();
    reason = json['reason']?.toString();
    status = json['status']?.toString();
    createdAt = json['created_at']?.toString();
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['report_id'] = reportId;
    map['student_id'] = studentId;
    map['tutor_id'] = tutorId;
    map['tutor_name'] = tutorName;
    map['session_id'] = sessionId;
    map['reason'] = reason;
    map['status'] = status;
    map['created_at'] = createdAt;
    return map;
  }
}
