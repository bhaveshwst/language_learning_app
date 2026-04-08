part of 'list_tutor_slot_bloc.dart';

sealed class ListTutorSlotState extends Equatable {
  const ListTutorSlotState();

  @override
  List<Object?> get props => [];
}

final class ListTutorSlotInitial extends ListTutorSlotState {}

final class ListTutorSlotLoading extends ListTutorSlotState {}

final class ListTutorSlotSuccess extends ListTutorSlotState {
  final ListTutorSlotModel listTutorSlotModel;

  const ListTutorSlotSuccess(this.listTutorSlotModel);

  @override
  List<Object?> get props => [listTutorSlotModel];
}

final class ListTutorSlotError extends ListTutorSlotState {
  final String message;

  const ListTutorSlotError(this.message);

  @override
  List<Object?> get props => [message];
}

