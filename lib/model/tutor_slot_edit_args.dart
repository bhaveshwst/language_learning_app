import 'package:language_learning_app/model/list_tutor_slot_model.dart' as tutor_slots;

/// Arguments for editing an open tutor availability slot.
class TutorSlotEditArgs {
  const TutorSlotEditArgs({
    required this.slotId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.topic,
    required this.shortDescription,
  });

  final String slotId;
  final String date;
  final String startTime;
  final String endTime;
  final String topic;
  final String shortDescription;

  factory TutorSlotEditArgs.fromSlot(tutor_slots.Data slot) {
    return TutorSlotEditArgs(
      slotId: (slot.slotid ?? '').trim(),
      date: (slot.date ?? '').trim(),
      startTime: (slot.startTime ?? '').trim(),
      endTime: (slot.endTime ?? '').trim(),
      topic: (slot.topics ?? '').trim(),
      shortDescription: (slot.shortDescription ?? '').trim(),
    );
  }
}
