import 'package:flutter/material.dart';

import 'offline_banner.dart';

/// Legacy adapter: Redirects DemoBadge to ConnectionStatusChip
/// ensuring backward compatibility while removing all demo mode toggles.
class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const ConnectionStatusChip();
  }
}
