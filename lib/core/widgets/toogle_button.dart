import 'package:flutter/material.dart';


class ToggleButton extends StatefulWidget {
  const ToggleButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  final String text;
  final Function(bool) onPressed;

  @override
  State<ToggleButton> createState() => _ToggleButtonState();
}

class _ToggleButtonState extends State<ToggleButton> {

  bool isClicked = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: 100,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: isClicked ? Colors.teal.shade600 : Colors.white30,
        ),
          onPressed: () {
            setState(() {
              isClicked = !isClicked;
            });

            widget.onPressed(isClicked);
          },
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: 14,
              color: isClicked ? Colors.white : Colors.white30,
            ),
          )
      ),
    );
  }
}
