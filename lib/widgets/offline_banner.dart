import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/network_service.dart';

/// Shows a persistent banner when the app is offline.
/// Place this at the top of Scaffold body (above other content) or
/// use it as a persistent widget in the app shell.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkService>(
      builder: (context, network, _) {
        if (network.isOnline) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          color: Colors.amber.shade800,
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                const Text(
                  'Offline Mode — Some features unavailable',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
