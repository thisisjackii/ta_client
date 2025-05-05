// lib/features/profile/bloc/profile_event.dart
import 'package:equatable/equatable.dart';
import 'package:ta_client/features/profile/models/user_model.dart';

abstract class ProfileEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProfileLoadRequested extends ProfileEvent {}

class ProfileUpdateRequested extends ProfileEvent {
  ProfileUpdateRequested(this.user);
  final User user;
  @override
  List<Object?> get props => [user];
}
