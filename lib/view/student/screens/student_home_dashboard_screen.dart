import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/core/constants/const_string.dart';
import 'package:language_learning_app/core/constants/utils.dart';
import 'package:language_learning_app/core/state/app_language_state.dart';
import 'package:language_learning_app/core/widgets/app_dropdown_button2.dart';
import 'package:language_learning_app/core/widgets/app_text.dart';
import 'package:language_learning_app/core/widgets/app_version_widgets.dart';
import 'package:language_learning_app/provider/get_student_profile/get_student_profile_bloc.dart';
import 'package:language_learning_app/provider/recommended_tutor/recommended_tutor_bloc.dart';
import 'package:language_learning_app/view/student/screens/booking_screen.dart';
import 'package:language_learning_app/view/student/screens/tutor_availability_calendar_screen.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';


class StudentHomeDashboardScreen extends StatefulWidget {
  const StudentHomeDashboardScreen({super.key});

  @override
  State<StudentHomeDashboardScreen> createState() =>
      _StudentHomeDashboardScreenState();
}

class _StudentHomeDashboardScreenState extends State<StudentHomeDashboardScreen>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final RecommendedTutorBloc _recommendedTutorBloc = RecommendedTutorBloc();
  final GetStudentProfileBloc _getStudentProfileBloc = GetStudentProfileBloc();
  Timer? _searchDebounce;

  bool _tutorSpeakMyPrimaryLanguage = true;
  String? _selectedTargetLanguage;

  String _address = "";
  String _latitude = "";
  String _longitude = "";

  String get _matchLanguageValue => _tutorSpeakMyPrimaryLanguage ? 'Yes' : 'No';

  bool? _parseMatchValue(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    final s = v.toString().trim().toLowerCase();
    if (s == 'yes' || s == 'true' || s == '1') return true;
    if (s == 'no' || s == 'false' || s == '0') return false;
    return null;
  }

  Future<void> _printFcmTokenAfterLogin() async {
    try {
      final saved = PrefUtils.getFCMToken().trim();
      if (saved.isNotEmpty) {
        debugPrint('FCM Token (Student Home): $saved');
        return;
      }

      for (int i = 0; i < 12; i++) {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.isNotEmpty) {
          await PrefUtils.setFCMToken(token);
          debugPrint('FCM Token (Student Home): $token');
          return;
        }
        await Future.delayed(const Duration(seconds: 1));
      }

      debugPrint('FCM Token (Student Home): still null');
    } catch (e) {
      debugPrint('FCM Token print failed: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _getLocation();
    final studentId = PrefUtils.getstudentid().trim();
    if (studentId.isNotEmpty) {
      _getStudentProfileBloc.add(FetchStudentProfile(studentId: studentId, tutorId: PrefUtils.gettutorid()));
    }
    _recommendedTutorBloc.add(
      FetchRecommendedTutorWithSearch(
        studentId: PrefUtils.getstudentid(),
        search: "",
        matchLanguage: _matchLanguageValue,
      ),
    );
    unawaited(_printFcmTokenAfterLogin());

    WidgetsBinding.instance.addObserver(this);
  }

    Future<void> _getLocation() async {
    Position position = await _getGeoLocationPosition();
    _latitude = position.latitude.toString();
    _longitude = position.longitude.toString();
    debugPrint('Latitude: $_latitude');
    debugPrint('Longitude: $_longitude');
    await getAddressFromLatLong(position);
  }


   Future<void> getAddressFromLatLong(Position position) async {
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);

    Placemark place = placemarks[0];
    _address =
        '${place.street!.isEmpty ? place.name : place.street}, ${place.locality!.isNotEmpty ? place.locality : place.subAdministrativeArea}, ${place.administrativeArea!.isNotEmpty ? place.administrativeArea : place.subLocality}, ${place.postalCode}, ${place.isoCountryCode}';
    setState(() {});
  }


    Future<Position> _getGeoLocationPosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();

      return Future.error('Location services are disabled.');
    } else {}

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        showCupertinoDialog(
            context: context,
            builder: (dialogContext) {
              return CupertinoAlertDialog(
                content: Text('Location permissions are denied'),
                actions: [
                  CupertinoDialogAction(child: Text("Settings"), onPressed: () async {
                      Navigator.pop(dialogContext);
                  if (Platform.isIOS) {
                    await Geolocator.openLocationSettings();
                  } else if (Platform.isAndroid) {
                    await Geolocator.openAppSettings();
                  }
                  }),
                ],
              );
            });
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      showCupertinoDialog(
          context: context,
          builder: (dialogContext) {
            return CupertinoAlertDialog(
              content: Text('Location permissions are permanently denied, we cannot request permissions.'),
               actions: [
                  CupertinoDialogAction(child: Text("Settings"), onPressed: () async {
                      Navigator.pop(dialogContext);
                  if (Platform.isIOS) {
                    await Geolocator.openLocationSettings();
                  } else if (Platform.isAndroid) {
                    await Geolocator.openAppSettings();
                  }
                  }),
                ],
            );
          });

      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      return await Geolocator.getCurrentPosition(
          locationSettings:
              LocationSettings(accuracy: LocationAccuracy.bestForNavigation));
    }
    return await Geolocator.getCurrentPosition(
        locationSettings:
            LocationSettings(accuracy: LocationAccuracy.bestForNavigation));
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _recommendedTutorBloc.close();
    _getStudentProfileBloc.close();
    super.dispose();
  }

  void _fetchTutorsForSearch() {
    _recommendedTutorBloc.add(
      FetchRecommendedTutorWithSearch(
        studentId: PrefUtils.getstudentid(),
        search: _searchController.text.trim(),
        matchLanguage: _matchLanguageValue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => _recommendedTutorBloc),
        BlocProvider(create: (context) => _getStudentProfileBloc),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<GetStudentProfileBloc, GetStudentProfileState>(
            listener: (context, state) async {
              if (state is GetStudentProfileSuccess) {
                await PrefUtils.setname(state.model.data?.displayName ?? '');
                await PrefUtils.settimezone(state.model.data?.timezone ?? '');
                await PrefUtils.setprimarylanguage(
                  state.model.data?.primaryLanguage ?? '',
                );
                await PrefUtils.settargetlanguage(
                  state.model.data?.targetLanguage ?? '',
                );
                await PrefUtils.setbio(state.model.data?.bio ?? '');
                await PrefUtils.setintrested(
                  state.model.data?.interests
                          ?.map((e) => e.toString())
                          .toList() ??
                      [],
                );
                if (!mounted) return;
                setState(() {});
              }
              // if (state is! GetStudentProfileSuccess) return;
              // final data = state.model.data;
              // if (data == null) return;

              // final name = (data.displayName ?? '').trim();
              // if (name.isNotEmpty) await PrefUtils.setname(name);

              // final timezone = (data.timezone ?? '').trim();
              // if (timezone.isNotEmpty) await PrefUtils.settimezone(timezone);

              // final primary = (data.primaryLanguage ?? '').trim();
              // if (primary.isNotEmpty) await PrefUtils.setprimarylanguage(primary);

              // final target = (data.targetLanguage ?? '').trim();
              // if (target.isNotEmpty) await PrefUtils.settargetlanguage(target);

              // final bio = (data.bio ?? '').trim();
              // if (bio.isNotEmpty) await PrefUtils.setbio(bio);

              // final interests = data.interests ?? const <String>[];
              // if (interests.isNotEmpty) await PrefUtils.setintrested(interests);

              // if (!mounted) return;
              // setState(() {});
            },
          ),
          BlocListener<RecommendedTutorBloc, RecommendedTutorState>(
            bloc: _recommendedTutorBloc,
            listener: (context, state) {
              if (state is! RecommendedTutorSuccess) return;
              final apiToggle = _parseMatchValue(
                state.recommendedTutorModel.matchValue,
              );
              if (apiToggle == null) return;
              if (apiToggle == _tutorSpeakMyPrimaryLanguage) return;
              setState(() => _tutorSpeakMyPrimaryLanguage = apiToggle);
            },
          ),
        ],
        child: ValueListenableBuilder<bool>(
          valueListenable: AppLanguageState.isKorean,
          builder: (context, isKoreanAppLang, _) {
            final language = isKoreanAppLang
                ? AppLanguage.korean
                : AppLanguage.english;
            final studentPrimaryLanguage = isKoreanAppLang
                ? 'Korean'
                : 'English';
            final defaultTargetLanguage = studentPrimaryLanguage == 'Korean'
                ? 'English'
                : 'Korean';

            _selectedTargetLanguage ??= defaultTargetLanguage;

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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${ConstString.text(language, 'hi')}, ${PrefUtils.getname()} 👋',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const AppVersionHeaderBadge(),
                      ],
                    ),
                    const SizedBox(height: ConstSize.grid * 2),
                    _YesNoToggle(
                      label: ConstString.text(
                        language,
                        'tutorSpeakPrimaryLanguage',
                      ),
                      left: ConstString.text(language, 'yes'),
                      right: ConstString.text(language, 'no'),
                      value: _tutorSpeakMyPrimaryLanguage,
                      onChanged: (v) {
                        setState(() => _tutorSpeakMyPrimaryLanguage = v);
                        // _fetchTutorsForSearch();
                      },
                    ),

                    const SizedBox(height: ConstSize.grid * 2),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: ConstString.text(
                                language,
                                'searchTutors',
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: ConstColor.textSecondary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  ConstSize.radiusM,
                                ),
                                borderSide: const BorderSide(
                                  color: ConstColor.border,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: ConstSize.grid * 1.5,
                                vertical: 14,
                              ),
                            ),
                            onChanged: (_) {
                              _searchDebounce?.cancel();
                              _searchDebounce = Timer(
                                const Duration(milliseconds: 350),
                                _fetchTutorsForSearch,
                              );
                            },
                          ),
                        ),
                        // const SizedBox(width: ConstSize.grid),
                        // IconButton(
                        //   icon: const Icon(Icons.filter_list_outlined),
                        //   color: ConstColor.primaryBlue,
                        //   onPressed: () async {
                        //     final result = await showDialog<_FilterResult>(
                        //       context: context,
                        //       builder: (_) => _FilterDialog(
                        //         initialTargetLanguage: _selectedTargetLanguage!,
                        //         initialAvailabilitySlot:
                        //             _selectedAvailabilitySlot,
                        //         targetLanguages: _targetLanguageOptions,
                        //         availabilitySlots: _availabilitySlots,
                        //       ),
                        //     );
                        //     if (result == null) return;

                        //     setState(() {
                        //       _selectedTargetLanguage = result.targetLanguage;
                        //       _selectedAvailabilitySlot =
                        //           result.availabilitySlot;
                        //     });
                        //     _fetchTutorsForSearch();
                        //   },
                        // ),
                      ],
                    ),

                    const SizedBox(height: ConstSize.grid * 2),

                    Text(
                      ConstString.text(language, 'recommendedTutors'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: ConstSize.grid * 2),
                    BlocBuilder<RecommendedTutorBloc, RecommendedTutorState>(
                      bloc: _recommendedTutorBloc,
                      builder: (context, tutorState) {
                        if (tutorState is RecommendedTutorInitial) {
                          return SizedBox.shrink();
                        }
                        if (tutorState is RecommendedTutorLoading) {
                          return SizedBox(
                            height: MediaQuery.of(context).size.height / 2,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (tutorState is RecommendedTutorError) {
                          return Center(child: Text(tutorState.message));
                        }
                        if (tutorState is RecommendedTutorSuccess) {
                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount:
                                tutorState
                                    .recommendedTutorModel
                                    .data
                                    ?.tutors
                                    ?.length ??
                                0,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _TutorCard(
                                  name:
                                      tutorState
                                          .recommendedTutorModel
                                          .data
                                          ?.tutors?[index]
                                          .displayName ??
                                      "",
                                  primaryLanguage:
                                      tutorState
                                          .recommendedTutorModel
                                          .data
                                          ?.tutors?[index]
                                          .teachesLanguages ??
                                      "",

                                  onBook: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BookingScreen(
                                        tutorName:
                                            tutorState
                                                .recommendedTutorModel
                                                .data
                                                ?.tutors?[index]
                                                .displayName ??
                                            "",
                                        tutorId:
                                            tutorState
                                                .recommendedTutorModel
                                                .data
                                                ?.tutors?[index]
                                                .id ??
                                            "",
                                        tutorBio:
                                            tutorState
                                                .recommendedTutorModel
                                                .data
                                                ?.tutors?[index]
                                                .bio ??
                                            "",
                                        tutorLanguagesTaught:
                                            tutorState
                                                .recommendedTutorModel
                                                .data
                                                ?.tutors?[index]
                                                .teachesLanguages ??
                                            "",
                                      ),
                                    ),
                                  ),
                                  onCheckAvailability: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            TutorAvailabilityCalendarScreen(
                                              tutorName:
                                                  tutorState
                                                      .recommendedTutorModel
                                                      .data
                                                      ?.tutors?[index]
                                                      .displayName ??
                                                  "",
                                              tutorId:
                                                  tutorState
                                                      .recommendedTutorModel
                                                      .data
                                                      ?.tutors?[index]
                                                      .id ??
                                                  "",
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        }
                        return SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TutorCard extends StatelessWidget {
  const _TutorCard({
    required this.name,
    required this.primaryLanguage,

    required this.onBook,
    required this.onCheckAvailability,
  });

  final String name;
  final String primaryLanguage;

  final VoidCallback onBook;
  final VoidCallback onCheckAvailability;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppLanguageState.isKorean,
      builder: (context, isKorean, _) {
        final language = isKorean ? AppLanguage.korean : AppLanguage.english;
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
                    radius: 24,
                    backgroundColor: ConstColor.primaryBlue.withValues(
                      alpha: 0.16,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: ConstColor.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: ConstSize.grid * 1.5),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ConstSize.grid * 1.5),
              Text(
                '${ConstString.text(language, 'language')}: $primaryLanguage',
                style: const TextStyle(color: ConstColor.textSecondary),
              ),
              const SizedBox(height: ConstSize.grid),

              const SizedBox(height: ConstSize.grid * 2),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.white,
                          foregroundColor: ConstColor.primaryBlue,
                          side: const BorderSide(color: ConstColor.primaryBlue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              ConstSize.radiusM,
                            ),
                          ),
                        ),
                        onPressed: onCheckAvailability,
                        child: Text(
                          ConstString.text(language, 'checkAvailability'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SizedBox(
                      height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: ConstColor.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              ConstSize.radiusM,
                            ),
                          ),
                        ),
                        onPressed: onBook,
                        child: const AppText('book'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _YesNoToggle extends StatelessWidget {
  const _YesNoToggle({
    required this.label,
    required this.left,
    required this.right,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String left;
  final String right;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: ConstSize.grid),
        ToggleButtons(
          isSelected: [value, !value],
          onPressed: (index) => onChanged(index == 0),
          borderRadius: BorderRadius.circular(ConstSize.radiusM),
          constraints: const BoxConstraints(minHeight: 30, minWidth: 50),
          selectedColor: Colors.white,
          fillColor: ConstColor.primaryBlue,
          color: ConstColor.textSecondary,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                left,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                right,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterDialog extends StatefulWidget {
  const _FilterDialog({
    required this.initialTargetLanguage,
    required this.initialAvailabilitySlot,
    required this.targetLanguages,
    required this.availabilitySlots,
  });

  final String initialTargetLanguage;
  final String? initialAvailabilitySlot;
  final List<String> targetLanguages;
  final List<String> availabilitySlots;

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late String _targetLanguage;
  String? _availabilitySlot;

  @override
  void initState() {
    super.initState();
    _targetLanguage = widget.initialTargetLanguage;
    _availabilitySlot = widget.initialAvailabilitySlot;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const AppText('filter'),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText(
                'targetLanguage',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: widget.targetLanguages.map((lang) {
                  final displayLang = ValueListenableBuilder<bool>(
                    valueListenable: AppLanguageState.isKorean,
                    builder: (context, isKorean, _) {
                      final language = isKorean
                          ? AppLanguage.korean
                          : AppLanguage.english;
                      return Text(
                        lang == 'Korean'
                            ? ConstString.text(language, 'korean')
                            : ConstString.text(language, 'english'),
                      );
                    },
                  );
                  return ChoiceChip(
                    label: displayLang,
                    selected: lang == _targetLanguage,
                    selectedColor: ConstColor.primaryBlue.withValues(
                      alpha: 0.16,
                    ),
                    onSelected: (_) => setState(() => _targetLanguage = lang),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const AppText(
                'availabilitySlot',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<bool>(
                valueListenable: AppLanguageState.isKorean,
                builder: (context, isKorean, _) {
                  final language = isKorean
                      ? AppLanguage.korean
                      : AppLanguage.english;
                  return AppDropdownButton2<String>(
                    hintText: ConstString.text(language, 'availabilitySlot'),
                    value: _availabilitySlot,
                    items: widget.availabilitySlots,
                    itemLabelBuilder: (slot) => slot,
                    onChanged: (v) => setState(() => _availabilitySlot = v),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const AppText('cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ConstColor.primaryBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ConstSize.radiusM),
            ),
          ),
          onPressed: () {
            Navigator.pop(
              context,
              _FilterResult(
                targetLanguage: _targetLanguage,
                availabilitySlot: _availabilitySlot,
              ),
            );
          },
          child: const AppText('apply'),
        ),
      ],
    );
  }
}

class _FilterResult {
  _FilterResult({required this.targetLanguage, required this.availabilitySlot});

  final String targetLanguage;
  final String? availabilitySlot;
}
