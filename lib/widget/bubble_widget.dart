import 'package:flutter/material.dart';

enum BubbleState { unselected, correct, wrong }

class BubbleWidget extends StatelessWidget {
  final int option;
  final BubbleState state;
  final void Function()? onTap;

  const BubbleWidget({
    super.key,
    required this.option,
    required this.onTap,
    this.state = BubbleState.unselected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: CircleAvatar(
          radius: 20,
          backgroundColor: switch (state) {
            BubbleState.unselected => Colors.grey.shade300,
            BubbleState.correct => Colors.green,
            BubbleState.wrong => Colors.red,
          },
          child: Text(
            String.fromCharCode('A'.codeUnitAt(0) + option),
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
