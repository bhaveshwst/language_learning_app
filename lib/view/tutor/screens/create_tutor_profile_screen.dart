import 'package:flutter/material.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/core/widgets/app_dropdown_button2.dart';
import 'package:language_learning_app/core/widgets/app_version_widgets.dart';

class CreateTutorProfileScreen extends StatefulWidget {
  const CreateTutorProfileScreen({super.key});

  @override
  State<CreateTutorProfileScreen> createState() =>
      _CreateTutorProfileScreenState();
}

class _CreateTutorProfileScreenState extends State<CreateTutorProfileScreen> {
  String? _taught;
  String? _spoken;
  final Set<String> _topics = {'Conversation', 'Culture'};

  @override
  Widget build(BuildContext context) {
    final allTopics = ['Conversation', 'Homework', 'Pronunciation', 'Culture'];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create Tutor Profile'),
        backgroundColor: Colors.white,
        actions: const [AppVersionAppBarAction()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ConstSize.grid * 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TextField(
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  hintText: 'Write your teaching approach and strengths',
                ),
              ),
              const SizedBox(height: ConstSize.grid * 2),
              AppDropdownButton2<String>(
                hintText: 'Languages Taught',
                value: _taught,
                items: const ['Korean', 'English', 'Spanish'],
                itemLabelBuilder: (v) => v,
                onChanged: (v) => setState(() => _taught = v),
              ),
              const SizedBox(height: ConstSize.grid * 2),
              AppDropdownButton2<String>(
                hintText: 'Languages Spoken',
                value: _spoken,
                items: const ['English', 'Korean', 'Japanese'],
                itemLabelBuilder: (v) => v,
                onChanged: (v) => setState(() => _spoken = v),
              ),
              const SizedBox(height: ConstSize.grid * 2),
              const Text(
                'Topics',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: ConstSize.grid),
              Wrap(
                spacing: ConstSize.grid,
                runSpacing: ConstSize.grid,
                children: allTopics.map((topic) {
                  final selected = _topics.contains(topic);
                  return FilterChip(
                    label: Text(topic),
                    selected: selected,
                    selectedColor: ConstColor.primaryBlue.withValues(
                      alpha: 0.14,
                    ),
                    side: const BorderSide(color: ConstColor.border),
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _topics.add(topic);
                        } else {
                          _topics.remove(topic);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
