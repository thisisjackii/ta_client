// lib/features/register/bloc/register_state.dart
import 'package:equatable/equatable.dart';

// Add occupationId to the state for consistency with backend DTO
// The 'occupation' string might be the name, and you resolve to ID before sending.

// New Status
enum RegisterStatus {
  initial,
  submitting,
  awaitingOtpVerification,
  finalizing,
  success,
  failure,
}

class RegisterState extends Equatable {
  const RegisterState({
    this.name = '',
    this.username = '',
    this.email = '',
    this.password = '',
    this.address = '',
    this.birthdate,
    this.occupationId = '', // Store ID, not name
    this.occupationName = '', // For display in dropdown
    this.status = RegisterStatus.initial,
    this.errorMessage,
  });

  final String name;
  final String username;
  final String email;
  final String password;
  final String address;
  final DateTime? birthdate;
  final String occupationId; // Store the ID of the selected occupation
  final String occupationName; // Store the name for display convenience
  final RegisterStatus status;
  final String? errorMessage;

  // Helper to check if all required fields for OTP request are present
  bool get canRequestOtp =>
      name.isNotEmpty &&
      username.isNotEmpty &&
      email.isNotEmpty &&
      password.isNotEmpty &&
      address.isNotEmpty &&
      birthdate != null &&
      occupationId.isNotEmpty;

  RegisterState copyWith({
    String? name,
    String? username,
    String? email,
    String? password,
    String? address,
    DateTime? birthdate,
    String? occupationId,
    String? occupationName,
    RegisterStatus? status,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return RegisterState(
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      address: address ?? this.address,
      birthdate: birthdate ?? this.birthdate,
      occupationId: occupationId ?? this.occupationId,
      occupationName: occupationName ?? this.occupationName,
      status: status ?? this.status,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    name,
    username,
    email,
    password,
    address,
    birthdate,
    occupationId,
    occupationName,
    status,
    errorMessage,
  ];
}
