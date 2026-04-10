import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_dialog.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/core/constants/const_string.dart';
import 'package:language_learning_app/core/constants/user_role.dart';
import 'package:language_learning_app/core/constants/utils.dart';
import 'package:language_learning_app/core/widgets/app_dropdown_button2.dart';
import 'package:language_learning_app/core/widgets/app_version_widgets.dart';
import 'package:language_learning_app/provider/profile_common_api/profile_common_api_bloc.dart';
import 'package:language_learning_app/provider/student_profile_create/student_profile_create_bloc.dart';
import 'package:language_learning_app/view/auth/widgets/auth_primary_button.dart';
import 'package:language_learning_app/view/auth/widgets/auth_text_field.dart';

/// Student profile completion page.
/// This duplicates `CompleteProfileScreen` so the fields + API calls match.
class StudentProfileCompletePage extends StatefulWidget {
  const StudentProfileCompletePage({
    super.key,
    required this.language,
    required this.role,
  });

  final AppLanguage language;
  final UserRole role;

  @override
  State<StudentProfileCompletePage> createState() =>
      _StudentProfileCompletePageState();
}

class _StudentProfileCompletePageState
    extends State<StudentProfileCompletePage> {
  String? _timezone;
  String? _primaryLanguage;
  String? _targetLanguage;
  final Set<String> _selectedInterests = {};

  String t(String key) => ConstString.text(widget.language, key);

  final ProfileCommonApiBloc _profileCommonApiBloc = ProfileCommonApiBloc();
  final StudentProfileUpdateBloc _studentProfileUpdateBloc =
      StudentProfileUpdateBloc();

  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _profileCommonApiBloc.add(FetchProfileCommonApi());
    _displayNameController.text = PrefUtils.getname();
    _timezone = PrefUtils.gettimezone() == "" ? null : PrefUtils.gettimezone();
    _primaryLanguage =PrefUtils.getprimarylanguage() == "" ? null : PrefUtils.getprimarylanguage();
    _targetLanguage = PrefUtils.gettargetlanguage() == "" ? null : PrefUtils.gettargetlanguage();
    _selectedInterests.addAll(PrefUtils.getintrested());
    _bioController.text = PrefUtils.getbio();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => _profileCommonApiBloc),
        BlocProvider(create: (context) => _studentProfileUpdateBloc),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            t('profileTitle'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          actions: const [AppVersionAppBarAction()],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: BlocBuilder<ProfileCommonApiBloc, ProfileCommonApiState>(
            builder: (context, state) {
              if (state is ProfileCommonApiInitial) {
                return SizedBox.shrink();
              }
              if (state is ProfileCommonApiLoading) {
                return SizedBox(
                  height: MediaQuery.of(context).size.height / 1.5,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (state is ProfileCommonApiError) {
                return Center(child: Text(state.message));
              }
              if (state is ProfileCommonApiSuccess) {
                return state.profileCommonAPI.data == null
                    ? SizedBox.shrink()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: ConstSize.grid * 3),
                          AuthTextField(
                            hint: t('displayName'),
                            controller: _displayNameController,
                          ),
                          const SizedBox(height: ConstSize.grid * 2),
                          AppDropdownButton2<String>(
                            hintText: t('timezone'),
                            value: _timezone,
                            items: List<String>.from(
                              state.profileCommonAPI.data?.timezone ?? [],
                            ),
                            itemLabelBuilder: (v) => v.toString(),
                            onChanged: (v) => setState(() => _timezone = v),
                          ),
                          const SizedBox(height: ConstSize.grid * 2),
                          AppDropdownButton2<String>(
                            hintText: t('primaryLanguage'),
                            value: _primaryLanguage,
                            items: List<String>.from(
                              state.profileCommonAPI.data?.language ?? [],
                            ),
                            itemLabelBuilder: (v) => v,
                            onChanged: (v) =>
                                setState(() => _primaryLanguage = v),
                          ),
                          const SizedBox(height: ConstSize.grid * 2),
                          AppDropdownButton2<String>(
                            hintText: t('targetLanguage'),
                            value: _targetLanguage,
                            items: List<String>.from(
                              state.profileCommonAPI.data?.language ?? [],
                            ),
                            itemLabelBuilder: (v) => v,
                            onChanged: (v) =>
                                setState(() => _targetLanguage = v),
                          ),
                          const SizedBox(height: ConstSize.grid * 2),
                          Text(
                            t('interests'),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: ConstSize.grid),
                          Wrap(
                            spacing: 3,
                            runSpacing: 0,
                            children: state.profileCommonAPI.data!.interest!
                                .map((interest) {
                                  final selected = _selectedInterests.contains(
                                    interest,
                                  );
                                  return FilterChip(
                                    label: Text(interest),
                                    selected: selected,
                                    onSelected: (value) {
                                      setState(() {
                                        if (value) {
                                          _selectedInterests.add(interest);
                                        } else {
                                          _selectedInterests.remove(interest);
                                        }
                                      });
                                    },
                                    selectedColor: ConstColor.primaryBlue
                                        .withValues(alpha: 0.16),
                                    side: const BorderSide(
                                      color: ConstColor.border,
                                    ),
                                  );
                                })
                                .toList(),
                          ),
                          const SizedBox(height: ConstSize.grid * 2),
                          AuthTextField(
                            hint: t('shortBio'),
                            maxLines: 3,
                            controller: _bioController,
                          ),
                          const SizedBox(height: ConstSize.grid * 3),
                          BlocListener<
                            StudentProfileUpdateBloc,
                            StudentProfileCreateState
                          >(
                            listener: (context, state) async {
                              if (state is StudentProfileCreateInitial) {
                                // no-op
                              } else if (state is StudentProfileCreateLoading) {
                                showDialog(
                                  barrierDismissible: false,
                                  context: context,
                                  builder: (context) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  },
                                );
                              } else if (state is StudentProfileCreateError) {
                                Navigator.pop(context);
                                commonAlertDialog(context, state.message);
                              } else if (state is StudentProfileCreateSuccess) {
                                Navigator.pop(context);

                                // Save locally, same as CompleteProfileScreen.
                                await PrefUtils.setname(
                                  _displayNameController.text.trim(),
                                );
                                await PrefUtils.settimezone(_timezone ?? '');
                                await PrefUtils.setprimarylanguage(
                                  _primaryLanguage ?? '',
                                );
                                await PrefUtils.settargetlanguage(
                                  _targetLanguage ?? '',
                                );
                                await PrefUtils.setintrested(
                                  _selectedInterests.toList(),
                                );
                                await PrefUtils.setbio(
                                  _bioController.text.trim(),
                                );

                                commonAlertDialogwithButton(
                                  context,
                                  "${state.studentCreateProfileModel.detail}",
                                  () {
                                    Navigator.pop(context);
                                    Navigator.pop(context);
                                  },
                                );
                              }
                            },
                            child: AuthPrimaryButton(
                              text: t('continue'),
                              onPressed: () {
                                if (_displayNameController.text
                                    .trim()
                                    .isEmpty) {
                                  commonAlertDialog(
                                    context,
                                    t('enterDisplayNameError'),
                                  );
                                } else if (_timezone == null) {
                                  commonAlertDialog(
                                    context,
                                    t('selectTimezoneError'),
                                  );
                                } else if (_primaryLanguage == null) {
                                  commonAlertDialog(
                                    context,
                                    t('selectPrimaryLanguageError'),
                                  );
                                } else if (_targetLanguage == null) {
                                  commonAlertDialog(
                                    context,
                                    t('selectTargetLanguageError'),
                                  );
                                } else if (_selectedInterests.isEmpty) {
                                  commonAlertDialog(
                                    context,
                                    t('selectInterestsError'),
                                  );
                                } else if (_bioController.text.trim().isEmpty) {
                                  commonAlertDialog(
                                    context,
                                    t('enterShortBioError'),
                                  );
                                } else {
                                  _studentProfileUpdateBloc.add(
                                    StudentProfileCreateProvider(
                                      displayname: _displayNameController.text
                                          .trim(),
                                      timezone: _timezone ?? '',
                                      primarylanguage: _primaryLanguage ?? '',
                                      targetlanguage: _targetLanguage ?? '',
                                      intrested: _selectedInterests.toList(),
                                      bio: _bioController.text.trim(),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      );
              }

              return SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
