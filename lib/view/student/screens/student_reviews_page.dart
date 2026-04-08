import 'package:flutter/material.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/core/widgets/app_text.dart';

class StudentReviewsPage extends StatelessWidget {
  const StudentReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const AppText('review'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ConstSize.grid * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText(
              'review',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: ConstSize.grid * 2),
            ..._placeholderReviews.map(
              (review) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ReviewCard(
                  from: review['from']!,
                  text: review['text']!,
                ),
              ),
            ),
            const SizedBox(height: ConstSize.grid * 2),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.from, required this.text});

  final String from;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ConstSize.grid * 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ConstSize.radiusM),
        border: Border.all(color: ConstColor.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(from, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            text,
            style: TextStyle(color: ConstColor.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}

const List<Map<String, String>> _placeholderReviews = [
  {
    'from': 'Student A',
    'text': 'Great session! Helped me speak more confidently.',
  },
  {'from': 'Student B', 'text': 'Very clear explanations and useful homework.'},
  {
    'from': 'Student C',
    'text': 'Fun and practical practice with good feedback.',
  },
];
