import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/theme_extensions.dart';

/// Dedicated screen to browse all media, documents, and links shared in a trip chat.
class ChatMediaGallery extends StatefulWidget {
  final String tripId;
  final String tripName;

  const ChatMediaGallery({super.key, required this.tripId, required this.tripName});

  @override
  State<ChatMediaGallery> createState() => _ChatMediaGalleryState();
}

class _ChatMediaGalleryState extends State<ChatMediaGallery> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _photos = [];
  List<Map<String, dynamic>> _documents = [];
  List<Map<String, dynamic>> _links = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchMedia();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchMedia() async {
    try {
      final client = Supabase.instance.client;

      final photosData = await client
          .from('trip_messages')
          .select('id, sender_name, content, metadata, created_at')
          .eq('trip_id', widget.tripId)
          .eq('type', 'image')
          .order('created_at', ascending: false);

      final docsData = await client
          .from('trip_messages')
          .select('id, sender_name, content, metadata, created_at')
          .eq('trip_id', widget.tripId)
          .eq('type', 'document')
          .order('created_at', ascending: false);

      final allMessages = await client
          .from('trip_messages')
          .select('id, sender_name, content, metadata, type, created_at')
          .eq('trip_id', widget.tripId)
          .eq('type', 'link')
          .order('created_at', ascending: false);

      // Also scan text messages for URLs
      final textMessages = await client
          .from('trip_messages')
          .select('id, sender_name, content, metadata, type, created_at')
          .eq('trip_id', widget.tripId)
          .eq('type', 'text')
          .order('created_at', ascending: false);

      final linkItems = <Map<String, dynamic>>[...allMessages];
      final urlRegex = RegExp(r'https?://[^\s]+');
      for (final msg in textMessages) {
        final content = msg['content'] as String? ?? '';
        if (urlRegex.hasMatch(content)) {
          linkItems.add(msg);
        }
      }

      if (mounted) {
        setState(() {
          _photos = List<Map<String, dynamic>>.from(photosData);
          _documents = List<Map<String, dynamic>>.from(docsData);
          _links = linkItems;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load media: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: Text('Media & Files', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: colors.cardBg,
        iconTheme: IconThemeData(color: colors.textPrimary),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.brand,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: AppColors.brand,
          tabs: [
            Tab(text: 'Photos (${_photos.length})'),
            Tab(text: 'Files (${_documents.length})'),
            Tab(text: 'Links (${_links.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPhotosGrid(),
                _buildDocumentsList(),
                _buildLinksList(),
              ],
            ),
    );
  }

  // ─── Photos Grid ──────────────────────────────────────────────────
  Widget _buildPhotosGrid() {
    if (_photos.isEmpty) {
      return _buildEmptyTab(Icons.photo_library_outlined, 'No photos shared yet');
    }

    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        final photo = _photos[index];
        final metadata = photo['metadata'] as Map<String, dynamic>? ?? {};
        final url = metadata['url'] as String? ?? photo['content'] as String? ?? '';

        return GestureDetector(
          onTap: () => _openPhotoViewer(url, photo['sender_name'] as String? ?? 'Unknown'),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: Colors.grey.shade200),
              errorWidget: (_, __, ___) => Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openPhotoViewer(String url, String senderName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: const CloseButton(color: Colors.white),
            title: Text(senderName, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ),
          body: PhotoView(
            imageProvider: CachedNetworkImageProvider(url),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
          ),
        ),
      ),
    );
  }

  // ─── Documents List ───────────────────────────────────────────────
  Widget _buildDocumentsList() {
    if (_documents.isEmpty) {
      return _buildEmptyTab(Icons.folder_outlined, 'No documents shared yet');
    }

    final colors = context.appColors;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: _documents.length,
      itemBuilder: (context, index) {
        final doc = _documents[index];
        final metadata = doc['metadata'] as Map<String, dynamic>? ?? {};
        final fileName = metadata['file_name'] as String? ?? 'Unknown file';
        final fileSize = metadata['file_size'] as int? ?? 0;
        final fileUrl = metadata['url'] as String? ?? '';
        final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
        final senderName = doc['sender_name'] as String? ?? 'Unknown';
        final createdAt = DateTime.tryParse(doc['created_at'] as String? ?? '');

        return Card(
          color: colors.cardBg,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: _fileTypeIcon(ext),
            title: Text(fileName, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              '${_formatFileSize(fileSize)} · $senderName${createdAt != null ? ' · ${DateFormat('MMM d').format(createdAt)}' : ''}',
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
            trailing: IconButton(
              icon: Icon(Icons.download, color: AppColors.brand),
              onPressed: () => _openUrl(fileUrl),
            ),
            onTap: () => _openUrl(fileUrl),
          ),
        );
      },
    );
  }

  Widget _fileTypeIcon(String ext) {
    IconData icon;
    Color color;

    switch (ext) {
      case 'pdf':
        icon = Icons.picture_as_pdf;
        color = Colors.red;
        break;
      case 'doc':
      case 'docx':
        icon = Icons.description;
        color = Colors.blue;
        break;
      case 'xls':
      case 'xlsx':
      case 'csv':
        icon = Icons.table_chart;
        color = Colors.green;
        break;
      case 'ppt':
      case 'pptx':
        icon = Icons.slideshow;
        color = Colors.orange;
        break;
      case 'zip':
      case 'rar':
      case '7z':
        icon = Icons.folder_zip;
        color = Colors.amber;
        break;
      default:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.15),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // ─── Links List ───────────────────────────────────────────────────
  Widget _buildLinksList() {
    if (_links.isEmpty) {
      return _buildEmptyTab(Icons.link_off, 'No links shared yet');
    }

    final colors = context.appColors;
    final urlRegex = RegExp(r'https?://[^\s]+');

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: _links.length,
      itemBuilder: (context, index) {
        final msg = _links[index];
        final content = msg['content'] as String? ?? '';
        final metadata = msg['metadata'] as Map<String, dynamic>? ?? {};
        final senderName = msg['sender_name'] as String? ?? 'Unknown';
        final createdAt = DateTime.tryParse(msg['created_at'] as String? ?? '');

        // Extract URL from content or metadata
        String url = metadata['url'] as String? ?? '';
        if (url.isEmpty) {
          final match = urlRegex.firstMatch(content);
          if (match != null) url = match.group(0)!;
        }

        // Try to get domain for display
        String domain = '';
        try {
          domain = Uri.parse(url).host;
        } catch (_) {}

        return Card(
          color: colors.cardBg,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: const Icon(Icons.link, color: Colors.blue, size: 20),
            ),
            title: Text(
              content.isNotEmpty ? content : url,
              style: TextStyle(color: colors.textPrimary, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${domain.isNotEmpty ? '$domain · ' : ''}$senderName${createdAt != null ? ' · ${DateFormat('MMM d').format(createdAt)}' : ''}',
              style: TextStyle(color: colors.textSecondary, fontSize: 11),
            ),
            onTap: () => _openUrl(url),
          ),
        );
      },
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────
  Future<void> _openUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildEmptyTab(IconData icon, String message) {
    final colors = context.appColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: colors.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: colors.textSecondary)),
        ],
      ),
    );
  }
}
