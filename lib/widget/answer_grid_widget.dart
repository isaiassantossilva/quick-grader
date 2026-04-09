import 'package:flutter/material.dart';
import 'package:quick_grader/widget/bubble_widget.dart';

class AnswerGrid extends StatelessWidget {
  final int numberOfQuestions;
  final int numberOfOptions;

  final void Function(int questionNumber, int optionNumber) onOptionTap;
  final BubbleState Function(int questionNumber, int optionNumber)
  bubbleStateBuilder;

  const AnswerGrid({
    super.key,
    required this.numberOfQuestions,
    required this.numberOfOptions,
    required this.onOptionTap,
    required this.bubbleStateBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: numberOfQuestions,
      separatorBuilder:
          (_, __) => Divider(height: 1, color: Colors.grey.shade300),
      itemBuilder: (_, index) {
        final questionNumber = index + 1;
        return _QuestionRow(
          questionNumber: questionNumber,
          numberOfOptions: numberOfOptions,
          onOptionTap:
              (optionNumber) => onOptionTap(questionNumber, optionNumber),
          bubbleStateBuilder:
              (optionNumber) =>
                  bubbleStateBuilder(questionNumber, optionNumber),
        );
      },
    );
  }
}

class _QuestionRow extends StatelessWidget {
  final int questionNumber;
  final int numberOfOptions;
  final void Function(int optionNumber) onOptionTap;
  final BubbleState Function(int optionNumber) bubbleStateBuilder;

  const _QuestionRow({
    required this.questionNumber,
    required this.numberOfOptions,
    required this.onOptionTap,
    required this.bubbleStateBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            '$questionNumber',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: List.generate(numberOfOptions, (optionNumber) {
              return BubbleWidget(
                option: optionNumber,
                state: bubbleStateBuilder(optionNumber),
                onTap: () => onOptionTap(optionNumber),
              );
            }),
          ),
        ),
      ],
    );
  }
}
