// lib/features/profile/bloc/profile_state.dart
import 'package:equatable/equatable.dart';
import 'package:ta_client/features/profile/models/user_model.dart';

abstract class ProfileState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoadInProgress extends ProfileState {}

class ProfileLoadSuccess extends ProfileState {
  ProfileLoadSuccess(this.user);
  final User user;
  @override
  List<Object?> get props => [user];
}

class ProfileLoadFailure extends ProfileState {
  ProfileLoadFailure(this.error);
  final String error;
  @override
  List<Object?> get props => [error];
}
