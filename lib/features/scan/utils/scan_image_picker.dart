import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lazychef/core/router/app_router.dart';
import 'package:lazychef/features/scan/models/scan_image_selection.dart';

Future<void> showScanImagePickerOptions(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (BuildContext context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Upload from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      );
    },
  );

  if (source == null || !context.mounted) {
    return;
  }

  await pickScanImage(context, source);
}

Future<void> pickScanImage(BuildContext context, ImageSource source) async {
  try {
    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (image == null || !context.mounted) {
      return;
    }

    Navigator.pushNamed(
      context,
      AppRouter.scanResult,
      arguments: ScanImageSelection(image: image, source: source),
    );
  } catch (_) {
    if (!context.mounted) {
      return;
    }

    final sourceLabel = source == ImageSource.camera ? 'camera' : 'gallery';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Could not open $sourceLabel. Check app permissions and try again.',
        ),
      ),
    );
  }
}
