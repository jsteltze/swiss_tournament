import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class Link extends StatelessWidget {
  final String text;
  final String url;

  const Link(this.text, this.url, {super.key});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
        text: text,
        recognizer: TapGestureRecognizer()..onTap = () => launchUrlString(url),
      ),
    );
  }
}
