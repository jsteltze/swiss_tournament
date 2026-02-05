import 'package:flutter/material.dart';

class NoDataTile extends StatelessWidget {
  final String text;
  final IconData icon;

  const NoDataTile({super.key, required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 100,
            color: Theme.of(context).colorScheme.primary.withAlpha(100),
          ),
          Text(
            text,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
