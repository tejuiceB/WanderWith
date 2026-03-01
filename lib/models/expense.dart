import 'dart:math';

class TripExpense {
  final String id;
  final String tripId;
  final String title;
  final double amount;
  final String currency;
  final String category;
  final String paidBy;
  final String splitType; // 'equal', 'custom', 'full'
  final DateTime createdAt;
  final String? receiptUrl;
  final String? notes;
  final List<ExpenseSplit> splits;

  TripExpense({
    required this.id,
    required this.tripId,
    required this.title,
    required this.amount,
    required this.currency,
    required this.category,
    required this.paidBy,
    required this.splitType,
    required this.createdAt,
    this.receiptUrl,
    this.notes,
    this.splits = const [],
  });

  factory TripExpense.fromJson(Map<String, dynamic> json) {
    return TripExpense(
      id: json['id'] ?? '',
      tripId: json['trip_id'] ?? '',
      title: json['title'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'INR',
      category: json['category'] ?? 'general',
      paidBy: json['paid_by'] ?? '',
      splitType: json['split_type'] ?? 'equal',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      receiptUrl: json['receipt_url'],
      notes: json['notes'],
      splits: (json['expense_splits'] as List<dynamic>?)
              ?.map((e) => ExpenseSplit.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'trip_id': tripId,
        'title': title,
        'amount': amount,
        'currency': currency,
        'category': category,
        'paid_by': paidBy,
        'split_type': splitType,
        'receipt_url': receiptUrl,
        'notes': notes,
      };

  /// Icon data for each category
  static String categoryEmoji(String category) {
    switch (category) {
      case 'food':
        return '🍽️';
      case 'transport':
        return '🚕';
      case 'accommodation':
        return '🏨';
      case 'activity':
        return '🎯';
      case 'shopping':
        return '🛍️';
      default:
        return '💰';
    }
  }
}

class ExpenseSplit {
  final String id;
  final String expenseId;
  final String userId;
  final double amount;
  final bool isSettled;
  final DateTime? settledAt;

  ExpenseSplit({
    required this.id,
    required this.expenseId,
    required this.userId,
    required this.amount,
    this.isSettled = false,
    this.settledAt,
  });

  factory ExpenseSplit.fromJson(Map<String, dynamic> json) {
    return ExpenseSplit(
      id: json['id'] ?? '',
      expenseId: json['expense_id'] ?? '',
      userId: json['user_id'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      isSettled: json['is_settled'] ?? false,
      settledAt: json['settled_at'] != null
          ? DateTime.parse(json['settled_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'expense_id': expenseId,
        'user_id': userId,
        'amount': amount,
        'is_settled': isSettled,
      };
}

/// Represents a simplified debt: from owes to some amount
class SimplifiedDebt {
  final String fromUserId;
  final String toUserId;
  final double amount;

  SimplifiedDebt({
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
  });
}

/// Calculate net balances from expenses
/// Positive = others owe you | Negative = you owe others
Map<String, double> calculateBalances(List<TripExpense> expenses) {
  final balances = <String, double>{};
  for (final expense in expenses) {
    // Person who paid gets credited the full amount
    balances[expense.paidBy] =
        (balances[expense.paidBy] ?? 0) + expense.amount;
    // Each person in split gets debited
    for (final split in expense.splits) {
      balances[split.userId] =
          (balances[split.userId] ?? 0) - split.amount;
    }
  }
  return balances;
}

/// Simplify debts to minimize number of transactions
List<SimplifiedDebt> simplifyDebts(Map<String, double> balances) {
  final debtors = <String, double>{}; // people who owe (negative balance)
  final creditors = <String, double>{}; // people who are owed (positive balance)

  for (final entry in balances.entries) {
    if (entry.value < -0.01) {
      debtors[entry.key] = -entry.value; // store as positive for clarity
    }
    if (entry.value > 0.01) {
      creditors[entry.key] = entry.value;
    }
  }

  final debtorList = debtors.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final creditorList = creditors.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final debts = <SimplifiedDebt>[];
  int i = 0, j = 0;
  final dAmounts = debtorList.map((e) => e.value).toList();
  final cAmounts = creditorList.map((e) => e.value).toList();

  while (i < debtorList.length && j < creditorList.length) {
    final transfer = min(dAmounts[i], cAmounts[j]);
    debts.add(SimplifiedDebt(
      fromUserId: debtorList[i].key,
      toUserId: creditorList[j].key,
      amount: double.parse(transfer.toStringAsFixed(2)),
    ));
    dAmounts[i] -= transfer;
    cAmounts[j] -= transfer;
    if (dAmounts[i] < 0.01) i++;
    if (cAmounts[j] < 0.01) j++;
  }

  return debts;
}
