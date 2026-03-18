import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/insight_period.dart';
import '../../domain/entities/insight_report.dart';
import '../../domain/usecases/compute_insight_report_use_case.dart';
import '../providers/insight_providers.dart';

class InsightController extends AsyncNotifier<InsightReport> {
  late ComputeInsightReportUseCase _compute;

  @override
  Future<InsightReport> build() async {
    _compute = ref.read(computeInsightReportUseCaseProvider);

    final selection = ref.watch(insightSelectionProvider);

    return _compute(dateFrom: selection.dateFrom, dateTo: selection.dateTo);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

class InsightSelection {
  const InsightSelection.period(InsightPeriod period)
    : _period = period,
      _customFrom = null,
      _customTo = null;

  const InsightSelection.custom({
    required DateTime dateFrom,
    required DateTime dateTo,
  }) : _period = null,
       _customFrom = dateFrom,
       _customTo = dateTo;

  final InsightPeriod? _period;
  final DateTime? _customFrom;
  final DateTime? _customTo;

  bool get isCustom => _period == null;
  InsightPeriod? get period => _period;

  DateTime get dateFrom => _period != null ? _period.dateFrom : _customFrom!;

  DateTime get dateTo => _period != null ? _period.dateTo : _customTo!;

  String get customRangeLabel {
    if (!isCustom) return '';
    return '${_fmt(_customFrom!)} – ${_fmt(_customTo!)}';
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  @override
  bool operator ==(Object other) =>
      other is InsightSelection &&
      other._period == _period &&
      other._customFrom == _customFrom &&
      other._customTo == _customTo;

  @override
  int get hashCode => Object.hash(_period, _customFrom, _customTo);
}

class InsightSelectionNotifier extends Notifier<InsightSelection> {
  @override
  InsightSelection build() =>
      const InsightSelection.period(InsightPeriod.monthly);

  void selectPeriod(InsightPeriod period) {
    state = InsightSelection.period(period);
  }

  void selectCustomRange({
    required DateTime dateFrom,
    required DateTime dateTo,
  }) {
    state = InsightSelection.custom(dateFrom: dateFrom, dateTo: dateTo);
  }
}
