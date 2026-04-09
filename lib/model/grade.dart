class Grade {
  int? id;
  int examId;
  String studentName;
  int score;

  Grade({
    required this.id,
    required this.examId,
    required this.studentName,
    required this.score,
  });

  factory Grade.fromMap(Map<String, dynamic> map) {
    return Grade(
      id: map['id'],
      examId: map['examId'],
      studentName: map['studentName'],
      score: map['score'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'examId': examId,
      'studentName': studentName,
      'score': score,
    };
  }
}
