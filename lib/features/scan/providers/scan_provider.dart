import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lazychef/features/scan/data/scan_repository.dart';
import 'package:lazychef/features/scan/models/scan_image_selection.dart';
import 'package:lazychef/features/scan/models/scan_upload_result.dart';

final scanUploadProvider = FutureProvider.autoDispose
    .family<ScanUploadResult, ScanImageSelection>((ref, selection) async {
      final repository = ref.watch(scanRepositoryProvider);
      return repository.uploadScanImage(selection.image);
    });
