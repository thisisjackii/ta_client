import 'package:equatable/equatable.dart';

class Category extends Equatable {
  const Category({
    required this.id,
    required this.accountTypeId,
    required this.name,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      accountTypeId: json['accountTypeId'] as String,
      name: json['name'] as String,
    );
  }
  @override
  List<Object?> get props => [id, accountTypeId, name];
  final String id;
  final String accountTypeId;
  final String name;
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'accountTypeId': accountTypeId,
      'name': name,
    };
  }
}
