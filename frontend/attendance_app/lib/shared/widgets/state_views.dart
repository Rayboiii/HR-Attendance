import 'package:flutter/material.dart';

/// Scrollable error view (works inside RefreshIndicator) with a retry button.
class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Icon(Icons.error_outline,
            size: 56, color: Theme.of(context).colorScheme.error),
        const SizedBox(height: 16),
        Center(child: Text(message, textAlign: TextAlign.center)),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
        ),
      ],
    );
  }
}

/// Scrollable empty-state view (works inside RefreshIndicator).
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Icon(icon, size: 56, color: Theme.of(context).disabledColor),
        const SizedBox(height: 16),
        Center(child: Text(message, textAlign: TextAlign.center)),
      ],
    );
  }
}
