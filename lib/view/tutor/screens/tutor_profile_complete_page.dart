import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_dialog.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/core/constants/const_string.dart';
import 'package:language_learning_app/core/constants/timezone_helper.dart';
import 'package:language_learning_app/core/constants/user_role.dart';
import 'package:language_learning_app/core/constants/utils.dart';
import 'package:language_learning_app/core/widgets/app_dropdown_button2.dart';
import 'package:language_learning_app/core/widgets/app_version_widgets.dart';
import 'package:language_learning_app/provider/profile_common_api/profile_common_api_bloc.dart';
import 'package:language_learning_app/provider/tutor_profile_create/tutor_profile_create_bloc.dart';
import 'package:language_learning_app/view/auth/widgets/auth_primary_button.dart';
import 'package:language_learning_app/view/auth/widgets/auth_text_field.dart';
import 'package:language_learning_app/view/tutor/tutor_dashboard_shell.dart';

class TutorProfileCompletePage extends StatefulWidget {
  const TutorProfileCompletePage({
    super.key,
    required this.language,
    required this.role,
  });

  final AppLanguage language;
  final UserRole role;

  @override
  State<TutorProfileCompletePage> createState() =>
      _TutorProfileCompletePageState();
}

class _TutorProfileCompletePageState extends State<TutorProfileCompletePage> {
  String? _timezone;

  /// True when a timezone was already saved locally (first-time signup / dashboard sync).
  bool _lockTimezoneEdit = false;
  String? _primaryLanguage;
  String? _targetLanguage;

  /// Tutor (becomeTutor) only: multiple languages you speak → `"English, Spanish"` for API/prefs.
  final Set<String> _tutorSpokenLanguages = {};
  final Set<String> _selectedInterests = {};

  File? _imagefile;
  String? imagepath;

  String t(String key) => ConstString.text(widget.language, key);
  final ProfileCommonApiBloc _profileCommonApiBloc = ProfileCommonApiBloc();
  final TutorProfileCreateBloc _tutorProfileCreateBloc =
      TutorProfileCreateBloc();
  final TutorProfileUpdateBloc _tutorProfileUpdateBloc =
      TutorProfileUpdateBloc();

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
    if (widget.role == UserRole.becomeTutor) {
      return options.where((e) => !_tutorSpokenLanguages.contains(e)).toList();
    }
    if (_targetLanguage == null) return options;
    return options.where((e) => e != _targetLanguage).toList();
  }

  String _serializedTutorSpokenLanguages() {
    final list = _tutorSpokenLanguages.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list.join(', ');
  }

  List<String> _tutorLanguageFluencyOptions(ProfileCommonApiSuccess state) {
    final options = _languageItemsFromState(state);
    if (_primaryLanguage == null) return options;
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

    final topics = PrefUtils.getTopics();

    if (widget.role == UserRole.becomeTutor) {
      if (topics.isNotEmpty) {
        _topicControllers = topics
            .map((e) => TextEditingController(text: e))
            .toList();
      } else {
        _topicControllers = [TextEditingController()];
      }

      _isPublished = PrefUtils.getIsPublished();
    }

    _displayNameController.text = PrefUtils.getname();
    final savedTz = PrefUtils.gettimezone().trim();
    _lockTimezoneEdit = savedTz.isNotEmpty;
    if( PrefUtils.getimagepath() != '') {
imagepath = PrefUtils.getimagepath();
    }
    
    _timezone = savedTz.isEmpty ? null : savedTz;
    _primaryLanguage = PrefUtils.getprimarylanguage() == ""
        ? null
        : PrefUtils.getprimarylanguage();
    final savedTarget = PrefUtils.gettargetlanguage().trim();
    if (widget.role == UserRole.becomeTutor) {
      if (savedTarget.isNotEmpty) {
        for (final part in savedTarget.split(RegExp(r'\s*,\s*'))) {
          final p = part.trim();
          if (p.isNotEmpty) {
            _tutorSpokenLanguages.add(p);
          }
        }
      }
      if ((_primaryLanguage ?? '').trim().isNotEmpty) {
        _tutorSpokenLanguages.remove(_primaryLanguage);
      }
    } else {
      _targetLanguage = savedTarget.isEmpty ? null : savedTarget;
      if ((_primaryLanguage ?? '').trim().isNotEmpty &&
          _primaryLanguage == _targetLanguage) {
        _targetLanguage = null;
      }
    }
    _selectedInterests.addAll(PrefUtils.getintrested());
    _bioController.text = PrefUtils.getbio();
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
        BlocProvider(create: (context) => _tutorProfileCreateBloc),
        BlocProvider(create: (context) => _tutorProfileUpdateBloc),
      ],
      child: Scaffold(
        appBar: AppBar(
          leading: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Icon(Icons.arrow_back_ios_new_rounded),
          ),
          title: Text(
            t('profileTitle'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          actions: const [AppVersionAppBarAction()],
        ),
        body: SingleChildScrollView(
          child: Padding(
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
                  _syncTimezoneFromApiIfNeeded(state);
                  return state.profileCommonAPI.data == null
                      ? SizedBox.shrink()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: ConstSize.grid * 2),
                            Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    clipBehavior: Clip.hardEdge,
                                    height: 120,
                                    width: 120,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: ConstColor.colorBlack,
                                        width: 2,
                                      ),
                                      color: ConstColor.primaryBlue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: _imagefile == null && imagepath == ''
                                        ? const Icon(
                                            Icons.person,
                                            color: ConstColor.colorWhite,
                                            size: 55,
                                          )
                                        : _imagefile != null
                                        ? Image.file(
                                            _imagefile!,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.network(
                                            imagepath ?? '',
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () {
                                        _pickPhoto();
                                      },
                                      child: Container(
                                        height: 34,
                                        width: 34,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: ConstColor.colorBlack,
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt_outlined,
                                          size: 18,
                                          color: ConstColor.colorWhite,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
                              enabled: !_lockTimezoneEdit,
                              onChanged: (v) {
                                setState(() => _timezone = v);
                              },
                            ),
                            if (_lockTimezoneEdit) ...[
                              const SizedBox(height: ConstSize.grid * 1),
                              Text(
                                t('timezoneLockedProfileHint'),
                                style: const TextStyle(
                                  color: ConstColor.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: ConstSize.grid * 2),
                            _fieldHeader(t('primaryLanguage')),
                            AppDropdownButton2<String>(
                              hintText: t('primaryLanguage'),
                              value: _primaryLanguage,
                              items: _tutorPrimaryLanguageOptions(state),
                              itemLabelBuilder: (v) => v,
                              onChanged: (v) => setState(() {
                                _primaryLanguage = v;
                                if (widget.role == UserRole.becomeTutor) {
                                  _tutorSpokenLanguages.remove(v);
                                } else if (_targetLanguage == v) {
                                  _targetLanguage = null;
                                }
                              }),
                            ),
                            const SizedBox(height: ConstSize.grid * 2),
                            _fieldHeader(t('languageFluency')),
                            if (widget.role == UserRole.becomeTutor)
                              Wrap(
                                spacing: 3,
                                runSpacing: 0,
                                children: _tutorLanguageFluencyOptions(state)
                                    .map((lang) {
                                      final selected = _tutorSpokenLanguages
                                          .contains(lang);
                                      return FilterChip(
                                        label: Text(lang),
                                        selected: selected,
                                        onSelected: (value) {
                                          setState(() {
                                            if (value) {
                                              _tutorSpokenLanguages.add(lang);
                                            } else {
                                              _tutorSpokenLanguages.remove(
                                                lang,
                                              );
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
                              )
                            else
                              AppDropdownButton2<String>(
                                hintText: t('languageFluency'),
                                value: _targetLanguage,
                                items: _tutorLanguageFluencyOptions(state),
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
                                    bottom:
                                        index == _topicControllers.length - 1
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
                              Text(
                                t('interests'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: ConstSize.grid),
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
                                              _selectedInterests.remove(
                                                interest,
                                              );
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
                              TutorProfileUpdateBloc,
                              TutorProfileCreateState
                            >(
                              listener: (context, state) async {
                                if (state is TutorProfileCreateInitial) {
                                } else if (state is TutorProfileCreateLoading) {
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
                                } else if (state is TutorProfileCreateError) {
                                  Navigator.pop(context);
                                  commonAlertDialog(context, state.message);
                                } else if (state is TutorProfileCreateSuccess) {
                                  Navigator.pop(context);
                                  await PrefUtils.setname(
                                    _displayNameController.text.trim(),
                                  );
                                  await PrefUtils.settimezone(_timezone ?? '');
                                  await PrefUtils.setprimarylanguage(
                                    _primaryLanguage ?? '',
                                  );
                                  await PrefUtils.setTopics(_topicValues);
                                  await PrefUtils.settargetlanguage(
                                    widget.role == UserRole.becomeTutor
                                        ? _serializedTutorSpokenLanguages()
                                        : (_targetLanguage ?? ''),
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

                                  commonAlertDialogwithButton(
                                    context,
                                    "${state.tutorCreateProfileModel.detail}",
                                    () {
                                     
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const TutorDashboardShell(),
                                        ),
                                        (route) => false,
                                      );
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
                                      _tutorSpokenLanguages.isEmpty) {
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
                                          _topicControllers.isEmpty ||
                                      _topicControllers.every(
                                        (element) =>
                                            element.text.trim().isEmpty,
                                      )) {
                                    commonAlertDialog(
                                      context,
                                      t('enterTopicError'),
                                    );
                                  } else {
                                    _tutorProfileUpdateBloc.add(
                                      TutorProfileCreateProvider(
                                        displayname: _displayNameController.text
                                            .trim(),
                                        timezone: _timezone ?? '',
                                        primarytaught: _primaryLanguage ?? '',
                                        targetspoken:
                                            widget.role == UserRole.becomeTutor
                                            ? _serializedTutorSpokenLanguages()
                                            : (_targetLanguage ?? ''),
                                        topics: _topicValues,
                                        bio: _bioController.text.trim(),
                                        ispublished: _isPublished == true
                                            ? "True"
                                            : "False",
                                        imagepath: _imagefile != null
            ? base64Encode(_imagefile!.readAsBytesSync())
            : imagepath ?? "",
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
      ),
    );
  }

  void _pickPhoto() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            "Select Picture",
            style: TextStyle(color: ConstColor.colorBlack),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                style: const ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                    ConstColor.primaryBlue,
                  ),
                ),
                child: const Text(
                  ' Pick from Camera ',
                  style: TextStyle(color: ConstColor.colorWhite),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  selectimage(ImageSource.camera);
                },
              ),
              OutlinedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                    ConstColor.primaryBlue,
                  ),
                ),
                child: const Text(
                  'Select from Gallery',
                  style: TextStyle(color: ConstColor.colorWhite),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  selectimage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 2),
            ],
          ),
        );
      },
    );
  }

  void _showImagePermissionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'Camera or photo library permission is required to upload a profile picture. Please enable it in app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void selectimage(ImageSource source) async {
    XFile? pickedFile;
    try {
      pickedFile = await ImagePicker().pickImage(source: source);
    } on PlatformException catch (_) {
      if (!mounted) return;
      _showImagePermissionDialog();
      return;
    }

    if (pickedFile != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,

        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,

        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
          ),

          IOSUiSettings(title: 'Crop Image'),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _imagefile = File(croppedFile.path);
        });
      }
    }
  }
}
