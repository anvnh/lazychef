import 'package:image_picker/image_picker.dart';

class ScanImageSelection {
  const ScanImageSelection({required this.image, required this.source});

  final XFile image;
  final ImageSource source;
}
