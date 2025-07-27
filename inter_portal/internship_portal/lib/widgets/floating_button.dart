import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FloatingButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  const FloatingButton({
    Key? key,
    required this.onPressed,
    required this.icon,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      icon: FaIcon(icon),
      label: Text(label),
      elevation: 2,
    );
  }
}
