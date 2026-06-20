import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class Link extends StatelessWidget {
  final String text;
  final String url;

  const Link(this.text, this.url, {super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
      ),
      onTap: () => launchUrlString(url),
    );
  }
}
