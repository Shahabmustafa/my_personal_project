import 'package:flutter/material.dart';
import '../utils/error_text.dart';

/// Poori jagah (list/page) ke liye error state — icon, heading, detail aur
/// optional Retry. Network na ho to "No internet connection" ka alag look.
class ErrorView extends StatelessWidget {
  final Object? error;
  final VoidCallback? onRetry;
  const ErrorView({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final offline = isNetworkError(error);
    final color = offline ? const Color(0xFFE56A00) : const Color(0xFFE5484D);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  offline
                      ? Icons.wifi_off_rounded
                      : Icons.error_outline_rounded,
                  size: 34,
                  color: color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                offline ? 'No internet connection' : 'Something went wrong',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2333),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                offline
                    ? 'Please check your internet connection and try again.'
                    : friendlyError(error),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Color(0xFF8A8FA3),
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Dropdown / chhoti row ke andar ek line ka error.
class InlineError extends StatelessWidget {
  final Object? error;
  final VoidCallback? onRetry;
  const InlineError(this.error, {super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final offline = isNetworkError(error);
    final color = offline ? const Color(0xFFE56A00) : const Color(0xFFE5484D);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          offline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
          size: 15,
          color: color,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            offline ? 'No internet connection' : friendlyError(error),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ),
        if (onRetry != null)
          InkWell(
            onTap: onRetry,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.refresh_rounded, size: 16, color: color),
            ),
          ),
      ],
    );
  }
}
