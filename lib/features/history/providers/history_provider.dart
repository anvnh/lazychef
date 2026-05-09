import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lazychef/features/history/data/history_repository.dart';
import 'package:lazychef/features/history/models/history_scan.dart';

final scanHistoryProvider = FutureProvider.autoDispose<List<HistoryScan>>((
  ref,
) async {
  final repository = ref.watch(historyRepositoryProvider);
  return repository.fetchScanHistory();
}, retry: (_, _) => null);
