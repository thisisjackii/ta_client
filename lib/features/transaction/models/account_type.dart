class AccountType {
  AccountType({required this.id, required this.name});

  factory AccountType.fromJson(Map<String, dynamic> json) {
    return AccountType(id: json['id'] as String, name: json['name'] as String);
  }
  final String id;
  final String name;
  Map<String, dynamic> toJson() {
    return <String, dynamic>{'id': id, 'name': name};
  }
}
