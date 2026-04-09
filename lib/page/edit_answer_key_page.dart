import 'package:flutter/material.dart';
import 'package:quick_grader/config/dependecy_injection.dart';
import 'package:quick_grader/controller/exam_controller.dart';
import 'package:quick_grader/widget/answer_grid_widget.dart';
import 'package:quick_grader/widget/bubble_widget.dart';
import 'package:quick_grader/model/exam.dart';

class EditAnswerKeyPage extends StatefulWidget {
  const EditAnswerKeyPage({super.key});

  @override
  State<EditAnswerKeyPage> createState() => _EditAnswerKeyPageState();
}

class _EditAnswerKeyPageState extends State<EditAnswerKeyPage> {
  final _examController = DI.get<ExamController>();

  late Exam _exam;
  Map<int, int> _answers = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _exam = ModalRoute.of(context)?.settings.arguments as Exam;
    _answers = Map<int, int>.from(_exam.answers);
  }

  Future<void> _saveAnswerKey() async {
    await _examController.updateExame({..._exam.toMap(), "answers": _answers});

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _selectAnswer(int questionNumber, int optionNumber) {
    if (_answers[questionNumber] == optionNumber) {
      _answers.remove(questionNumber);
    } else {
      _answers[questionNumber] = optionNumber;
    }
    setState(() {});
  }

  BubbleState _buildBubbleState(int questionNumber, int optionNumber) {
    return _answers[questionNumber] == optionNumber
        ? BubbleState.correct
        : BubbleState.unselected;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chaves de respostas'),
        actions: [
          IconButton(icon: Icon(Icons.save), onPressed: _saveAnswerKey),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: AnswerGrid(
          numberOfQuestions: _exam.numberOfQuestions,
          numberOfOptions: _exam.numberOfOptions,
          onOptionTap: _selectAnswer,
          bubbleStateBuilder: _buildBubbleState,
        ),
      ),
    );
  }
}
