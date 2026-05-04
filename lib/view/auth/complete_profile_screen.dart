import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_dialog.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/core/constants/const_string.dart';
import 'package:language_learning_app/core/constants/timezone_helper.dart';
import 'package:language_learning_app/core/constants/user_role.dart';
import 'package:language_learning_app/core/constants/utils.dart';
import 'package:language_learning_app/core/widgets/app_dropdown_button2.dart';
import 'package:language_learning_app/provider/profile_common_api/profile_common_api_bloc.dart';
import 'package:language_learning_app/provider/student_profile_create/student_profile_create_bloc.dart';
import 'package:language_learning_app/provider/tutor_profile_create/tutor_profile_create_bloc.dart';
import 'package:language_learning_app/view/auth/widgets/auth_primary_button.dart';
import 'package:language_learning_app/view/auth/widgets/auth_screen_shell.dart';
import 'package:language_learning_app/view/auth/widgets/auth_text_field.dart';
import 'package:language_learning_app/view/student/student_dashboard_shell.dart';
import 'package:language_learning_app/view/tutor/tutor_dashboard_shell.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({
    super.key,
    required this.language,
    required this.role,
  });

  final AppLanguage language;
  final UserRole role;

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  String? _timezone;
  String? _primaryLanguage;
  String? _targetLanguage;
  final Set<String> _selectedInterests = {};

  String t(String key) => ConstString.text(widget.language, key);
  final ProfileCommonApiBloc _profileCommonApiBloc = ProfileCommonApiBloc();
  final StudentProfileCreateBloc _studentProfileCreateBloc =
      StudentProfileCreateBloc();
  final TutorProfileCreateBloc _tutorProfileCreateBloc =
      TutorProfileCreateBloc();

  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  List<TextEditingController> _topicControllers = [];
  bool _isPublished = false;

  List<String> get _topicValues => _topicControllers
      .map((c) => c.text.trim())
      .where((v) => v.isNotEmpty)
      .toList();

  List<String> _languageItemsFromState(ProfileCommonApiSuccess state) {
    return List<String>.from(state.profileCommonAPI.data?.language ?? []);
  }

  List<String> _tutorPrimaryLanguageOptions(ProfileCommonApiSuccess state) {
    final options = _languageItemsFromState(state);
    if (widget.role != UserRole.becomeTutor || _targetLanguage == null) {
      return options;
    }
    return options.where((e) => e != _targetLanguage).toList();
  }

  List<String> _tutorLanguageFluencyOptions(ProfileCommonApiSuccess state) {
    final options = _languageItemsFromState(state);
    if (widget.role != UserRole.becomeTutor || _primaryLanguage == null) {
      return options;
    }
    return options.where((e) => e != _primaryLanguage).toList();
  }

  List<String> _studentPrimaryLanguageOptions(ProfileCommonApiSuccess state) {
    final options = _languageItemsFromState(state);
    if (widget.role != UserRole.findTutor || _targetLanguage == null) {
      return options;
    }
    return options.where((e) => e != _targetLanguage).toList();
  }

  List<String> _studentTargetLanguageOptions(ProfileCommonApiSuccess state) {
    final options = _languageItemsFromState(state);
    if (widget.role != UserRole.findTutor || _primaryLanguage == null) {
      return options;
    }
    return options.where((e) => e != _primaryLanguage).toList();
  }

  void _syncTimezoneFromApiIfNeeded(ProfileCommonApiSuccess state) {
    if ((_timezone ?? '').trim().isNotEmpty) return;
    final timezoneOptions = List<String>.from(
      state.profileCommonAPI.data?.timezone ?? [],
    );
    final matched = TimezoneHelper.matchDeviceTimezoneFromApi(timezoneOptions);
    if (matched != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _timezone = matched);
      });
    }
  }

  Widget _fieldHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ConstSize.grid),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _addTopicField() {
    setState(() {
      _topicControllers.add(TextEditingController());
    });
  }

  void _removeTopicField(int index) {
    // Keep at least one field on screen.
    if (_topicControllers.length <= 1) return;
    if (index < 0 || index >= _topicControllers.length) return;
    final controller = _topicControllers[index];
    setState(() {
      _topicControllers.removeAt(index);
    });
    controller.dispose();
  }

  @override
  void initState() {
    super.initState();
    _profileCommonApiBloc.add(FetchProfileCommonApi());
    if (widget.role == UserRole.becomeTutor) {
      // Start with one topic field for tutor sign-up.
      _topicControllers = [TextEditingController()];
      // Default is "Yes" when becoming a tutor.
      _isPublished = true;
      if ((_primaryLanguage ?? '').trim().isNotEmpty &&
          _primaryLanguage == _targetLanguage) {
        _targetLanguage = null;
      }
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    for (final c in _topicControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hot-reload/state reuse can occasionally leave controllers empty.
    // Ensure tutor sign-up always starts with one topic field.
    if (widget.role == UserRole.becomeTutor && _topicControllers.isEmpty) {
      _topicControllers = [TextEditingController()];
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => _profileCommonApiBloc),
        BlocProvider(create: (context) => _studentProfileCreateBloc),
        BlocProvider(create: (context) => _tutorProfileCreateBloc),
      ],
      child: PopScope(
        canPop: false,

        child: AuthScreenShell(
          showAppBar: false,
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
                _syncTimezoneFromApiIfNeeded(state);
                return state.profileCommonAPI.data == null
                    ? SizedBox.shrink()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 20),
                          Text(
                            t('profileTitle'),
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: ConstSize.grid * 2),
                          _fieldHeader(t('displayName')),
                          AuthTextField(
                            hint: t('displayName'),
                            controller: _displayNameController,
                          ),
                          const SizedBox(height: ConstSize.grid * 2),
                          _fieldHeader(t('timezone')),
                          AppDropdownButton2<String>(
                            hintText: t('timezone'),
                            value: _timezone,
                            items: List<String>.from(
                              state.profileCommonAPI.data?.timezone ?? [],
                            ),
                            itemLabelBuilder: (v) {
                              return v.toString();
                            },
                            onChanged: (v) => setState(() => _timezone = v),
                          ),

                          const SizedBox(height: ConstSize.grid * 2),
                          _fieldHeader(
                            widget.role == UserRole.becomeTutor
                                ? t('primaryLanguage')
                                : t('yourPrimaryLanguage'),
                          ),
                          AppDropdownButton2<String>(
                            hintText: widget.role == UserRole.becomeTutor
                                ? t('primaryLanguage')
                                : t('yourPrimaryLanguage'),
                            value: _primaryLanguage,
                            items: widget.role == UserRole.becomeTutor
                                ? _tutorPrimaryLanguageOptions(state)
                                : _studentPrimaryLanguageOptions(state),
                            itemLabelBuilder: (v) => v,
                            onChanged: (v) => setState(() {
                              _primaryLanguage = v;
                              if (_targetLanguage == v) {
                                _targetLanguage = null;
                              }
                            }),
                          ),
                          const SizedBox(height: ConstSize.grid * 2),
                          _fieldHeader(
                            widget.role == UserRole.becomeTutor
                                ? t('languageFluency')
                                : t('targetLanguage'),
                          ),
                          AppDropdownButton2<String>(
                            hintText: widget.role == UserRole.becomeTutor
                                ? t('languageFluency')
                                : t('targetLanguage'),
                            value: _targetLanguage,
                            items: widget.role == UserRole.becomeTutor
                                ? _tutorLanguageFluencyOptions(state)
                                : _studentTargetLanguageOptions(state),
                            itemLabelBuilder: (v) => v,
                            onChanged: (v) => setState(() {
                              _targetLanguage = v;
                              if (_primaryLanguage == v) {
                                _primaryLanguage = null;
                              }
                            }),
                          ),
                          if (widget.role == UserRole.becomeTutor) ...[
                            const SizedBox(height: ConstSize.grid * 2),
                            _fieldHeader(t('topics')),

                            ..._topicControllers.asMap().entries.map((entry) {
                              final index = entry.key;
                              final controller = entry.value;
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: index == _topicControllers.length - 1
                                      ? 0
                                      : ConstSize.grid,
                                ),

                                child: AuthTextField(
                                  hint: index == 0
                                      ? t('topic')
                                      : '${t('topic')} ${index + 1}',
                                  controller: controller,
                                  suffixIcon: index == 0
                                      ? null
                                      : IconButton(
                                          onPressed: () =>
                                              _removeTopicField(index),
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                          ),
                                          tooltip: 'Remove',
                                        ),
                                ),
                              );
                            }),
                            SizedBox(height: ConstSize.grid),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () {
                                  _addTopicField();
                                },
                                child: Container(
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    color: ConstColor.primaryBlue,
                                    borderRadius: BorderRadius.circular(
                                      ConstSize.radiusM,
                                    ),
                                  ),
                                  child: Icon(Icons.add, color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: ConstSize.grid),
                            Row(
                              children: [
                                Expanded(
                                  flex: 9,
                                  child: Text(
                                    t('isPublished'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: ToggleButtons(
                                    isSelected: [_isPublished, !_isPublished],
                                    onPressed: (index) {
                                      setState(() {
                                        _isPublished = index == 0;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(
                                      ConstSize.radiusM,
                                    ),
                                    selectedColor: ConstColor.textPrimary,
                                    fillColor: ConstColor.primaryBlue,
                                    color: ConstColor.textPrimary,
                                    constraints: const BoxConstraints(
                                      minWidth: 50,
                                      minHeight: 30,
                                    ),
                                    children: [Text(t('yes')), Text(t('no'))],
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (widget.role == UserRole.findTutor) ...[
                            const SizedBox(height: ConstSize.grid * 2),
                            _fieldHeader(t('interests')),

                            Wrap(
                              spacing: 3,
                              runSpacing: 0,
                              children: state.profileCommonAPI.data!.interest!
                                  .map((interest) {
                                    final selected = _selectedInterests
                                        .contains(interest);
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
                          ],
                          const SizedBox(height: ConstSize.grid * 2),
                          _fieldHeader(t('shortBio')),
                          AuthTextField(
                            hint: t('shortBio'),
                            maxLines: 3,
                            controller: _bioController,
                          ),

                          const SizedBox(height: ConstSize.grid * 3),
                          BlocListener<
                            StudentProfileCreateBloc,
                            StudentProfileCreateState
                          >(
                            listener: (context, state) async {
                              if (state is StudentProfileCreateInitial) {
                              } else if (state is StudentProfileCreateLoading) {
                                showDialog(
                                  barrierDismissible: false,
                                  context: context,
                                  builder: (context) {
                                    return Center(
                                      child: const CircularProgressIndicator(),
                                    );
                                  },
                                );
                              } else if (state is StudentProfileCreateError) {
                                Navigator.pop(context);
                                commonAlertDialog(context, state.message);
                              } else if (state is StudentProfileCreateSuccess) {
                                Navigator.pop(context);
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
                                await PrefUtils.setTopics(_topicValues);

                                await PrefUtils.setintrested(
                                  widget.role == UserRole.becomeTutor
                                      ? _topicValues
                                      : _selectedInterests.toList(),
                                );
                                if (widget.role == UserRole.becomeTutor) {
                                  await PrefUtils.setIsPublished(_isPublished);
                                }
                                await PrefUtils.setbio(
                                  _bioController.text.trim(),
                                );

                                final Widget targetDashboard =
                                    widget.role == UserRole.becomeTutor
                                    ? const TutorDashboardShell()
                                    : const StudentDashboardShell();

                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => targetDashboard,
                                  ),
                                  (route) => false,
                                );
                              }
                            },
                            child:
                                BlocListener<
                                  TutorProfileCreateBloc,
                                  TutorProfileCreateState
                                >(
                                  listener: (context, state) async {
                                    if (state is TutorProfileCreateInitial) {
                                    } else if (state
                                        is TutorProfileCreateLoading) {
                                      showDialog(
                                        barrierDismissible: false,
                                        context: context,
                                        builder: (context) {
                                          return Center(
                                            child:
                                                const CircularProgressIndicator(),
                                          );
                                        },
                                      );
                                    } else if (state
                                        is TutorProfileCreateError) {
                                      Navigator.pop(context);
                                      commonAlertDialog(context, state.message);
                                    } else if (state
                                        is TutorProfileCreateSuccess) {
                                      Navigator.pop(context);
                                      await PrefUtils.setname(
                                        _displayNameController.text.trim(),
                                      );
                                      await PrefUtils.settimezone(
                                        _timezone ?? '',
                                      );
                                      await PrefUtils.setprimarylanguage(
                                        _primaryLanguage ?? '',
                                      );
                                      await PrefUtils.setTopics(_topicValues);
                                      await PrefUtils.settargetlanguage(
                                        _targetLanguage ?? '',
                                      );
                                      await PrefUtils.setintrested(
                                        widget.role == UserRole.becomeTutor
                                            ? _topicValues
                                            : _selectedInterests.toList(),
                                      );
                                      if (widget.role == UserRole.becomeTutor) {
                                        await PrefUtils.setIsPublished(
                                          _isPublished,
                                        );
                                      }
                                      await PrefUtils.setbio(
                                        _bioController.text.trim(),
                                      );

                                      final Widget targetDashboard =
                                          widget.role == UserRole.becomeTutor
                                          ? const TutorDashboardShell()
                                          : const StudentDashboardShell();

                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => targetDashboard,
                                        ),
                                        (route) => false,
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
                                      } else if (widget.role ==
                                              UserRole.findTutor &&
                                          _primaryLanguage == null) {
                                        commonAlertDialog(
                                          context,
                                          t('selectPrimaryLanguageError'),
                                        );
                                      } else if (widget.role ==
                                              UserRole.findTutor &&
                                          _targetLanguage == null) {
                                        commonAlertDialog(
                                          context,
                                          t('selectTargetLanguageError'),
                                        );
                                      } else if (widget.role ==
                                              UserRole.becomeTutor &&
                                          _primaryLanguage == null) {
                                        commonAlertDialog(
                                          context,
                                          t('selectPrimaryLanguageError'),
                                        );
                                      } else if (widget.role ==
                                              UserRole.becomeTutor &&
                                          _targetLanguage == null) {
                                        commonAlertDialog(
                                          context,
                                          t('selectLanguageFluencyError'),
                                        );
                                      } else if (widget.role ==
                                              UserRole.findTutor &&
                                          _selectedInterests.isEmpty) {
                                        commonAlertDialog(
                                          context,
                                          t('selectInterestsError'),
                                        );
                                      } else if (_bioController.text
                                          .trim()
                                          .isEmpty) {
                                        commonAlertDialog(
                                          context,
                                          t('enterShortBioError'),
                                        );
                                      } else if (widget.role ==
                                              UserRole.becomeTutor &&
                                          (_topicControllers.isEmpty ||
                                              _topicControllers.every(
                                                (element) =>
                                                    element.text.trim().isEmpty,
                                              ))) {
                                        commonAlertDialog(
                                          context,
                                          t('enterTopicError'),
                                        );
                                      } else {
                                        if (widget.role ==
                                            UserRole.becomeTutor) {
                                          _tutorProfileCreateBloc.add(
                                            TutorProfileCreateProvider(
                                              displayname:
                                                  _displayNameController.text
                                                      .trim(),
                                              timezone: _timezone ?? '',
                                              primarytaught:
                                                  _primaryLanguage ?? '',
                                              targetspoken:
                                                  _targetLanguage ?? '',
                                              topics: _topicValues,
                                              bio: _bioController.text.trim(),
                                              ispublished: _isPublished == true
                                                  ? "True"
                                                  : "False",
                                            ),
                                          );
                                        } else {
                                          _studentProfileCreateBloc.add(
                                            StudentProfileCreateProvider(
                                              displayname:
                                                  _displayNameController.text
                                                      .trim(),
                                              timezone: _timezone ?? '',
                                              primarylanguage:
                                                  _primaryLanguage ?? '',
                                              targetlanguage:
                                                  _targetLanguage ?? '',
                                              intrested:
                                                  widget.role ==
                                                      UserRole.becomeTutor
                                                  ? _topicValues
                                                  : _selectedInterests.toList(),
                                              bio: _bioController.text.trim(),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  ),
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
