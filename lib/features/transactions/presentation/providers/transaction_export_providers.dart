import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../categories/presentation/providers/category_providers.dart';
import '../../data/services/transaction_pdf_service.dart';
import '../../domain/usecases/export_transactions_use_case.dart';
import 'transaction_providers.dart';

final transactionPdfServiceProvider = Provider<TransactionPdfService>(
  (_) => const TransactionPdfService(),
);

final exportTransactionsUseCaseProvider = Provider<ExportTransactionsUseCase>(
  (ref) => ExportTransactionsUseCase(
    ref.read(transactionRepositoryProvider),
    ref.read(categoryRepositoryProvider),
    ref.read(transactionPdfServiceProvider),
  ),
);
