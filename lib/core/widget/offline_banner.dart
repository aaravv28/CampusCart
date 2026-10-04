import 'package:flutter/material.dart';

import '../services/offline_cache_service.dart';

/// Contextual banner that automatically appears when the device is disconnected
/// or experiencing backend timeouts, clearly informing the student of offline mode.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: OfflineCacheService.instance.isOnlineNotifier,
      builder: (context, isOnline, _) {
        if (isOnline) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          color: const Color(0xFFFEF3C7),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 18,
                color: Color(0xFFB45309),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Offline Mode — Displaying cached items. Actions will sync when connected.",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  // Re-check status on tap
                  OfflineCacheService.instance.isOnline = true;
                },
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    "Retry",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB45309),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Compact status chip for app bars
class ConnectionStatusChip extends StatelessWidget {
  const ConnectionStatusChip({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: OfflineCacheService.instance.isOnlineNotifier,
      builder: (context, isOnline, _) {
        if (isOnline) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF59E0B)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 13, color: Color(0xFFB45309)),
              SizedBox(width: 4),
              Text(
                "Offline",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB45309),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
