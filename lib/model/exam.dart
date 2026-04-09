class Exam {
  int? id;
  String name;
  int numberOfQuestions;
  int numberOfOptions;
  Map<int, int> answers;

  Exam({
    required this.id,
    required this.name,
    required this.numberOfQuestions,
    required this.numberOfOptions,
    required this.answers,
  });

  factory Exam.fromMap(Map<String, dynamic> map) {
    return Exam(
      id: map["id"],
      name: map["name"],
      numberOfQuestions: map["numberOfQuestions"],
      numberOfOptions: map["numberOfOptions"],
      answers: map["answers"],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "numberOfQuestions": numberOfQuestions,
      "numberOfOptions": numberOfOptions,
      "answers": answers,
    };
  }
}
