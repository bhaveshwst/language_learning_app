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
