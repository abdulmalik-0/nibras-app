import 'package:flutter/material.dart';

class AnswerView extends StatelessWidget {
  final List<String> options;
  final Function(String) onAnswerSelected;
  final String? selectedAnswer;
  final String? correctAnswer;
  final bool isAnswered;

  const AnswerView({
    super.key,
    required this.options,
    required this.onAnswerSelected,
    this.selectedAnswer,
    this.correctAnswer,
    this.isAnswered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        
        Color backgroundColor = Colors.white;
        Color borderColor = Colors.grey.shade300;
        Color textColor = Colors.black87;
        IconData? icon;

        if (isAnswered) {
          if (option == correctAnswer) {
            backgroundColor = Colors.green.shade50;
            borderColor = Colors.green.shade400;
            textColor = Colors.green.shade900;
            icon = Icons.check_circle_rounded;
          } else if (option == selectedAnswer) {
            backgroundColor = Colors.red.shade50;
            borderColor = Colors.red.shade400;
            textColor = Colors.red.shade900;
            icon = Icons.cancel_rounded;
          }
        } else if (option == selectedAnswer) {
          backgroundColor = Colors.deepPurple.shade50;
          borderColor = Colors.deepPurple.shade400;
          textColor = Colors.deepPurple.shade900;
        }

        final letters = ['أ', 'ب', 'ج', 'د'];

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: isAnswered ? null : () => onAnswerSelected(option),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: borderColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: borderColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        letters[index],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (icon != null)
                    Icon(
                      icon,
                      color: borderColor,
                      size: 28,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
