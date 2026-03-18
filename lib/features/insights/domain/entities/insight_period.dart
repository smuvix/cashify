enum InsightPeriod {
  monthly,
  threeMonths,
  sixMonths,
  yearly;

  String get label => switch (this) {
    InsightPeriod.monthly => '1 Month',
    InsightPeriod.threeMonths => '3 Months',
    InsightPeriod.sixMonths => '6 Months',
    InsightPeriod.yearly => '1 Year',
  };

  DateTime get dateFrom {
    final now = DateTime.now();
    return switch (this) {
      InsightPeriod.monthly => DateTime(now.year, now.month, 1),
      InsightPeriod.threeMonths => DateTime(now.year, now.month - 2, 1),
      InsightPeriod.sixMonths => DateTime(now.year, now.month - 5, 1),
      InsightPeriod.yearly => DateTime(now.year, 1, 1),
    };
  }

  DateTime get dateTo {
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day + 1,
    ).subtract(const Duration(milliseconds: 1));
  }
}
