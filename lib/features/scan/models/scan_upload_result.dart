class ScanUploadResult {
  const ScanUploadResult({
    required this.scan,
    required this.image,
    required this.analysis,
  });

  factory ScanUploadResult.fromJson(Map<String, dynamic> json) {
    return ScanUploadResult(
      scan: SavedScan.fromJson(_jsonMap(json['scan'])),
      image: CloudinaryImage.fromJson(_jsonMap(json['image'])),
      analysis: VisionAnalysis.fromJson(_jsonMap(json['analysis'])),
    );
  }

  final SavedScan scan;
  final CloudinaryImage image;
  final VisionAnalysis analysis;
}

Map<String, dynamic> _jsonMap(Object? value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return const {};
}

class SavedScan {
  const SavedScan({
    required this.id,
    required this.userId,
    required this.imageUrl,
  });

  factory SavedScan.fromJson(Map<String, dynamic> json) {
    return SavedScan(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }

  final String id;
  final String userId;
  final String imageUrl;
}

class CloudinaryImage {
  const CloudinaryImage({
    required this.publicId,
    required this.imageUrl,
    required this.secureUrl,
    required this.width,
    required this.height,
    required this.format,
    required this.bytes,
  });

  factory CloudinaryImage.fromJson(Map<String, dynamic> json) {
    return CloudinaryImage(
      publicId: json['publicId'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      secureUrl: json['secureUrl'] as String? ?? '',
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      format: json['format'] as String? ?? 'unknown',
      bytes: (json['bytes'] as num?)?.toInt() ?? 0,
    );
  }

  final String publicId;
  final String imageUrl;
  final String secureUrl;
  final int width;
  final int height;
  final String format;
  final int bytes;
}

class VisionAnalysis {
  const VisionAnalysis({
    required this.provider,
    required this.model,
    required this.status,
    required this.detectedIngredients,
    required this.message,
  });

  factory VisionAnalysis.fromJson(Map<String, dynamic> json) {
    final ingredients = json['detectedIngredients'];

    return VisionAnalysis(
      provider: json['provider'] as String? ?? 'placeholder',
      model: json['model'] as String? ?? 'unknown',
      status: json['status'] as String? ?? 'pending',
      detectedIngredients: ingredients is List
          ? ingredients
                .whereType<Map>()
                .map((ingredient) => Map<String, dynamic>.from(ingredient))
                .map(DetectedIngredient.fromJson)
                .toList()
          : const [],
      message: json['message'] as String? ?? '',
    );
  }

  final String provider;
  final String model;
  final String status;
  final List<DetectedIngredient> detectedIngredients;
  final String message;
}

class DetectedIngredient {
  const DetectedIngredient({required this.name, required this.confidence});

  factory DetectedIngredient.fromJson(Map<String, dynamic> json) {
    return DetectedIngredient(
      name: json['name'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
    );
  }

  final String name;
  final double confidence;
}
