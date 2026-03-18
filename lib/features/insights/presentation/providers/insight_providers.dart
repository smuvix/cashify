import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../domain/entities/insight_report.dart';
import '../../domain/usecases/compute_insight_report_use_case.dart';
import '../controllers/insight_controller.dart';

final computeInsightReportUseCaseProvider =
    Provider<ComputeInsightReportUseCase>(
      (ref) =>
          ComputeInsightReportUseCase(ref.read(transactionRepositoryProvider)),
    );

final insightSelectionProvider =
    NotifierProvider<InsightSelectionNotifier, InsightSelection>(
      InsightSelectionNotifier.new,
    );

final insightProvider = AsyncNotifierProvider<InsightController, InsightReport>(
  InsightController.new,
);
