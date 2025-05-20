import 'package:equatable/equatable.dart';

class AccountType extends Equatable {
  // Important for DropdownButtonFormField value comparison

  factory AccountType.fromJson(Map<String, dynamic> json) {
    return AccountType(id: json['id'] as String, name: json['name'] as String);
  }
  // ignore: sort_unnamed_constructors_first
  const AccountType({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
  final String id;
  final String name;
  Map<String, dynamic> toJson() {
    return <String, dynamic>{'id': id, 'name': name};
  }
}
