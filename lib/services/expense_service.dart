import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense.dart';
import 'chat_event_service.dart';

class ExpenseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Stream of expenses for a trip (real-time)
  Stream<List<TripExpense>> getExpensesStream(String tripId) {
    return _supabase
        .from('trip_expenses')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId)
        .order('created_at', ascending: false)
        .asyncMap((rows) async {
      if (rows.isEmpty) return <TripExpense>[];

      // Fetch all splits for these expenses in one query
      final expenseIds = rows.map((r) => r['id'] as String).toList();
      final splits = await _supabase
          .from('expense_splits')
          .select()
          .inFilter('expense_id', expenseIds);

      // Group splits by expense_id
      final splitsMap = <String, List<Map<String, dynamic>>>{};
      for (final s in splits) {
        final eid = s['expense_id'] as String;
        splitsMap.putIfAbsent(eid, () => []).add(s);
      }

      return rows.map((r) {
        r['expense_splits'] = splitsMap[r['id']] ?? [];
        return TripExpense.fromJson(r);
      }).toList();
    });
  }

  /// Add a new expense with splits
  Future<void> addExpense({
    required String tripId,
    required String title,
    required double amount,
    required String currency,
    required String category,
    required String paidBy,
    required String splitType,
    required List<String> splitAmongUserIds,
    String? notes,
  }) async {
    // Insert expense
    final expenseRow = await _supabase
        .from('trip_expenses')
        .insert({
          'trip_id': tripId,
          'title': title,
          'amount': amount,
          'currency': currency,
          'category': category,
          'paid_by': paidBy,
          'split_type': splitType,
          'notes': notes,
        })
        .select()
        .single();

    final expenseId = expenseRow['id'] as String;

    // Calculate splits
    List<Map<String, dynamic>> splitRows;
    if (splitType == 'equal') {
      final perPerson = amount / splitAmongUserIds.length;
      splitRows = splitAmongUserIds
          .map((uid) => {
                'expense_id': expenseId,
                'user_id': uid,
                'amount': double.parse(perPerson.toStringAsFixed(2)),
              })
          .toList();
    } else {
      // For 'full' split — payer owes nothing, everyone else owes equally
      final others =
          splitAmongUserIds.where((uid) => uid != paidBy).toList();
      if (others.isEmpty) return;
      final perPerson = amount / others.length;
      splitRows = others
          .map((uid) => {
                'expense_id': expenseId,
                'user_id': uid,
                'amount': double.parse(perPerson.toStringAsFixed(2)),
              })
          .toList();
    }

    if (splitRows.isNotEmpty) {
      await _supabase.from('expense_splits').insert(splitRows);
    }

    // Post system message to chat
    try {
      final userData = await _supabase.from('profiles').select('display_name').eq('id', paidBy).maybeSingle();
      final payerName = userData?['display_name'] ?? 'Someone';
      await ChatEventService.instance.expenseAdded(tripId, payerName, title, amount, currency);
    } catch (_) {}
  }

  /// Mark a specific split as settled
  Future<void> settleUp(String splitId) async {
    await _supabase.from('expense_splits').update({
      'is_settled': true,
      'settled_at': DateTime.now().toIso8601String(),
    }).eq('id', splitId);
  }

  /// Delete an expense and its splits (cascade handled by DB)
  Future<void> deleteExpense(String expenseId) async {
    // Delete splits first then expense
    await _supabase
        .from('expense_splits')
        .delete()
        .eq('expense_id', expenseId);
    await _supabase.from('trip_expenses').delete().eq('id', expenseId);
  }
}
