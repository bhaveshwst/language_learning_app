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
import 'package:language_learning_app/provider/student_profile_create/student_profile_create_bloc.dart';
import 'package:language_learning_app/view/auth/widgets/auth_primary_button.dart';
import 'package:language_learning_app/view/auth/widgets/auth_text_field.dart';
import 'package:language_learning_app/view/student/student_dashboard_shell.dart';
import 'package:language_learning_app/view/tutor/tutor_dashboard_shell.dart';

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
  /// True when a timezone was already saved locally (first-time signup / dashboard sync).
  bool _lockTimezoneEdit = false;
  String? _primaryLanguage;
  String? _targetLanguage;
  final Set<String> _selectedInterests = {};

  File? _imagefile;
  String? imagepath;

  String t(String key) => ConstString.text(widget.language, key);

  final ProfileCommonApiBloc _profileCommonApiBloc = ProfileCommonApiBloc();
  final StudentProfileUpdateBloc _studentProfileUpdateBloc =
      StudentProfileUpdateBloc();

  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  List<String> _languageItemsFromState(ProfileCommonApiSuccess state) {
    return List<String>.from(state.profileCommonAPI.data?.language ?? []);
  }

  List<String> _studentPrimaryLanguageOptions(ProfileCommonApiSuccess state) {
    final options = _languageItemsFromState(state);
    if (_targetLanguage == null) return options;
    return options.where((e) => e != _targetLanguage).toList();
  }

  List<String> _studentTargetLanguageOptions(ProfileCommonApiSuccess state) {
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

  @override
  void initState() {
    super.initState();
    _profileCommonApiBloc.add(FetchProfileCommonApi());
    _displayNameController.text = PrefUtils.getname();
    if( PrefUtils.getimagepath() != '') {
      imagepath = PrefUtils.getimagepath();
    }
    final savedTz = PrefUtils.gettimezone().trim();
    _lockTimezoneEdit = savedTz.isNotEmpty;
    _timezone = savedTz.isEmpty ? null : savedTz;
    _primaryLanguage = PrefUtils.getprimarylanguage() == ""
        ? null
        : PrefUtils.getprimarylanguage();
    _targetLanguage = PrefUtils.gettargetlanguage() == ""
        ? null
        : PrefUtils.gettargetlanguage();
    if ((_primaryLanguage ?? '').trim().isNotEmpty &&
        _primaryLanguage == _targetLanguage) {
      _targetLanguage = null;
    }
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
          child: SingleChildScrollView(
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
                            const SizedBox(height: ConstSize.grid * 3),
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
                                    child:  _imagefile == null && imagepath == ''
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
                            const SizedBox(height: ConstSize.grid * 3),
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
                              itemLabelBuilder: (v) => v.toString(),
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
                            _fieldHeader(t('yourPrimaryLanguage')),
                            AppDropdownButton2<String>(
                              hintText: t('yourPrimaryLanguage'),
                              value: _primaryLanguage,
                              items: _studentPrimaryLanguageOptions(state),
                              itemLabelBuilder: (v) => v,
                              onChanged: (v) => setState(() {
                                _primaryLanguage = v;
                                if (_targetLanguage == v) {
                                  _targetLanguage = null;
                                }
                              }),
                            ),
                            const SizedBox(height: ConstSize.grid * 2),
                            _fieldHeader(t('targetLanguage')),
                            AppDropdownButton2<String>(
                              hintText: t('targetLanguage'),
                              value: _targetLanguage,
                              items: _studentTargetLanguageOptions(state),
                              itemLabelBuilder: (v) => v,
                              onChanged: (v) => setState(() {
                                _targetLanguage = v;
                                if (_primaryLanguage == v) {
                                  _primaryLanguage = null;
                                }
                              }),
                            ),
                            const SizedBox(height: ConstSize.grid * 2),
                            _fieldHeader(t('interests')),
                            
                            
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
                            _fieldHeader(t('shortBio')),
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
                                       Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const StudentDashboardShell(),
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
                                        imagepath: _imagefile != null
            ? base64Encode(_imagefile!.readAsBytesSync())
            : imagepath ?? "",
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
                            SizedBox(height: 20,)
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
