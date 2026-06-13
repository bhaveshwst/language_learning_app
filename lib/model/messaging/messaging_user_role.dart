enum MessagingUserRole {
  student,
  tutor;

  bool get isStudent => this == MessagingUserRole.student;

  bool get isTutor => this == MessagingUserRole.tutor;
}
