part of 'recommended_tutor_bloc.dart';

sealed class RecommendedTutorState extends Equatable {
  const RecommendedTutorState();

  @override
  List<Object?> get props => [];
}

final class RecommendedTutorInitial extends RecommendedTutorState {}

final class RecommendedTutorLoading extends RecommendedTutorState {}

final class RecommendedTutorSuccess extends RecommendedTutorState {
  final RecommendedTutorModel recommendedTutorModel;

  const RecommendedTutorSuccess(this.recommendedTutorModel);

  @override
  List<Object?> get props => [recommendedTutorModel];
}

final class RecommendedTutorError extends RecommendedTutorState {
  final String message;

  const RecommendedTutorError(this.message);

  @override
  List<Object?> get props => [message];
}

