part of 'recommended_tutor_bloc.dart';

sealed class RecommendedTutorEvent extends Equatable {
  const RecommendedTutorEvent();

  @override
  List<Object?> get props => [];
}

class FetchRecommendedTutorWithSearch extends RecommendedTutorEvent {
  final String studentId;
  final String search;
  final String? toggleKey;

  const FetchRecommendedTutorWithSearch({
    required this.studentId,
    required this.search,
    this.toggleKey,
  });

  @override
  List<Object?> get props => [studentId, search, toggleKey];
}

class SaveTutorSpeakPrimaryLanguageToggle extends RecommendedTutorEvent {
  final String studentId;
  final String toggleKey;
  final String search;

  const SaveTutorSpeakPrimaryLanguageToggle({
    required this.studentId,
    required this.toggleKey,
    required this.search,
  });

  @override
  List<Object?> get props => [studentId, toggleKey, search];
}

class ToggleTutorLikeDislike extends RecommendedTutorEvent {
  final String studentId;
  final String tutorId;
  final int likeDislike;

  const ToggleTutorLikeDislike({
    required this.studentId,
    required this.tutorId,
    required this.likeDislike,
  });

  @override
  List<Object?> get props => [studentId, tutorId, likeDislike];
}
