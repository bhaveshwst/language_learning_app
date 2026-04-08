import 'package:flutter/material.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/view/student/screens/booking_screen.dart';

class TutorProfileScreen extends StatelessWidget {
  const TutorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topics = ['Conversation', 'Pronunciation', 'Homework', 'Culture'];
    final slots = ['Today 6:30 PM', 'Today 8:00 PM', 'Tomorrow 9:00 AM'];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          ConstSize.grid * 2,
          ConstSize.grid * 2,
          ConstSize.grid * 2,
          ConstSize.grid * 2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 46,
                backgroundColor: Color(0x1A18B6A6),
                child: Icon(Icons.person, size: 52, color: ConstColor.accentTeal),
              ),
            ),
            const SizedBox(height: ConstSize.grid * 2),
            const Center(
              child: Text(
                'Mina Park',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: ConstSize.grid),
            const Center(
              child: Text(
                'Teaches: Korean, English',
                style: TextStyle(color: ConstColor.textSecondary),
              ),
            ),
            const SizedBox(height: 4),
            const Center(
              child: Text(
                'Speaks: Korean, English, Japanese',
                style: TextStyle(color: ConstColor.textSecondary),
              ),
            ),
            const SizedBox(height: ConstSize.grid * 3),
            const Text(
              'Topics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: ConstSize.grid),
            Wrap(
              spacing: ConstSize.grid,
              runSpacing: ConstSize.grid,
              children: topics
                  .map(
                    (topic) => Chip(
                      label: Text(topic),
                      side: const BorderSide(color: ConstColor.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: ConstSize.grid * 3),
            const Text(
              'Bio',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: ConstSize.grid),
            const Text(
              'Friendly language tutor with 5+ years experience helping teens build confidence in speaking and academic writing.',
              style: TextStyle(height: 1.45, color: ConstColor.textSecondary),
            ),
            const SizedBox(height: ConstSize.grid * 3),
            const Text(
              'Available Slots',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: ConstSize.grid),
            ...slots.map(
              (slot) => Container(
                margin: const EdgeInsets.only(bottom: ConstSize.grid),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(ConstSize.radiusM),
                  border: Border.all(color: ConstColor.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, color: ConstColor.primaryBlue),
                    const SizedBox(width: ConstSize.grid),
                    Text(slot),
                  ],
                ),
              ),
            ),
            const SizedBox(height: ConstSize.grid * 2),
            SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingScreen(
                        tutorName: 'Mina Park',
                        tutorId: '',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ConstColor.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ConstSize.radiusM),
                  ),
                ),
                child: const Text('Book Session'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
