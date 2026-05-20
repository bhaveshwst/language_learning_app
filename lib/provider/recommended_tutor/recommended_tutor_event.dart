part of 'recommended_tutor_bloc.dart';

sealed class RecommendedTutorEvent extends Equatable {
  const RecommendedTutorEvent();

  @override
  List<Object?> get props => [];
}

class FetchRecommendedTutorWithSearch extends RecommendedTutorEvent {
  final String studentId;
  final String search;
  final String matchLanguage;

  const FetchRecommendedTutorWithSearch({
    required this.studentId,
    required this.search,
    required this.matchLanguage,
  });

  @override
  List<Object?> get props => [studentId, search, matchLanguage];
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
