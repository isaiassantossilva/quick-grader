class Student {
  int? id;
  String firstName;
  String lastName;

  Student({required this.id, required this.firstName, required this.lastName});

  String get fullName => "$firstName $lastName";

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map["id"],
      firstName: map["firstName"],
      lastName: map["lastName"],
    );
  }

  Map<String, dynamic> toMap() {
    return {"id": id, "firstName": firstName, "lastName": lastName};
  }
}
