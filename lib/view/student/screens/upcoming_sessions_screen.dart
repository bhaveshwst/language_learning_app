import 'package:flutter/material.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/core/widgets/app_text.dart';

class UpcomingSessionsScreen extends StatelessWidget {
  const UpcomingSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(ConstSize.grid * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText(
              'upcomingSessionsTitle',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: ConstSize.grid * 2),
            _SessionCard(
              tutorName: 'Mina Park',
              time: 'Today, 6:30 PM',
              onJoin: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Open sessions tab to join live class.'),
                  ),
                );
              },
            ),
            const SizedBox(height: ConstSize.grid * 2),
            _SessionCard(
              tutorName: 'Daniel Kim',
              time: 'Tomorrow, 9:00 AM',
              onJoin: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Open sessions tab to join live class.'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.tutorName,
    required this.time,
    required this.onJoin,
  });

  final String tutorName;
  final String time;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ConstSize.grid * 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ConstSize.radiusL),
        border: Border.all(color: ConstColor.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: ConstColor.accentTeal.withValues(alpha: 0.16),
                child: const Icon(Icons.person, color: ConstColor.accentTeal),
              ),
              const SizedBox(width: ConstSize.grid),
              Text(
                tutorName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: ConstSize.grid),
          Text(
            time,
            style: const TextStyle(
              color: ConstColor.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ConstSize.grid * 2),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onJoin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ConstColor.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ConstSize.radiusM),
                    ),
                  ),
                  child: const AppText('join'),
                ),
              ),
              const SizedBox(width: ConstSize.grid),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: ConstColor.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ConstSize.radiusM),
                    ),
                  ),
                  child: const AppText('cancel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
