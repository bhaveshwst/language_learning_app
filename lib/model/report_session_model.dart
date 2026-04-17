class ReportSessionModel {
  String? responseCode;
  String? detail;
  ReportSessionData? data;

  ReportSessionModel({this.responseCode, this.detail, this.data});

  ReportSessionModel.fromJson(Map<String, dynamic> json) {
    responseCode = json['response_code']?.toString();
    detail = json['detail']?.toString();
    data = json['data'] != null
        ? ReportSessionData.fromJson(json['data'] as Map<String, dynamic>)
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = <String, dynamic>{};
    map['response_code'] = responseCode;
    map['detail'] = detail;
    if (data != null) {
      map['data'] = data!.toJson();
    }
    return map;
  }
}

class ReportSessionData {
  String? reportId;
  String? createdAt;

  ReportSessionData({this.reportId, this.createdAt});

  ReportSessionData.fromJson(Map<String, dynamic> json) {
    reportId = json['report_id']?.toString();
    createdAt = json['created_at']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = <String, dynamic>{};
    map['report_id'] = reportId;
    map['created_at'] = createdAt;
    return map;
  }
}
