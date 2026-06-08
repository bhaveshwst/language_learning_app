import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/auth/student_auth_gate.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_image.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/core/constants/const_string.dart';
import 'package:language_learning_app/core/constants/utils.dart';
import 'package:language_learning_app/core/state/app_language_state.dart';
import 'package:language_learning_app/core/widgets/app_dropdown_button2.dart';
import 'package:language_learning_app/core/widgets/app_text.dart';
import 'package:language_learning_app/core/device/app_device_info.dart';
import 'package:language_learning_app/core/widgets/app_version_widgets.dart';
import 'package:language_learning_app/main.dart';
import 'package:language_learning_app/provider/get_student_profile/get_student_profile_bloc.dart';
import 'package:language_learning_app/model/recommended_tutor_model/recommended_tutor_model.dart';
import 'package:language_learning_app/provider/recommended_tutor/recommended_tutor_bloc.dart';
import 'package:language_learning_app/view/student/screens/tutor_availability_calendar_screen.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class StudentHomeDashboardScreen extends StatefulWidget {
  const StudentHomeDashboardScreen({super.key, this.isGuest = false});

  final bool isGuest;

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

  bool? _tutorSpeakMyPrimaryLanguage;
  bool _isTutorListRefreshing = false;
  bool _showFavoriteTutorsOnly = false;
  String? _selectedTargetLanguage;
  String? _studentPrimaryLanguage;

  String _address = "";
  String _latitude = "";
  String _longitude = "";
  String t(String key) =>
      ConstString.text(AppLanguageState.currentLanguage, key);

  String? get _matchLanguageValue {
    if (_tutorSpeakMyPrimaryLanguage == null) return null;
    return _tutorSpeakMyPrimaryLanguage! ? 'Yes' : 'No';
  }

  bool get _canUsePrimaryLanguageFilter =>
      !widget.isGuest && StudentAuthGate.isLoggedIn;

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

  String get _resolvedStudentPrimaryLanguage {
    final fromState = (_studentPrimaryLanguage ?? '').trim();
    if (fromState.isNotEmpty) return fromState;
    return PrefUtils.getprimarylanguage().trim();
  }

  bool _languageMatchesStudentPrimary(String tutorLanguage, String studentPrimary) {
    final student = studentPrimary.trim().toLowerCase();
    if (student.isEmpty) return false;

    final tutor = tutorLanguage.trim().toLowerCase();
    if (tutor.isEmpty) return false;
    if (tutor == student) return true;

    return tutor
        .split(',')
        .map((part) => part.trim())
        .any((part) => part == student);
  }

  String _tutorPrimaryLanguageLabel(Tutors tutor) {
    final primary = (tutor.primaryLanguage ?? '').trim();
    if (primary.isNotEmpty) return primary;
    return (tutor.teachesLanguages ?? '').trim();
  }

  bool _tutorMatchesPrimaryLanguageFilter(Tutors tutor) {
    final selection = _tutorSpeakMyPrimaryLanguage;
    if (selection == null) return true;

    final studentPrimary = _resolvedStudentPrimaryLanguage;
    if (studentPrimary.isEmpty) return true;

    final tutorLang = _tutorPrimaryLanguageLabel(tutor);
    final speaksStudentPrimary =
        _languageMatchesStudentPrimary(tutorLang, studentPrimary);

    return selection ? speaksStudentPrimary : !speaksStudentPrimary;
  }

  List<Tutors> _visibleTutors(List<Tutors>? tutors) {
    var list = tutors ?? [];
    if (_canUsePrimaryLanguageFilter && _tutorSpeakMyPrimaryLanguage != null) {
      list = list.where(_tutorMatchesPrimaryLanguageFilter).toList();
    }
    if (!_showFavoriteTutorsOnly) return list;
    return list.where((t) => t.isLiked).toList();
  }

  Future<void> _toggleFavoriteTutor(BuildContext context, Tutors tutor) async {
    if (widget.isGuest || !StudentAuthGate.isLoggedIn) {
      await StudentAuthGate.ensureLoggedInForBooking(context);
      return;
    }
    final studentId = PrefUtils.getstudentid().trim();
    final tutorId = (tutor.id ?? '').trim();
    if (studentId.isEmpty || tutorId.isEmpty) return;

    _recommendedTutorBloc.add(
      ToggleTutorLikeDislike(
        studentId: studentId,
        tutorId: tutorId,
        likeDislike: tutor.isLiked ? 0 : 1,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final cachedPrimary = PrefUtils.getprimarylanguage().trim();
    if (cachedPrimary.isNotEmpty) {
      _studentPrimaryLanguage = cachedPrimary;
    }
    _deviceName();
    _getLocation();
    if (!widget.isGuest) {
      final studentId = PrefUtils.getstudentid().trim();
      if (studentId.isNotEmpty) {
        _getStudentProfileBloc.add(FetchStudentProfile(studentId: studentId));
      }
    }
    _recommendedTutorBloc.add(
      FetchRecommendedTutorWithSearch(
        studentId: PrefUtils.getstudentid(),
        search: "",
        toggleKey: _matchLanguageValue,
      ),
    );
    if (!widget.isGuest) {
      unawaited(_printFcmTokenAfterLogin());
    }

    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _deviceName() async {
    await loadAppDeviceInfo();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _getLocation() async {
    Position position = await _getGeoLocationPosition();
    _latitude = position.latitude.toString();
    _longitude = position.longitude.toString();
    debugPrint('Latitude: $_latitude');
    debugPrint('Longitude: $_longitude');
    debugPrint('Address: $_address');
    await getAddressFromLatLong(position);
  }

  Future<void> getAddressFromLatLong(Position position) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

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

      return Future.error(t('locationServicesDisabled'));
    } else {}

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // showCupertinoDialog(
        //     context: context,
        //     builder: (dialogContext) {
        //       return CupertinoAlertDialog(
        //         content: Text(t('locationPermissionsDenied')),
        //         actions: [
        //           CupertinoDialogAction(child: Text(t('cancel')), onPressed: () {
        //             Navigator.pop(dialogContext);
        //           }),
        //           CupertinoDialogAction(child: Text(t('settings')), onPressed: () async {
        //               Navigator.pop(dialogContext);
        //           if (Platform.isIOS) {
        //             await Geolocator.openLocationSettings();
        //           } else if (Platform.isAndroid) {
        //             await Geolocator.openAppSettings();
        //           }
        //           }),

        //         ],
        //       );
        //     });
        return Future.error(t('locationPermissionsDenied'));
      }
    }
    if (permission == LocationPermission.deniedForever) {
      // showCupertinoDialog(
      //     context: context,
      //     builder: (dialogContext) {
      //       return CupertinoAlertDialog(
      //         content: Text(t('locationPermissionsPermanentlyDenied')),
      //          actions: [
      //           CupertinoDialogAction(child: Text(t('cancel')), onPressed: () {
      //               Navigator.pop(dialogContext);
      //             }),
      //             CupertinoDialogAction(child: Text(t('settings')), onPressed: () async {
      //                 Navigator.pop(dialogContext);
      //             if (Platform.isIOS) {
      //               await Geolocator.openLocationSettings();
      //             } else if (Platform.isAndroid) {
      //               await Geolocator.openAppSettings();
      //             }
      //             }),

      //           ],
      //       );
      //     });

      return Future.error(t('locationPermissionsPermanentlyDenied'));
    }
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        ),
      );
    }
    return await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
      ),
    );
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
        toggleKey: _matchLanguageValue,
      ),
    );
  }

  void _onPrimaryLanguageToggleChanged(bool value) {
    setState(() {
      _tutorSpeakMyPrimaryLanguage = value;
      _isTutorListRefreshing = true;
    });
    final toggleKey = value ? 'Yes' : 'No';
    if (_canUsePrimaryLanguageFilter) {
      _recommendedTutorBloc.add(
        SaveTutorSpeakPrimaryLanguageToggle(
          studentId: PrefUtils.getstudentid(),
          toggleKey: toggleKey,
          search: _searchController.text.trim(),
        ),
      );
      return;
    }
    _fetchTutorsForSearch();
  }

  @override
  Widget build(BuildContext context) {
    final body = MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => _recommendedTutorBloc),
          BlocProvider(create: (context) => _getStudentProfileBloc),
        ],
        child: MultiBlocListener(
          listeners: [
            BlocListener<GetStudentProfileBloc, GetStudentProfileState>(
              listener: (context, state) async {
                if (state is GetStudentProfileSuccess) {
                  final profilePrimary =
                      (state.model.data?.primaryLanguage ?? '').trim();
                  if (profilePrimary.isNotEmpty) {
                    _studentPrimaryLanguage = profilePrimary;
                  }
                  zegoAppID = state.model.zegoAppID ?? 1896143529;
                  await PrefUtils.setname(state.model.data?.displayName ?? '');
                  await PrefUtils.setimagepath(
                    state.model.data?.imagepath ?? '',
                  );
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
                if (_isTutorListRefreshing &&
                    (state is RecommendedTutorSuccess ||
                        state is RecommendedTutorError)) {
                  setState(() => _isTutorListRefreshing = false);
                }

              },
            ),
          ],
          child: ValueListenableBuilder<AppLanguage>(
            valueListenable: AppLanguageState.current,
            builder: (context, language, _) {
              final studentPrimaryLanguage = language == AppLanguage.korean
                  ? 'Korean'
                  : 'English';
              final defaultTargetLanguage = studentPrimaryLanguage == 'Korean'
                  ? 'English'
                  : 'Korean';

              _selectedTargetLanguage ??= defaultTargetLanguage;

              return SafeArea(
                top: !widget.isGuest,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    ConstSize.grid * 2,
                    widget.isGuest ? ConstSize.grid : ConstSize.grid * 1.5,
                    ConstSize.grid * 2,
                    ConstSize.grid * 3,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.isGuest
                                  ? '${ConstString.text(language, 'hi')}, ${ConstString.text(language, 'guestVisitor')} 👋'
                                  : '${ConstString.text(language, 'hi')}, ${PrefUtils.getname()} 👋',
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w700,
                                height: 1.12,
                                letterSpacing: -0.45,
                                color: ConstColor.textPrimary,
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
                        enabled: _canUsePrimaryLanguageFilter,
                        onChanged: _onPrimaryLanguageToggleChanged,
                      ),

                      const SizedBox(height: ConstSize.grid * 2),

                      TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                          color: ConstColor.textPrimary,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: ConstString.text(language, 'searchTutors'),
                          hintStyle: TextStyle(
                            color: ConstColor.textSecondary.withValues(
                              alpha: 0.75,
                            ),
                            fontSize: 15,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: ConstColor.primaryBlue.withValues(
                              alpha: 0.85,
                            ),
                            size: 24,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: ConstColor.border.withValues(alpha: 0.85),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: ConstColor.border.withValues(alpha: 0.85),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: ConstColor.primaryBlue,
                              width: 1.5,
                            ),
                          ),
                          isDense: true,
                        ),
                        onChanged: (_) {
                          _searchDebounce?.cancel();
                          _searchDebounce = Timer(
                            const Duration(milliseconds: 350),
                            _fetchTutorsForSearch,
                          );
                        },
                      ),

                      const SizedBox(height: ConstSize.grid * 2.25),

                      Text(
                        ConstString.text(language, 'recommendedTutors'),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.25,
                          color: ConstColor.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _TutorListFilterToggle(
                        showFavoritesOnly: _showFavoriteTutorsOnly,
                        allLabel: ConstString.text(language, 'allTutors'),
                        favoritesLabel:
                            ConstString.text(language, 'favoriteTutors'),
                        onChanged: (showFavorites) {
                          setState(
                            () => _showFavoriteTutorsOnly = showFavorites,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      BlocBuilder<RecommendedTutorBloc, RecommendedTutorState>(
                        bloc: _recommendedTutorBloc,
                        builder: (context, tutorState) {
                          if (tutorState is RecommendedTutorInitial) {
                            return SizedBox.shrink();
                          }
                          if (_isTutorListRefreshing ||
                              tutorState is RecommendedTutorLoading) {
                            return SizedBox(
                              height: MediaQuery.of(context).size.height * 0.35,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: ConstColor.primaryBlue,
                                ),
                              ),
                            );
                          }
                          if (tutorState is RecommendedTutorError) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  tutorState.message,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: ConstColor.textSecondary,
                                    fontSize: 14,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            );
                          }
                          if (tutorState is RecommendedTutorSuccess) {
                            final tutors = _visibleTutors(
                              tutorState.recommendedTutorModel.data?.tutors,
                            );
                            if (tutors.isEmpty) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text(
                                    _showFavoriteTutorsOnly
                                        ? ConstString.text(
                                            language,
                                            'noFavoriteTutors',
                                          )
                                        : ConstString.text(
                                            language,
                                            'noTutorsMatch',
                                          ),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: ConstColor.textSecondary,
                                      fontSize: 14,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return ListView.builder(
                              shrinkWrap: true,
                              itemCount: tutors.length,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                final tutor = tutors[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _TutorCard(
                                    imagepath: tutor.imagepath ?? "",
                                    flagimage: tutor.country == "US"
                                        ? ConstImage.usFlag
                                        : tutor.country == "KR"
                                        ? ConstImage.krFlag
                                        : ConstImage.spFlag,
                                    country: tutor.country == "US"
                                        ? "United States"
                                        : tutor.country == "KR"
                                        ? "South Korea"
                                        : tutor.country == "SP"
                                        ? "Spain"
                                        : "-",
                                    rating: tutor.avaragerating ?? "0",
                                    name: tutor.displayName ?? "",
                                    primaryLanguage:
                                        tutor.teachesLanguages ?? "",
                                    isFavorite: tutor.isLiked,
                                    onFavoriteToggle: () =>
                                        _toggleFavoriteTutor(context, tutor),
                                    onBook: () {
                                      StudentAuthGate.openBookingScreenIfAllowed(
                                        context,
                                        tutorName: tutor.displayName ?? '',
                                        tutorId: tutor.id ?? '',
                                        tutorBio: tutor.bio ?? '',
                                        tutorLanguagesTaught:
                                            tutor.teachesLanguages ?? '',
                                        tutorImageUrl: tutor.imagepath,
                                        source: BookingAuthSource.tutorList,
                                      );
                                    },
                                    onCheckAvailability: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              TutorAvailabilityCalendarScreen(
                                                tutorName:
                                                    tutor.displayName ?? "",
                                                tutorId: tutor.id ?? "",
                                                tutorImageUrl: tutor.imagepath,
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

    if (widget.isGuest) {
      return body;
    }

    return Scaffold(
      backgroundColor: ConstColor.background,
      body: body,
    );
  }
}

class _TutorCard extends StatelessWidget {
  const _TutorCard({
    required this.name,
    required this.primaryLanguage,
    required this.rating,
    required this.country,
    required this.flagimage,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onBook,
    required this.onCheckAvailability,
    required this.imagepath,
  });

  final String name;
  final String primaryLanguage;
  final String? rating;
  final String? country;
  final String? flagimage;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onBook;
  final VoidCallback onCheckAvailability;
  final String? imagepath;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLanguageState.current,
      builder: (context, language, _) {
        final hasPhoto =
            imagepath != null && (imagepath ?? '').trim().isNotEmpty;
        final url = (imagepath ?? '').trim();
        const avatarSize = 52.0;

        final placeholder = Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ConstColor.primaryBlue.withValues(alpha: 0.1),
          ),
          child: const Icon(
            Icons.person_rounded,
            size: 26,
            color: ConstColor.primaryBlue,
          ),
        );

        final Widget avatar = hasPhoto
            ? ClipOval(
                child: SizedBox(
                  width: avatarSize,
                  height: avatarSize,
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => placeholder,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        width: avatarSize,
                        height: avatarSize,
                        alignment: Alignment.center,
                        color: ConstColor.primaryBlue.withValues(alpha: 0.06),
                        child: const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ConstColor.primaryBlue,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              )
            : placeholder;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: ConstColor.border.withValues(alpha: 0.65),
            ),
            boxShadow: [
              BoxShadow(
                color: ConstColor.primaryBlue.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    color: ConstColor.primaryBlue.withValues(alpha: 0.85),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              avatar,
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.25,
                                        color: ConstColor.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            country ?? '-',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: ConstColor.textSecondary
                                                  .withValues(alpha: 0.95),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (flagimage != null &&
                                            (flagimage ?? '').isNotEmpty &&
                                            (flagimage ?? '-') != '-')
                                          Image.asset(
                                            flagimage!,
                                            fit: BoxFit.contain,
                                            width: 22,
                                            height: 22,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ConstColor.primaryBlue.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          rating != null &&
                                                  rating != 'null' &&
                                                  (rating ?? '').isNotEmpty
                                              ? (rating ?? '0')
                                              : '0',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: ConstColor.primaryBlue,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Icon(
                                          rating != null &&
                                                  rating != '0' &&
                                                  rating != 'null'
                                              ? Icons.star_rounded
                                              : Icons.star_outline_rounded,
                                          size: 18,
                                          color: ConstColor.primaryBlue,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: onFavoriteToggle,
                                      borderRadius: BorderRadius.circular(10),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: Icon(
                                          isFavorite
                                              ? Icons.favorite_rounded
                                              : Icons.favorite_border_rounded,
                                          size: 22,
                                          color: isFavorite
                                              ? const Color(0xFFE53935)
                                              : ConstColor.textSecondary
                                                  .withValues(alpha: 0.75),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${ConstString.text(language, 'language')}: $primaryLanguage',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ConstColor.textSecondary,
                              fontSize: 13,
                              height: 1.3,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 46,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: ConstColor.primaryBlue,
                                      side: BorderSide(
                                        color: ConstColor.primaryBlue
                                            .withValues(alpha: 0.85),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: onCheckAvailability,
                                    child: Text(
                                      ConstString.text(
                                        language,
                                        'checkAvailability',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: SizedBox(
                                  height: 46,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: ConstColor.primaryBlue,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: onBook,
                                    child: const AppText(
                                      'book',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TutorListFilterToggle extends StatelessWidget {
  const _TutorListFilterToggle({
    required this.showFavoritesOnly,
    required this.allLabel,
    required this.favoritesLabel,
    required this.onChanged,
  });

  final bool showFavoritesOnly;
  final String allLabel;
  final String favoritesLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ConstColor.border.withValues(alpha: 0.65),
        ),
        boxShadow: [
          BoxShadow(
            color: ConstColor.primaryBlue.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _YesNoPill(
              label: allLabel,
              selected: !showFavoritesOnly,
              onTap: () => onChanged(false),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _YesNoPill(
              label: favoritesLabel,
              selected: showFavoritesOnly,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
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
    this.enabled = true,
  });

  final String label;
  final String left;
  final String right;
  final bool? value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.15,
              color: enabled
                  ? ConstColor.textPrimary
                  : ConstColor.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ConstColor.border.withValues(alpha: 0.65),
              ),
              boxShadow: [
                BoxShadow(
                  color: ConstColor.primaryBlue.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _YesNoPill(
                      label: left,
                      selected: value == true,
                      enabled: enabled,
                      onTap: enabled ? () => onChanged(true) : null,
                    ),
                  ),
                  Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: ConstColor.primaryBlue,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  Expanded(
                    child: _YesNoPill(
                      label: right,
                      selected: value == false,
                      enabled: enabled,
                      onTap: enabled ? () => onChanged(false) : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _YesNoPill extends StatelessWidget {
  const _YesNoPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? ConstColor.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: selected ? Colors.white : ConstColor.textSecondary,
              ),
            ),
          ),
        ),
      ),
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
                  final displayLang = ValueListenableBuilder<AppLanguage>(
                    valueListenable: AppLanguageState.current,
                    builder: (context, language, _) {
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
              ValueListenableBuilder<AppLanguage>(
                valueListenable: AppLanguageState.current,
                builder: (context, language, _) {
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
