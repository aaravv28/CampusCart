import 'package:flutter/material.dart';

import '../errors/app_error.dart';

/// Reusable UI error presentation widget with retry action.
/// Displays clear, friendly user messaging instead of raw stack traces.
class ErrorView extends StatelessWidget {
  final dynamic error;
  final VoidCallback? onRetry;
  final String? customMessage;

  const ErrorView({super.key, this.error, this.onRetry, this.customMessage});

  @override
  Widget build(BuildContext context) {
    final appError = error is AppError
        ? error as AppError
        : (error != null ? AppError.fromException(error) : null);

    final displayMessage =
        customMessage ??
        appError?.message ??
        'An unexpected error occurred. Please try again.';

    IconData errorIcon = Icons.error_outline_rounded;
    if (appError?.type == AppErrorType.network ||
        appError?.type == AppErrorType.timeout) {
      errorIcon = Icons.wifi_off_rounded;
    } else if (appError?.type == AppErrorType.notFound) {
      errorIcon = Icons.search_off_rounded;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(errorIcon, size: 48, color: Colors.red.shade700),
            ),
            const SizedBox(height: 18),
            Text(
              displayMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
                height: 1.4,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
