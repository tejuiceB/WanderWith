import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/location_share_service.dart';
import '../models/user_profile.dart';
import '../theme/app_colors.dart';
import '../theme/theme_extensions.dart';

/// A compact banner that shows active live location sharers.
/// Tapping it opens a full-screen map with all active locations.
class LiveLocationBanner extends StatefulWidget {
  final String tripId;
  final Map<String, UserProfile> memberProfiles;

  const LiveLocationBanner({
    super.key,
    required this.tripId,
    required this.memberProfiles,
  });

  @override
  State<LiveLocationBanner> createState() => _LiveLocationBannerState();
}

class _LiveLocationBannerState extends State<LiveLocationBanner> {
  List<Map<String, dynamic>> _activeShares = [];
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = LocationShareService.instance
        .activeSharesStream(widget.tripId)
        .listen((shares) {
      if (mounted) setState(() => _activeShares = shares);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_activeShares.isEmpty) return const SizedBox.shrink();

    final colors = context.appColors;
    final names = _activeShares.map((s) {
      final uid = s['user_id'] as String;
      return widget.memberProfiles[uid]?.displayName ?? 'Someone';
    }).toList();

    final label = names.length == 1
        ? '${names.first} is sharing live location'
        : '${names.length} people sharing live location';

    return GestureDetector(
      onTap: () => _openFullMap(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.brand.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.brand.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.share_location, color: AppColors.brand, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: colors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  void _openFullMap(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _FullLiveLocationMap(
        tripId: widget.tripId,
        memberProfiles: widget.memberProfiles,
        initialShares: _activeShares,
      ),
    ));
  }
}

/// Full-screen Google Map showing all active live location shares
class _FullLiveLocationMap extends StatefulWidget {
  final String tripId;
  final Map<String, UserProfile> memberProfiles;
  final List<Map<String, dynamic>> initialShares;

  const _FullLiveLocationMap({
    required this.tripId,
    required this.memberProfiles,
    required this.initialShares,
  });

  @override
  State<_FullLiveLocationMap> createState() => _FullLiveLocationMapState();
}

class _FullLiveLocationMapState extends State<_FullLiveLocationMap> {
  GoogleMapController? _mapController;
  StreamSubscription? _sub;
  List<Map<String, dynamic>> _shares = [];
  final List<Color> _markerColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
  ];

  @override
  void initState() {
    super.initState();
    _shares = widget.initialShares;
    _sub = LocationShareService.instance
        .activeSharesStream(widget.tripId)
        .listen((shares) {
      if (mounted) setState(() => _shares = shares);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    for (int i = 0; i < _shares.length; i++) {
      final s = _shares[i];
      final uid = s['user_id'] as String;
      final lat = (s['latitude'] as num).toDouble();
      final lng = (s['longitude'] as num).toDouble();
      final name = widget.memberProfiles[uid]?.displayName ?? 'User';
      final color = _markerColors[i % _markerColors.length];

      markers.add(Marker(
        markerId: MarkerId(uid),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(title: name),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _colorToHue(color),
        ),
      ));
    }
    return markers;
  }

  double _colorToHue(Color c) {
    if (c == Colors.red) return BitmapDescriptor.hueRed;
    if (c == Colors.blue) return BitmapDescriptor.hueBlue;
    if (c == Colors.green) return BitmapDescriptor.hueGreen;
    if (c == Colors.orange) return BitmapDescriptor.hueOrange;
    if (c == Colors.purple) return BitmapDescriptor.hueViolet;
    return BitmapDescriptor.hueCyan;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final markers = _buildMarkers();

    // Center on first share or default
    final center = _shares.isNotEmpty
        ? LatLng(
            (_shares.first['latitude'] as num).toDouble(),
            (_shares.first['longitude'] as num).toDouble(),
          )
        : const LatLng(20.5937, 78.9629); // Default: India center

    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Locations"),
        backgroundColor: colors.cardBg,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: center, zoom: 14),
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (controller) => _mapController = controller,
          ),
          // Bottom overlay with sharer list
          if (_shares.isNotEmpty)
            Positioned(
              left: 12,
              right: 12,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _shares.asMap().entries.map((entry) {
                    final i = entry.key;
                    final s = entry.value;
                    final uid = s['user_id'] as String;
                    final profile = widget.memberProfiles[uid];
                    final name = profile?.displayName ?? 'User';
                    final expires = DateTime.tryParse(s['expires_at'] ?? '');
                    final remaining = expires != null
                        ? expires.difference(DateTime.now())
                        : Duration.zero;
                    final color = _markerColors[i % _markerColors.length];

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: color.withOpacity(0.2),
                            backgroundImage: profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty
                                ? NetworkImage(profile.avatarUrl!)
                                : null,
                            child: profile?.avatarUrl == null || profile!.avatarUrl!.isEmpty
                                ? Text(name[0].toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14))
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colors.textPrimary)),
                          ),
                          Text(
                            remaining.inMinutes > 60
                                ? '${remaining.inHours}h ${remaining.inMinutes % 60}m left'
                                : '${remaining.inMinutes}m left',
                            style: TextStyle(fontSize: 11, color: colors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
