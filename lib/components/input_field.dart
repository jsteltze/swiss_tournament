import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool autoFocus;
  final bool isOptional;
  final TextInputType inputType;

  const InputField(
    this.label,
    this.controller, {
    super.key,
    this.autoFocus = false,
    this.isOptional = false,
    this.inputType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    final GlobalKey key = GlobalKey();

    return TextFormField(
      key: key,
      onTap: () {
        // Small delay to ensure the keyboard is fully visible
        Future.delayed(Duration(milliseconds: 700), () {
          Scrollable.ensureVisible(
            key.currentContext!,
            alignment: 0.5,
            //duration: Duration(milliseconds: 300),
            //curve: Curves.easeIn,
          );
        });
      },
      controller: controller,
      validator: (value) {
        if (isOptional && (value == null || value.isEmpty)) {
          return null;
        }
        if (value == null || value.isEmpty) {
          return 'Input must not be empty!';
        }
        if (inputType == TextInputType.number && int.tryParse(value) == null) {
          return 'Invalid integer';
        }
        return null;
      },
      keyboardType: inputType,
      inputFormatters: inputType == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : [],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      autofocus: autoFocus,
    );
  }
}
