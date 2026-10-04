import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

/// Interactive badge indicating and toggling between Offline Demo Mode and Live Cloud Mode
class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key});

  bool get _isSupabaseAvailable {
    try {
      final _ = Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  void _showModeDialog(BuildContext context, bool isDemo) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isDemo ? Icons.bolt_rounded : Icons.cloud_done_rounded,
              color: isDemo ? const Color(0xFFB45309) : const Color(0xFF047857),
            ),
            const SizedBox(width: 8),
            Text(
              isDemo ? "Demo Mode Active" : "Live Cloud Active",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isDemo
                  ? "You are currently in Offline Demo Mode. All listings and actions are stored locally in temporary memory."
                  : "You are in Live Cloud Mode. All listings, photos, and messages sync directly to Supabase cloud.",
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDemo
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDemo
                      ? const Color(0xFFA7F3D0)
                      : const Color(0xFFFDE68A),
                ),
              ),
              child: Text(
                isDemo
                    ? "Tap below to switch to Live Supabase Backend."
                    : "Tap below to switch to Offline Demo Mode.",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDemo
                      ? const Color(0xFF065F46)
                      : const Color(0xFF92400E),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("Close"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDemo
                  ? const Color(0xFF059669)
                  : const Color(0xFFD97706),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              if (isDemo) {
                if (!_isSupabaseAvailable) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Cannot switch to Live Cloud: Supabase is not connected in .env.",
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                AppConfig.instance.isDemoMode = false;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Switched to Live Cloud Mode (Supabase) ☁️"),
                    backgroundColor: Color(0xFF059669),
                  ),
                );
              } else {
                AppConfig.instance.loginDemoUser();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Switched to Offline Demo Mode ⚡"),
                    backgroundColor: Color(0xFFD97706),
                  ),
                );
              }
            },
            child: Text(
              isDemo ? "Switch to Live Cloud ☁️" : "Switch to Demo Mode ⚡",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppConfig.instance.isDemoModeNotifier,
      builder: (context, isDemo, _) {
        final badgeColor = isDemo
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFD1FAE5);
        final borderColor = isDemo
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981);
        final textColor = isDemo
            ? const Color(0xFFB45309)
            : const Color(0xFF047857);

        return Tooltip(
          message:
              "Mode: ${isDemo ? 'Offline Demo' : 'Live Cloud'}. Tap to toggle.",
          child: InkWell(
            onTap: () => _showModeDialog(context, isDemo),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isDemo ? Icons.bolt_rounded : Icons.cloud_done_rounded,
                    size: 14,
                    color: textColor,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    isDemo ? 'DEMO MODE' : 'LIVE CLOUD',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
