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

  Future<void> exportAsPdf(Trip trip) async {
    final data = await _gatherData(trip);
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM d, yyyy');
    final brandColor = PdfColor.fromHex('#6C63FF');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _buildPdfHeader(data, dateFormat, brandColor),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount} — Exported via WanderWith',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
          ),
        ),
        build: (ctx) => [
          // ── Trip Overview ──
          _pdfSection('Trip Overview', brandColor),
          _pdfKeyValue('Location', data.trip.location),
          if (data.trip.startDate != null && data.trip.endDate != null)
            _pdfKeyValue('Dates',
                '${dateFormat.format(data.trip.startDate!)} — ${dateFormat.format(data.trip.endDate!)}'),
          if (data.trip.metadata?['trip_type'] != null)
            _pdfKeyValue('Type', data.trip.metadata!['trip_type'].toString()),
          if (data.trip.estimatedCost > 0)
            _pdfKeyValue('Budget',
                '${data.trip.budgetCurrency} ${data.trip.estimatedCost.toStringAsFixed(0)}'),
          _pdfKeyValue('Status', data.trip.status.toUpperCase()),
          pw.SizedBox(height: 16),

          // ── Members ──
          if (data.members.isNotEmpty) ...[
            _pdfSection('Members (${data.members.length})', brandColor),
            ...data.members.map((m) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(children: [
                    pw.Container(
                      width: 8,
                      height: 8,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        color: brandColor,
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      '${m.displayName ?? m.username ?? 'Unknown'}${m.uid == data.trip.createdBy ? ' (Admin)' : ''}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ]),
                )),
            pw.SizedBox(height: 16),
          ],

          // ── Itinerary ──
          if (data.itinerary.isNotEmpty) ...[
            _pdfSection('Itinerary (${data.itinerary.length} days)', brandColor),
            ...data.itinerary.map((day) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: brandColor,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          'Day ${day.dayNumber}${day.summary != null ? ' — ${day.summary}' : ''}',
                          style: pw.TextStyle(fontSize: 11, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      ...day.places.map((p) => pw.Padding(
                            padding: const pw.EdgeInsets.only(left: 16, bottom: 3),
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('• ', style: pw.TextStyle(fontSize: 11, color: brandColor)),
                                pw.Expanded(
                                  child: pw.RichText(
                                    text: pw.TextSpan(
                                      children: [
                                        pw.TextSpan(
                                          text: p.name,
                                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                                        ),
                                        if (p.type.isNotEmpty)
                                          pw.TextSpan(
                                            text: ' (${p.type})',
                                            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                                          ),
                                        if (p.arrivalTime != null && p.arrivalTime!.isNotEmpty)
                                          pw.TextSpan(
                                            text: ' at ${p.arrivalTime}',
                                            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                )),
            pw.SizedBox(height: 8),
          ],

          // ── Checklist ──
          if (data.checklist.isNotEmpty) ...[
            _pdfSection('Checklist (${data.checklist.length} items)', brandColor),
            ..._groupByCategory(data.checklist).entries.map((entry) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      _categoryLabel(entry.key),
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: brandColor),
                    ),
                    pw.SizedBox(height: 4),
                    ...entry.value.map((item) => pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 12, bottom: 2),
                          child: pw.Row(children: [
                            pw.Text(item.isChecked ? '☑ ' : '☐ ', style: const pw.TextStyle(fontSize: 11)),
                            pw.Expanded(
                              child: pw.Text(item.itemText, style: const pw.TextStyle(fontSize: 11)),
                            ),
                          ]),
                        )),
                    pw.SizedBox(height: 8),
                  ],
                )),
            pw.SizedBox(height: 8),
          ],

          // ── Expenses ──
          if (data.expenses.isNotEmpty) ...[
            _pdfSection('Expenses', brandColor),
            _buildExpenseTable(data),
            pw.SizedBox(height: 8),
            _pdfKeyValue('Total Spent',
                '${data.expenses.first.currency} ${data.expenses.fold(0.0, (sum, e) => sum + e.amount).toStringAsFixed(2)}'),
            pw.SizedBox(height: 16),
          ],

          // ── Emergency Info ──
          if (data.metadata != null) ...[
            _pdfSection('Destination Info', brandColor),
            if (data.metadata!['emergency_number'] != null)
              _pdfKeyValue('Emergency', data.metadata!['emergency_number']),
            if (data.metadata!['timezone'] != null)
              _pdfKeyValue('Timezone', data.metadata!['timezone']),
            if (data.metadata!['language'] != null)
              _pdfKeyValue('Language', data.metadata!['language']),
            if (data.metadata!['currency_name'] != null)
              _pdfKeyValue('Currency', '${data.metadata!['currency_name']} (${data.metadata!['currency_code'] ?? ''})'),
            if (data.metadata!['visa_required'] != null)
              _pdfKeyValue('Visa', data.metadata!['visa_required']),
            if (data.metadata!['safety_tips'] != null) ...[
              pw.SizedBox(height: 6),
              pw.Text('Safety Tips', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
              pw.SizedBox(height: 3),
              pw.Text(data.metadata!['safety_tips'], style: const pw.TextStyle(fontSize: 10)),
            ],
          ],
        ],
      ),
    );

    // Save and share
    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final sanitized = trip.name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    final file = File('${dir.path}/${sanitized}_trip.pdf');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: '${trip.name} — Trip Details',
    );
  }

  pw.Widget _buildPdfHeader(_ExportData data, DateFormat fmt, PdfColor brand) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: brand,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(data.trip.name,
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
          pw.SizedBox(height: 4),
          pw.Text(data.trip.location,
              style: pw.TextStyle(fontSize: 13, color: PdfColors.white)),
          if (data.trip.startDate != null)
            pw.Text(
              '${fmt.format(data.trip.startDate!)}${data.trip.endDate != null ? ' — ${fmt.format(data.trip.endDate!)}' : ''}',
              style: pw.TextStyle(fontSize: 11, color: PdfColors.grey200),
            ),
        ],
      ),
    );
  }

  pw.Widget _pdfSection(String title, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10, top: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: color)),
          pw.Divider(color: color, thickness: 1),
        ],
      ),
    );
  }

  pw.Widget _pdfKeyValue(String key, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text('$key:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
          ),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 11))),
        ],
      ),
    );
  }

  pw.Widget _buildExpenseTable(_ExportData data) {
    final dateFmt = DateFormat('MMM d');
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey200),
          children: ['Item', 'Amount', 'Category', 'Date']
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(h, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ))
              .toList(),
        ),
        ...data.expenses.map((e) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(e.title, style: const pw.TextStyle(fontSize: 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('${e.currency} ${e.amount.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(e.category, style: const pw.TextStyle(fontSize: 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(dateFmt.format(e.createdAt), style: const pw.TextStyle(fontSize: 10)),
                ),
              ],
            )),
      ],
    );
  }

  Map<String, List<ChecklistItem>> _groupByCategory(List<ChecklistItem> items) {
    final map = <String, List<ChecklistItem>>{};
    for (final item in items) {
      map.putIfAbsent(item.category, () => []).add(item);
    }
    return map;
  }

  String _categoryLabel(String cat) {
    const labels = {
      'documents': '📄 Documents',
      'packing': '🧳 Packing',
      'bookings': '🏨 Bookings',
      'health': '💊 Health',
      'money': '💰 Money',
      'general': '📋 General',
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
