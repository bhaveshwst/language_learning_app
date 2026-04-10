import 'package:flutter/material.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/core/widgets/app_version_widgets.dart';

class PublishedListingPreviewScreen extends StatelessWidget {
  const PublishedListingPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Published Listing Preview'),
        backgroundColor: Colors.white,
        actions: const [AppVersionAppBarAction()],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(ConstSize.grid * 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(ConstSize.grid * 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(ConstSize.radiusL),
                  border: Border.all(color: ConstColor.border),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Color(0x1A18B6A6),
                          child: Icon(Icons.person, color: ConstColor.accentTeal),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Mina Park',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Korean Tutor for Teen Learners',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: ConstColor.primaryBlue,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Conversation • Pronunciation • Culture',
                      style: TextStyle(color: ConstColor.textSecondary),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Friendly and structured sessions focused on confidence and practical speaking.',
                      style: TextStyle(color: ConstColor.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ConstColor.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ConstSize.radiusM),
                    ),
                  ),
                  child: const Text('Publish'),
                ),
              ),
              const SizedBox(height: ConstSize.grid),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: ConstColor.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ConstSize.radiusM),
                    ),
                  ),
                  child: const Text('Unpublish'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
