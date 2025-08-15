class Answer {
  int questionNumber;
  List<int> filledOptions = [];

  Answer(this.questionNumber);

  void addFilledOption(int optionNumber) {
    filledOptions.add(optionNumber);
  }
}
