import 'package:equatable/equatable.dart';

class Subcategory extends Equatable {
  const Subcategory({
    required this.id,
    required this.categoryId,
    required this.name,
  });
  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      name: json['name'] as String,
    );
  }
  @override
  List<Object?> get props => [id, categoryId, name];
  final String id;
  final String categoryId;
  final String name;
  Map<String, dynamic> toJson() {
    return <String, dynamic>{'id': id, 'categoryId': categoryId, 'name': name};
  }
}
