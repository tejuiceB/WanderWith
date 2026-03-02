import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/trip_template.dart';
import '../services/template_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_extensions.dart';
import 'create_trip_screen.dart';

class TemplatePickerScreen extends StatefulWidget {
  const TemplatePickerScreen({super.key});

  @override
  State<TemplatePickerScreen> createState() => _TemplatePickerScreenState();
}

class _TemplatePickerScreenState extends State<TemplatePickerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _templateService = TemplateService();

  List<TripTemplate> _myTemplates = [];
  List<TripTemplate> _publicTemplates = [];
  bool _isLoadingMine = true;
  bool _isLoadingPublic = true;
  String? _errorMine;
  String? _errorPublic;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMyTemplates();
    _loadPublicTemplates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMyTemplates() async {
    try {
      final list = await _templateService.getMyTemplates();
      if (mounted) setState(() { _myTemplates = list; _isLoadingMine = false; });
    } catch (e) {
      if (mounted) setState(() { _errorMine = e.toString(); _isLoadingMine = false; });
    }
  }

  Future<void> _loadPublicTemplates() async {
    try {
      final list = await _templateService.getPublicTemplates();
      if (mounted) setState(() { _publicTemplates = list; _isLoadingPublic = false; });
    } catch (e) {
      if (mounted) setState(() { _errorPublic = e.toString(); _isLoadingPublic = false; });
    }
  }

  void _useTemplate(TripTemplate template) {
    _templateService.incrementUseCount(template.id);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTripScreen(template: template),
      ),
    );
  }

  Future<void> _deleteTemplate(TripTemplate template) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Template', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Delete "${template.name}"? This cannot be undone.',
            style: GoogleFonts.inter(color: context.appColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _templateService.deleteTemplate(template.id);
      setState(() => _myTemplates.removeWhere((t) => t.id == template.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template deleted')),
        );
      }
    }
  }

  void _showTemplateDetail(TripTemplate template, {bool canDelete = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: context.appColors.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.appColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Cover image
              if (template.coverImageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: template.coverImageUrl!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 160,
                      color: context.appColors.fieldFillBg,
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              if (template.coverImageUrl != null) const SizedBox(height: 16),

              // Name + type
              Text(template.name,
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: context.appColors.textPrimary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _chip(template.tripTypeLabel),
                  const SizedBox(width: 8),
                  _chip(template.durationLabel),
                  if (template.estimatedCost > 0) ...[
                    const SizedBox(width: 8),
                    _chip('${template.budgetCurrency} ${template.estimatedCost.toStringAsFixed(0)}'),
                  ],
                ],
              ),

              if (template.location != null && template.location!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: context.appColors.textMuted),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(template.location!,
                          style: GoogleFonts.inter(color: context.appColors.textSecondary, fontSize: 14)),
                    ),
                  ],
                ),
              ],

              if (template.description != null && template.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(template.description!,
                    style: GoogleFonts.inter(color: context.appColors.textSecondary, fontSize: 14, height: 1.5)),
              ],

              // Checklist preview
              if (template.checklistItems.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Checklist (${template.checklistItems.length} items)',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: context.appColors.textPrimary)),
                const SizedBox(height: 8),
                ...template.checklistItems.take(8).map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, size: 16, color: AppColors.brand),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(item['text']?.toString() ?? '',
                                style: GoogleFonts.inter(fontSize: 14, color: context.appColors.textPrimary)),
                          ),
                        ],
                      ),
                    )),
                if (template.checklistItems.length > 8)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('+${template.checklistItems.length - 8} more',
                        style: GoogleFonts.inter(fontSize: 13, color: context.appColors.textMuted)),
                  ),
              ],

              // Itinerary preview
              if (template.itinerary.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Itinerary (${template.itinerary.length} days)',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: context.appColors.textPrimary)),
                const SizedBox(height: 8),
                ...template.itinerary.take(5).map((day) {
                  final dayNum = day['day_number'] ?? '';
                  final summary = day['summary'] ?? '';
                  final places = (day['places'] as List?)?.length ?? 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.brand.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Day $dayNum',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.brand)),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (summary.toString().isNotEmpty)
                                Text(summary.toString(),
                                    style: GoogleFonts.inter(fontSize: 14, color: context.appColors.textPrimary)),
                              if (places > 0)
                                Text('$places place${places > 1 ? 's' : ''}',
                                    style: GoogleFonts.inter(fontSize: 12, color: context.appColors.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],

              const SizedBox(height: 32),

              // Action buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _useTemplate(template);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text('Use This Template',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),

              if (canDelete) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _deleteTemplate(template);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Delete Template',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.brand.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brand)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: colors.cardBg,
        surfaceTintColor: colors.cardBg,
        title: Text('Trip Templates', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.brand,
          labelColor: AppColors.brand,
          unselectedLabelColor: colors.textSecondary,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'My Templates'),
            Tab(text: 'Community'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── My Templates tab ──
          _buildTab(
            templates: _myTemplates,
            isLoading: _isLoadingMine,
            error: _errorMine,
            emptyIcon: Icons.bookmark_border_rounded,
            emptyTitle: 'No templates yet',
            emptySubtitle: 'Save a trip as a template from the trip menu',
            canDelete: true,
            onRefresh: _loadMyTemplates,
          ),
          // ── Community tab ──
          _buildTab(
            templates: _publicTemplates,
            isLoading: _isLoadingPublic,
            error: _errorPublic,
            emptyIcon: Icons.explore_outlined,
            emptyTitle: 'No community templates',
            emptySubtitle: 'Be the first to share a template!',
            canDelete: false,
            onRefresh: _loadPublicTemplates,
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required List<TripTemplate> templates,
    required bool isLoading,
    required String? error,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
    required bool canDelete,
    required Future<void> Function() onRefresh,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: context.appColors.textMuted),
              const SizedBox(height: 12),
              Text('Something went wrong', style: GoogleFonts.inter(color: context.appColors.textSecondary)),
              const SizedBox(height: 8),
              TextButton(onPressed: onRefresh, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (templates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(emptyIcon, size: 56, color: context.appColors.textMuted),
              const SizedBox(height: 16),
              Text(emptyTitle, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: context.appColors.textPrimary)),
              const SizedBox(height: 6),
              Text(emptySubtitle, style: GoogleFonts.inter(color: context.appColors.textSecondary), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: templates.length,
        itemBuilder: (context, index) => _buildTemplateCard(templates[index], canDelete: canDelete),
      ),
    );
  }

  Widget _buildTemplateCard(TripTemplate template, {required bool canDelete}) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: () => _showTemplateDetail(template, canDelete: canDelete),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(color: colors.shadow, blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image or gradient header
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: template.coverImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: template.coverImageUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.brand.withOpacity(0.3), AppColors.brand.withOpacity(0.1)],
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => _buildGradientHeader(),
                    )
                  : _buildGradientHeader(),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(template.name,
                            style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: colors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (template.useCount > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_outline, size: 14, color: colors.textMuted),
                            const SizedBox(width: 4),
                            Text('${template.useCount}',
                                style: GoogleFonts.inter(fontSize: 12, color: colors.textMuted)),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _chip(template.tripTypeLabel),
                      _chip(template.durationLabel),
                      if (template.location != null && template.location!.isNotEmpty)
                        _chip('📍 ${template.location!.split(',').first}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (template.checklistItems.isNotEmpty)
                        _iconCount(Icons.checklist_rounded, template.checklistItems.length),
                      if (template.itinerary.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        _iconCount(Icons.map_outlined, template.itinerary.length),
                      ],
                      const Spacer(),
                      SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          onPressed: () => _useTemplate(template),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brand,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('Use',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientHeader() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brand.withOpacity(0.3), AppColors.brand.withOpacity(0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.flight_takeoff_rounded, size: 40, color: AppColors.brand.withOpacity(0.5)),
      ),
    );
  }

  Widget _iconCount(IconData icon, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: context.appColors.textMuted),
        const SizedBox(width: 4),
        Text('$count', style: GoogleFonts.inter(fontSize: 13, color: context.appColors.textMuted)),
      ],
    );
  }
}
