enum MessageType {
  text,
  image;

  static MessageType fromApi(String? raw) {
    final normalized = (raw ?? '').trim().toLowerCase();
    if (normalized == 'image' || normalized == 'photo') {
      return MessageType.image;
    }
    return MessageType.text;
  }

  String get apiValue => switch (this) {
    MessageType.text => 'text',
    MessageType.image => 'image',
  };
}
