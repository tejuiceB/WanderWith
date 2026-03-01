import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/theme_extensions.dart';

class AvatarPicker extends StatefulWidget {
  final File? imageFile;
  final String? existingUrl;
  final ValueChanged<File> onPicked;
  final double size;

  const AvatarPicker({
    super.key,
    this.imageFile,
    this.existingUrl,
    required this.onPicked,
    this.size = 100,
  });

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  File? _pickedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pickedImage = widget.imageFile;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final colors = context.appColors;
    final isDark = context.isDark;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: colors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Choose a photo',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.brand.withOpacity(0.15) : const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.camera_alt_outlined, color: AppColors.brand),
                ),
                title: Text('Camera', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                subtitle: Text('Take a new photo', style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFFAB47BC).withOpacity(0.15) : const Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: Color(0xFFAB47BC)),
                ),
                title: Text('Gallery', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                subtitle: Text('Pick from gallery', style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    setState(() => _isLoading = true);

    try {
      final picked = await picker.pickImage(source: source, maxWidth: 800, maxHeight: 800);
      if (picked == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Compress image
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final compressed = await FlutterImageCompress.compressAndGetFile(
        picked.path,
        targetPath,
        quality: 80,
        minWidth: 400,
        minHeight: 400,
      );

      final file = compressed != null ? File(compressed.path) : File(picked.path);

      setState(() {
        _pickedImage = file;
        _isLoading = false;
      });
      widget.onPicked(file);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: _isLoading ? null : _pickImage,
      child: Stack(
        children: [
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.surfaceBg,
              border: Border.all(
                color: colors.border,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
              image: _pickedImage != null
                  ? DecorationImage(image: FileImage(_pickedImage!), fit: BoxFit.cover)
                  : widget.existingUrl != null
                      ? DecorationImage(image: NetworkImage(widget.existingUrl!), fit: BoxFit.cover)
                      : null,
            ),
            child: _pickedImage == null && widget.existingUrl == null
                ? Icon(
                    Icons.person_outline_rounded,
                    size: widget.size * 0.4,
                    color: colors.textMuted,
                  )
                : null,
          ),
          // Camera badge
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.brand,
                shape: BoxShape.circle,
                border: Border.all(color: colors.scaffoldBg, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(6),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.camera_alt, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
