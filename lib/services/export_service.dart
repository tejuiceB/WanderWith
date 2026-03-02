import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trip.dart';
import '../models/trip_plan.dart';
import '../models/checklist_item.dart';
import '../models/expense.dart';
import '../models/user_profile.dart';
import 'plan_service.dart';
import 'checklist_service.dart';

/// Service to export trip data as PDF or JSON.
class ExportService {
  final _supabase = Supabase.instance.client;
  final _planService = PlanService();
  final _checklistService = ChecklistService();

  String get _userId => _supabase.auth.currentUser!.id;

  // ── Gather all trip data ─────────────────────────────────────────

  Future<_ExportData> _gatherData(Trip trip) async {
    // Run parallel fetches for performance
    final results = await Future.wait([
      _planService.fetchTripPlan(trip.id),
      _checklistService.getChecklist(trip.id),
      _fetchExpenses(trip.id),
      _fetchMemberProfiles(trip.memberIds),
      _fetchTripMetadata(trip.id),
    ]);

    return _ExportData(
      trip: trip,
      itinerary: results[0] as List<TripDay>,
      checklist: results[1] as List<ChecklistItem>,
      expenses: results[2] as List<TripExpense>,
      members: results[3] as List<UserProfile>,
      metadata: results[4] as Map<String, dynamic>?,
    );
  }

  Future<List<TripExpense>> _fetchExpenses(String tripId) async {
    try {
      final data = await _supabase
          .from('trip_expenses')
          .select('*, expense_splits(*)')
          .eq('trip_id', tripId)
          .order('created_at', ascending: false);
      return (data as List).map((e) => TripExpense.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<UserProfile>> _fetchMemberProfiles(List<String> memberIds) async {
    if (memberIds.isEmpty) return [];
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .inFilter('uid', memberIds);
      return (data as List).map((e) => UserProfile.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> _fetchTripMetadata(String tripId) async {
    try {
      final data = await _supabase
          .from('trip_metadata')
          .select()
          .eq('trip_id', tripId)
          .maybeSingle();
      return data;
    } catch (_) {
      return null;
    }
  }

  // ── PDF Export ───────────────────────────────────────────────────

  static const _brand = PdfColor.fromInt(0xFF6C63FF);
  static const _brandLight = PdfColor.fromInt(0xFFF3F2FF);
  static const _textDark = PdfColor.fromInt(0xFF1A1A2E);
  static const _textMid = PdfColor.fromInt(0xFF666680);
  static const _textLight = PdfColor.fromInt(0xFF9999AA);
  static const _divider = PdfColor.fromInt(0xFFE8E8F0);
  static const _tripUrl = 'https://wanderwith.online/trip';

  // ── Themes & Layout ─────────────────────────────────────────────

  pw.PageTheme _contentTheme() => pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 44),
        buildBackground: (_) => pw.FullPage(
          ignoreMargins: true,
          child: pw.Center(
            child: pw.Transform.rotate(
              angle: -0.40,
              child: pw.Opacity(
                opacity: 0.035,
                child: pw.Text(
                  'WANDERWITH',
                  style: pw.TextStyle(
                    fontSize: 82,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey,
                    letterSpacing: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  pw.Widget _pageHeader(_ExportData data) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 16),
        padding: const pw.EdgeInsets.only(bottom: 10),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _divider, width: 0.5)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Expanded(
              child: pw.Text(
                '${data.trip.name}  ·  ${data.trip.location}',
                style: pw.TextStyle(fontSize: 8, color: _textLight),
                maxLines: 1,
              ),
            ),
            pw.Text(
              'WANDERWITH',
              style: pw.TextStyle(
                fontSize: 7,
                color: _brand,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      );

  pw.Widget _pageFooter(pw.Context ctx) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 16),
        padding: const pw.EdgeInsets.only(top: 10),
        decoration: const pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: _divider, width: 0.5)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: pw.TextStyle(fontSize: 7, color: _textLight)),
            pw.Text('wanderwith.online',
                style: pw.TextStyle(fontSize: 7, color: _textLight)),
          ],
        ),
      );

  pw.Widget _section(String title) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 24, bottom: 14),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
                color: _textDark,
                letterSpacing: 1.5,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Container(width: 40, height: 2.5, color: _brand),
          ],
        ),
      );

  pw.Widget _label(String text) => pw.Text(
        text.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 7,
          color: _textMid,
          letterSpacing: 0.8,
          fontWeight: pw.FontWeight.bold,
        ),
      );

  pw.Widget _value(String text, {double fontSize = 10}) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 2),
        child: pw.Text(text, style: pw.TextStyle(fontSize: fontSize, color: _textDark)),
      );

  // ── Export Entry Points ─────────────────────────────────────────

  Future<void> exportAsPdf(Trip trip) async {
    final data = await _gatherData(trip);
    final doc = pw.Document(
      title: '${trip.name} - WanderWith Trip Plan',
      author: 'WanderWith',
    );

    doc.addPage(_buildCoverPage(data));
    doc.addPage(pw.MultiPage(
      pageTheme: _contentTheme(),
      header: (_) => _pageHeader(data),
      footer: _pageFooter,
      build: (_) => _buildOverviewWidgets(data),
    ));
    if (data.itinerary.isNotEmpty) {
      doc.addPage(pw.MultiPage(
        pageTheme: _contentTheme(),
        header: (_) => _pageHeader(data),
        footer: _pageFooter,
        build: (_) => _buildItineraryWidgets(data),
      ));
    }
    doc.addPage(pw.MultiPage(
      pageTheme: _contentTheme(),
      header: (_) => _pageHeader(data),
      footer: _pageFooter,
      build: (_) => _buildBudgetWidgets(data),
    ));
    if (data.checklist.isNotEmpty) {
      doc.addPage(pw.MultiPage(
        pageTheme: _contentTheme(),
        header: (_) => _pageHeader(data),
        footer: _pageFooter,
        build: (_) => _buildChecklistWidgets(data),
      ));
    }
    if (data.members.isNotEmpty) {
      doc.addPage(pw.MultiPage(
        pageTheme: _contentTheme(),
        header: (_) => _pageHeader(data),
        footer: _pageFooter,
        build: (_) => _buildCrewWidgets(data),
      ));
    }
    doc.addPage(_buildClosingPage(data));

    final bytes = await doc.save();
    final dir = await getTemporaryDirectory();
    final sanitized =
        trip.name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    final file = File('${dir.path}/${sanitized}_trip.pdf');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: '${trip.name} - Trip Plan (PDF)',
    );
  }

  Future<void> exportChecklistPdf(Trip trip) async {
    final data = await _gatherData(trip);
    if (data.checklist.isEmpty) return;

    final doc = pw.Document(
      title: '${trip.name} - Checklist',
      author: 'WanderWith',
    );

    doc.addPage(pw.MultiPage(
      pageTheme: _contentTheme(),
      header: (_) => _pageHeader(data),
      footer: _pageFooter,
      build: (_) => _buildChecklistWidgets(data),
    ));

    final bytes = await doc.save();
    final dir = await getTemporaryDirectory();
    final sanitized =
        trip.name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    final file = File('${dir.path}/${sanitized}_checklist.pdf');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: '${trip.name} - Checklist (PDF)',
    );
  }

  // ── Cover Page ──────────────────────────────────────────────────

  pw.Page _buildCoverPage(_ExportData data) {
    final fmt = DateFormat('MMM d, yyyy');
    final start =
        data.trip.startDate != null ? fmt.format(data.trip.startDate!) : '-';
    final end =
        data.trip.endDate != null ? fmt.format(data.trip.endDate!) : '-';
    final days = (data.trip.startDate != null && data.trip.endDate != null)
        ? '${data.trip.endDate!.difference(data.trip.startDate!).inDays + 1} days'
        : '-';
    final currency = data.trip.budgetCurrency;
    final budget = data.trip.estimatedCost > 0
        ? '$currency ${data.trip.estimatedCost.toStringAsFixed(0)}'
        : '-';

    return pw.Page(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
      ),
      build: (ctx) => pw.Column(
        children: [
          // ── Brand header band ──
          pw.Container(
            width: double.infinity,
            height: 340,
            padding: const pw.EdgeInsets.symmetric(horizontal: 48),
            decoration: const pw.BoxDecoration(color: _brand),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'WANDERWITH',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.white,
                    letterSpacing: 6,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 28),
                pw.Text(
                  data.trip.name,
                  style: pw.TextStyle(
                    fontSize: 32,
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0x33FFFFFF),
                    borderRadius: pw.BorderRadius.circular(20),
                  ),
                  child: pw.Text(
                    data.trip.location,
                    style: pw.TextStyle(
                        fontSize: 11, color: PdfColors.white),
                  ),
                ),
              ],
            ),
          ),

          // ── Info grid & QR ──
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 48, vertical: 32),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(children: [
                    pw.Expanded(
                        child: _coverTile('DATES', '$start  -  $end')),
                    pw.SizedBox(width: 24),
                    pw.Expanded(child: _coverTile('DURATION', days)),
                    pw.SizedBox(width: 24),
                    pw.Expanded(child: _coverTile('BUDGET', budget)),
                  ]),
                  pw.SizedBox(height: 20),
                  pw.Row(children: [
                    pw.Expanded(
                      child: _coverTile(
                        'TRAVELERS',
                        '${data.members.length} member${data.members.length == 1 ? '' : 's'}',
                      ),
                    ),
                    pw.SizedBox(width: 24),
                    pw.Expanded(
                        child:
                            _coverTile('CURRENCY', data.trip.budgetCurrency)),
                    pw.SizedBox(width: 24),
                    pw.Expanded(
                      child: _coverTile(
                        'TRIP ID',
                        data.trip.id.substring(0, 8).toUpperCase(),
                      ),
                    ),
                  ]),
                  pw.Spacer(),

                  // ── QR section ──
                  pw.Container(
                    padding: const pw.EdgeInsets.all(20),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: _divider, width: 0.5),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Row(children: [
                      pw.BarcodeWidget(
                        data: '$_tripUrl/${data.trip.id}',
                        barcode: pw.Barcode.qrCode(),
                        width: 80,
                        height: 80,
                      ),
                      pw.SizedBox(width: 20),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'SCAN TO VIEW ONLINE',
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: _textMid,
                                letterSpacing: 1,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 6),
                            pw.UrlLink(
                              destination: '$_tripUrl/${data.trip.id}',
                              child: pw.Text(
                                '$_tripUrl/${data.trip.id}',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: _brand,
                                  decoration: pw.TextDecoration.underline,
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Text(
                              'View the latest version of this trip, including live updates from your crew.',
                              style: pw.TextStyle(
                                  fontSize: 8, color: _textLight),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Center(
                    child: pw.Text(
                      'Generated on ${DateFormat('MMMM d, yyyy').format(DateTime.now())}',
                      style: pw.TextStyle(fontSize: 8, color: _textLight),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _coverTile(String label, String value) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 10),
        decoration: const pw.BoxDecoration(
          border:
              pw.Border(bottom: pw.BorderSide(color: _divider, width: 0.5)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 7,
                color: _textMid,
                letterSpacing: 1,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                color: _textDark,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      );

  // ── Overview Page ───────────────────────────────────────────────

  List<pw.Widget> _buildOverviewWidgets(_ExportData data) {
    final w = <pw.Widget>[];
    final fmt = DateFormat('MMMM d, yyyy');
    final start =
        data.trip.startDate != null ? fmt.format(data.trip.startDate!) : '-';
    final end =
        data.trip.endDate != null ? fmt.format(data.trip.endDate!) : '-';
    final days = (data.trip.startDate != null && data.trip.endDate != null)
        ? '${data.trip.endDate!.difference(data.trip.startDate!).inDays + 1}'
        : '-';

    w.add(_section('Trip Overview'));

    // Two-column detail grid
    w.add(pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _infoRow('Start Date', start),
              _infoRow('End Date', end),
              _infoRow('Duration', '$days days'),
              _infoRow(
                'Total Budget',
                data.trip.estimatedCost > 0
                    ? '${data.trip.budgetCurrency} ${data.trip.estimatedCost.toStringAsFixed(2)}'
                    : 'Not set',
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 32),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _infoRow('Currency', data.trip.budgetCurrency),
              _infoRow('Travelers', '${data.members.length}'),
              _infoRow('Location', data.trip.location),
              _infoRow(
                  'Trip ID', data.trip.id.substring(0, 8).toUpperCase()),
            ],
          ),
        ),
      ],
    ));

    // ── Destination Intelligence ──
    if (data.metadata != null) {
      final m = data.metadata!;
      final cards = <pw.Widget>[];
      if (m['timezone'] != null)
        cards.add(_intelCard('Timezone', m['timezone']));
      if (m['language'] != null)
        cards.add(_intelCard('Language', m['language']));
      if (m['currency_name'] != null)
        cards.add(_intelCard('Currency', m['currency_name']));
      if (m['dial_code'] != null)
        cards.add(_intelCard('Dial Code', m['dial_code']));
      if (m['plug_type'] != null)
        cards.add(_intelCard('Plug Type', m['plug_type']));
      if (m['tap_water_safe'] != null)
        cards.add(_intelCard(
            'Tap Water', m['tap_water_safe'] == true ? 'Safe' : 'Unsafe'));
      if (m['visa_required'] != null)
        cards.add(_intelCard('Visa', m['visa_required']));

      if (cards.isNotEmpty) {
        w.add(_section('Destination Intelligence'));
        w.add(pw.Wrap(spacing: 12, runSpacing: 12, children: cards));
      }

      // Emergency contact
      if (m['emergency_number'] != null) {
        w.add(pw.SizedBox(height: 20));
        w.add(pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFFFF3F3),
            border: pw.Border.all(
                color: PdfColor.fromInt(0xFFFFCCCC), width: 0.5),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'EMERGENCY',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColor.fromInt(0xFFCC0000),
                  letterSpacing: 1,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                m['emergency_number'].toString(),
                style: pw.TextStyle(
                  fontSize: 18,
                  color: PdfColor.fromInt(0xFFCC0000),
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ));
      }

      // Safety tips
      if (m['safety_tips'] != null) {
        w.add(pw.SizedBox(height: 12));
        w.add(pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFFFF9E6),
            border: pw.Border.all(
                color: PdfColor.fromInt(0xFFFFE0A0), width: 0.5),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'SAFETY TIPS',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColor.fromInt(0xFFB38600),
                  letterSpacing: 1,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                m['safety_tips'].toString(),
                style: pw.TextStyle(fontSize: 9, color: _textDark),
              ),
            ],
          ),
        ));
      }
    }

    return w;
  }

  pw.Widget _infoRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 12),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _label(label),
            _value(value),
          ],
        ),
      );

  pw.Widget _intelCard(String label, String value) => pw.Container(
        width: 150,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _divider, width: 0.5),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _label(label),
            pw.SizedBox(height: 4),
            pw.Text(
              value.toString(),
              style: pw.TextStyle(
                fontSize: 11,
                color: _textDark,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      );

  // ── Itinerary Pages ─────────────────────────────────────────────

  List<pw.Widget> _buildItineraryWidgets(_ExportData data) {
    final w = <pw.Widget>[];
    w.add(_section('Itinerary'));

    for (final day in data.itinerary) {
      // Day header
      w.add(pw.Padding(
        padding: const pw.EdgeInsets.only(top: 18, bottom: 10),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12, vertical: 5),
              decoration: pw.BoxDecoration(
                color: _brand,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                'DAY ${day.dayNumber}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
            pw.SizedBox(width: 12),
            if (day.date != null)
              pw.Text(
                DateFormat('EEEE, MMMM d, yyyy').format(day.date!),
                style: pw.TextStyle(fontSize: 10, color: _textMid),
              ),
          ],
        ),
      ));

      // Day summary
      if ((day.summary ?? '').isNotEmpty) {
        w.add(pw.Padding(
          padding: const pw.EdgeInsets.only(left: 4, bottom: 8),
          child: pw.Text(
            day.summary!,
            style: pw.TextStyle(
              fontSize: 9,
              color: _textMid,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ));
      }

      // Places with timeline
      for (final p in day.places) {
        w.add(pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 10),
          padding: const pw.EdgeInsets.only(left: 14),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
                left: pw.BorderSide(color: _brandLight, width: 2)),
          ),
          child: pw.Padding(
            padding: const pw.EdgeInsets.only(left: 12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        p.name,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: _textDark,
                        ),
                      ),
                    ),
                    if (p.type.isNotEmpty)
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: _brandLight,
                          borderRadius: pw.BorderRadius.circular(10),
                        ),
                        child: pw.Text(
                          p.type,
                          style: pw.TextStyle(
                            fontSize: 7,
                            color: _brand,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                if ((p.arrivalTime ?? '').isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 3),
                    child: pw.Text(p.arrivalTime!,
                        style: pw.TextStyle(fontSize: 9, color: _textMid)),
                  ),
                if ((p.description ?? '').isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 3),
                    child: pw.Text(p.description!,
                        style:
                            pw.TextStyle(fontSize: 9, color: _textLight)),
                  ),
              ],
            ),
          ),
        ));
      }
    }

    return w;
  }

  // ── Budget Page ─────────────────────────────────────────────────

  List<pw.Widget> _buildBudgetWidgets(_ExportData data) {
    final w = <pw.Widget>[];
    w.add(_section('Budget & Expenses'));

    final currency = data.trip.budgetCurrency;
    final totalBudget = data.trip.estimatedCost;
    final hasBudget = totalBudget > 0;
    final spent = data.expenses.fold<double>(0, (s, e) => s + e.amount);

    // Summary card
    w.add(pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: pw.BoxDecoration(
        color: _brandLight,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(children: [
        pw.Expanded(
          child: _budgetStat(
            'Total Budget',
            hasBudget
                ? '$currency ${totalBudget.toStringAsFixed(2)}'
                : 'Not set',
          ),
        ),
        pw.Expanded(
            child: _budgetStat(
                'Spent', '$currency ${spent.toStringAsFixed(2)}')),
        pw.Expanded(
          child: _budgetStat(
            'Remaining',
            hasBudget
                ? '$currency ${(totalBudget - spent).toStringAsFixed(2)}'
                : '-',
          ),
        ),
      ]),
    ));

    // Category breakdown
    if (data.expenses.isNotEmpty) {
      final grouped = _expensesByCategory(data.expenses);
      w.add(pw.SizedBox(height: 20));
      w.add(pw.Text(
        'SPENDING BY CATEGORY',
        style: pw.TextStyle(
          fontSize: 8,
          color: _textMid,
          letterSpacing: 1,
          fontWeight: pw.FontWeight.bold,
        ),
      ));
      w.add(pw.SizedBox(height: 10));

      w.add(pw.TableHelper.fromTextArray(
        border: pw.TableBorder.all(color: _divider, width: 0.5),
        headerStyle: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white),
        headerDecoration: const pw.BoxDecoration(color: _brand),
        cellStyle: pw.TextStyle(fontSize: 9, color: _textDark),
        cellPadding:
            const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        headers: ['Category', 'Amount', '% of Spent'],
        data: grouped.entries
            .map((e) => [
                  _categoryLabel(e.key),
                  '$currency ${e.value.toStringAsFixed(2)}',
                  spent > 0
                      ? '${(e.value / spent * 100).toStringAsFixed(1)}%'
                      : '-',
                ])
            .toList(),
      ));

      // Expense log
      w.add(pw.SizedBox(height: 20));
      w.add(pw.Text(
        'EXPENSE LOG',
        style: pw.TextStyle(
          fontSize: 8,
          color: _textMid,
          letterSpacing: 1,
          fontWeight: pw.FontWeight.bold,
        ),
      ));
      w.add(pw.SizedBox(height: 10));
      w.add(_buildExpenseTable(data.expenses, currency));
    }

    return w;
  }

  pw.Widget _budgetStat(String label, String value) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 7,
              color: _textMid,
              letterSpacing: 0.8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: _textDark,
            ),
          ),
        ],
      );

  pw.Widget _buildExpenseTable(
          List<TripExpense> expenses, String currency) =>
      pw.TableHelper.fromTextArray(
        border: pw.TableBorder.all(color: _divider, width: 0.5),
        headerStyle: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white),
        headerDecoration: const pw.BoxDecoration(color: _brand),
        cellStyle: pw.TextStyle(fontSize: 9, color: _textDark),
        cellPadding:
            const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        headers: ['Title', 'Amount', 'Category', 'Date'],
        data: expenses
            .map((e) => [
                  e.title,
                  '$currency ${e.amount.toStringAsFixed(2)}',
                  _categoryLabel(e.category),
                  DateFormat('MMM d').format(e.createdAt),
                ])
            .toList(),
      );

  // ── Checklist Pages ─────────────────────────────────────────────

  List<pw.Widget> _buildChecklistWidgets(_ExportData data) {
    final w = <pw.Widget>[];
    final checked = data.checklist.where((i) => i.isChecked).length;
    final total = data.checklist.length;

    w.add(_section('Packing & Checklist'));

    w.add(pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: pw.BoxDecoration(
        color: _brandLight,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        '$checked of $total items completed',
        style: pw.TextStyle(
            fontSize: 10, color: _brand, fontWeight: pw.FontWeight.bold),
      ),
    ));
    w.add(pw.SizedBox(height: 16));

    final grouped = <String, List<ChecklistItem>>{};
    for (final item in data.checklist) {
      (grouped[item.category] ??= []).add(item);
    }

    for (final entry in grouped.entries) {
      // Category header
      w.add(pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.only(top: 14),
        padding:
            const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: pw.BoxDecoration(
          color: _brandLight,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Text(
          _categoryLabel(entry.key).toUpperCase(),
          style: pw.TextStyle(
            fontSize: 8,
            color: _brand,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ));
      w.add(pw.SizedBox(height: 8));

      for (final item in entry.value) {
        w.add(pw.Padding(
          padding: const pw.EdgeInsets.only(left: 8, bottom: 6),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: 14,
                height: 14,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: item.isChecked ? _brand : _textLight,
                    width: 1,
                  ),
                  borderRadius: pw.BorderRadius.circular(3),
                  color: item.isChecked ? _brand : PdfColors.white,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Text(
                  item.itemText,
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: item.isChecked ? _textLight : _textDark,
                    decoration: item.isChecked
                        ? pw.TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ));
      }
    }

    return w;
  }

  // ── Crew Page ───────────────────────────────────────────────────

  List<pw.Widget> _buildCrewWidgets(_ExportData data) {
    final w = <pw.Widget>[];
    w.add(_section('Travel Crew'));
    w.add(pw.Text(
      '${data.members.length} traveler${data.members.length == 1 ? '' : 's'}',
      style: pw.TextStyle(fontSize: 10, color: _textMid),
    ));
    w.add(pw.SizedBox(height: 16));

    for (final m in data.members) {
      final isOwner = m.uid == data.trip.createdBy;
      final name = m.displayName ?? m.username ?? 'Unknown';
      w.add(pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 10),
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(
            color: isOwner ? _brand : _divider,
            width: isOwner ? 1.5 : 0.5,
          ),
          color: isOwner ? _brandLight : PdfColors.white,
        ),
        child: pw.Row(children: [
          pw.Container(
            width: 32,
            height: 32,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              color: isOwner ? _brand : PdfColor.fromInt(0xFFE0E0E8),
            ),
            child: pw.Center(
              child: pw.Text(
                name[0].toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: isOwner ? PdfColors.white : _textDark,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 14),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  name,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _textDark,
                  ),
                ),
                if (m.email != null)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Text(m.email!,
                        style:
                            pw.TextStyle(fontSize: 9, color: _textMid)),
                  ),
              ],
            ),
          ),
          pw.Container(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: pw.BoxDecoration(
              color: isOwner ? _brand : _brandLight,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Text(
              isOwner ? 'Trip Owner' : 'Member',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: isOwner ? PdfColors.white : _brand,
              ),
            ),
          ),
        ]),
      ));
    }

    return w;
  }

  // ── Closing Page ────────────────────────────────────────────────

  pw.Page _buildClosingPage(_ExportData data) => pw.Page(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(48),
        ),
        build: (ctx) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'WANDERWITH',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: _brand,
                  letterSpacing: 8,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Thank you for planning with us',
                style: pw.TextStyle(fontSize: 12, color: _textMid),
              ),
              pw.SizedBox(height: 40),
              pw.Container(
                padding: const pw.EdgeInsets.all(24),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _divider, width: 0.5),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(children: [
                  pw.BarcodeWidget(
                    data: '$_tripUrl/${data.trip.id}',
                    barcode: pw.Barcode.qrCode(),
                    width: 140,
                    height: 140,
                  ),
                  pw.SizedBox(height: 16),
                  pw.UrlLink(
                    destination: '$_tripUrl/${data.trip.id}',
                    child: pw.Text(
                      '$_tripUrl/${data.trip.id}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: _brand,
                        decoration: pw.TextDecoration.underline,
                      ),
                    ),
                  ),
                ]),
              ),
              pw.SizedBox(height: 40),
              pw.Container(width: 60, height: 0.5, color: _divider),
              pw.SizedBox(height: 20),
              pw.Text(
                'Made for travelers, by travelers',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: _textLight,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Generated ${DateFormat('MMMM d, yyyy').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 8, color: _textLight),
              ),
            ],
          ),
        ),
      );

  // ── Shared Helpers ──────────────────────────────────────────────

  Map<String, double> _expensesByCategory(List<TripExpense> expenses) {
    final map = <String, double>{};
    for (final e in expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  Map<String, List<ChecklistItem>> _groupByCategory(
      List<ChecklistItem> items) {
    final map = <String, List<ChecklistItem>>{};
    for (final item in items) {
      map.putIfAbsent(item.category, () => []).add(item);
    }
    return map;
  }

  String _categoryLabel(String cat) {
    const labels = {
      'documents': 'Documents',
      'packing': 'Packing',
      'bookings': 'Bookings',
      'health': 'Health',
      'money': 'Money',
      'general': 'General',
      'food': 'Food & Dining',
      'transport': 'Transport',
      'accommodation': 'Accommodation',
      'entertainment': 'Entertainment',
      'shopping': 'Shopping',
      'other': 'Other',
    };
    return labels[cat] ?? cat;
  }


  // ── JSON Export ──────────────────────────────────────────────────

  Future<void> exportAsJson(Trip trip) async {
    final data = await _gatherData(trip);

    final json = {
      'export_version': '1.0',
      'exported_at': DateTime.now().toIso8601String(),
      'trip': {
        'name': data.trip.name,
        'location': data.trip.location,
        'start_date': data.trip.startDate?.toIso8601String(),
        'end_date': data.trip.endDate?.toIso8601String(),
        'status': data.trip.status,
        'type': data.trip.metadata?['trip_type'],
        'budget_currency': data.trip.budgetCurrency,
        'estimated_cost': data.trip.estimatedCost,
        'visibility': data.trip.visibility,
      },
      'members': data.members
          .map((m) => {
                'name': m.displayName ?? m.username,
                'role': m.uid == data.trip.createdBy ? 'admin' : 'member',
              })
          .toList(),
      'itinerary': data.itinerary
          .map((day) => {
                'day_number': day.dayNumber,
                'date': day.date?.toIso8601String(),
                'summary': day.summary,
                'places': day.places
                    .map((p) => {
                          'name': p.name,
                          'type': p.type,
                          'description': p.description,
                          'arrival_time': p.arrivalTime,
                        })
                    .toList(),
              })
          .toList(),
      'checklist': data.checklist
          .map((item) => {
                'text': item.itemText,
                'category': item.category,
                'checked': item.isChecked,
              })
          .toList(),
      'expenses': data.expenses
          .map((e) => {
                'title': e.title,
                'amount': e.amount,
                'currency': e.currency,
                'category': e.category,
                'date': e.createdAt.toIso8601String(),
                'notes': e.notes,
              })
          .toList(),
      if (data.metadata != null)
        'destination_info': {
          'emergency_number': data.metadata!['emergency_number'],
          'timezone': data.metadata!['timezone'],
          'language': data.metadata!['language'],
          'currency': data.metadata!['currency_name'],
          'visa_required': data.metadata!['visa_required'],
          'safety_tips': data.metadata!['safety_tips'],
        },
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(json);
    final dir = await getTemporaryDirectory();
    final sanitized = trip.name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    final file = File('${dir.path}/${sanitized}_trip.json');
    await file.writeAsString(jsonStr);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: '${trip.name} — Trip Data (JSON)',
    );
  }
}

/// Internal data container for export.
class _ExportData {
  final Trip trip;
  final List<TripDay> itinerary;
  final List<ChecklistItem> checklist;
  final List<TripExpense> expenses;
  final List<UserProfile> members;
  final Map<String, dynamic>? metadata;

  _ExportData({
    required this.trip,
    required this.itinerary,
    required this.checklist,
    required this.expenses,
    required this.members,
    this.metadata,
  });
}
