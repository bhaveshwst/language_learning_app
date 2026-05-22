class NotificationListingModel {
  String? responseCode;
  String? detail;
  List<String>? data;

  NotificationListingModel({this.responseCode, this.detail, this.data});

  NotificationListingModel.fromJson(Map<String, dynamic> json) {
    responseCode = json['response_code']?.toString();
    detail = json['detail']?.toString();
    if (json['data'] is List) {
      data = (json['data'] as List)
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } else {
      data = <String>[];
    }
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['response_code'] = responseCode;
    map['detail'] = detail;
    map['data'] = data ?? <String>[];
    return map;
  }
}
