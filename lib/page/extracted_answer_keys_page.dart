import 'package:flutter/material.dart';
import 'package:quick_grader/config/app_routes.dart';
import 'package:quick_grader/model/exam.dart';
import 'package:quick_grader/widget/answer_grid_widget.dart';
import 'package:quick_grader/widget/bubble_widget.dart';

class ExamExtractedAnswerKeysPage extends StatefulWidget {
  const ExamExtractedAnswerKeysPage({super.key});

  @override
  State<ExamExtractedAnswerKeysPage> createState() =>
      _ExamEditAnswerKeysPageState();
}

class _ExamEditAnswerKeysPageState extends State<ExamExtractedAnswerKeysPage> {
  late Exam _exam;
  Map<int, Set<int>> _extractedAnswers = {};

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    _exam = args['exam'] as Exam;
    _extractedAnswers = args['extractedAnswers'] as Map<int, Set<int>>;
  }

  int get _score {
    int totalCorrectAnswers = 0;

    for (
      int questionNumber = 1;
      questionNumber <= _exam.numberOfQuestions;
      questionNumber++
    ) {
      if (isCorrectAnswer(questionNumber)) {
        totalCorrectAnswers++;
      }
    }

    return totalCorrectAnswers;
  }

  bool isCorrectAnswer(int questionNumber) {
    final selectedOptions = _extractedAnswers[questionNumber];

    final hasOptionSelected =
        selectedOptions != null && selectedOptions.isNotEmpty;

    if (!hasOptionSelected) {
      return false;
    }

    final hasMultipleSelection = selectedOptions.length > 1;

    if (hasMultipleSelection) {
      return false;
    }

    final selectedOption = selectedOptions.first;
    final correctOption = _exam.answers[questionNumber];

    return selectedOption == correctOption;
  }

  void _toggleOptionSelection(int questionNumber, int optionNumber) {
    final selectedOptions = _extractedAnswers[questionNumber] ?? <int>{};

    bool isSelected = selectedOptions.contains(optionNumber);

    if (isSelected) {
      selectedOptions.remove(optionNumber);
    } else {
      selectedOptions.add(optionNumber);
    }

    _extractedAnswers[questionNumber] = selectedOptions;

    setState(() {});
  }

  BubbleState _buildBubbleState(int questionNumber, int optionNumber) {
    final selectedOptions = _extractedAnswers[questionNumber];

    final hasOptionSelected =
        selectedOptions != null && selectedOptions.isNotEmpty;

    if (!hasOptionSelected) {
      return BubbleState.unselected;
    }

    final hasMultipleSelection = selectedOptions.length > 1;

    final isOptionSelected = selectedOptions.contains(optionNumber);

    if (hasMultipleSelection) {
      return isOptionSelected ? BubbleState.wrong : BubbleState.unselected;
    }

    if (!isOptionSelected) {
      return BubbleState.unselected;
    }

    final selectedAnswer = selectedOptions.first;
    final correctAnswer = _exam.answers[questionNumber];
    final isCorrectAnswer = selectedAnswer == correctAnswer;

    return isCorrectAnswer ? BubbleState.correct : BubbleState.wrong;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chaves de respostas')),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: AnswerGrid(
                numberOfQuestions: _exam.numberOfQuestions,
                numberOfOptions: _exam.numberOfOptions,
                onOptionTap: _toggleOptionSelection,
                bubbleStateBuilder: _buildBubbleState,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: FilledButton(
                child: Text('Próxima'),
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.studentSelection,
                    arguments: {'score': _score, 'exam': _exam},
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
