import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';

/// Predefined high quality gear preset images for easy selection & demo.
class GearImagePreset {
  final String title;
  final String categoryId;
  final String imageUrl;

  const GearImagePreset({
    required this.title,
    required this.categoryId,
    required this.imageUrl,
  });

  static const List<GearImagePreset> presets = [
    GearImagePreset(
      title: 'Kookaburra Pro Cricket Kit',
      categoryId: 'cricket',
      imageUrl: 'assets/images/gear_cricket_kit.jpg',
    ),
    GearImagePreset(
      title: 'Yonex Astrox Badminton Set',
      categoryId: 'badminton',
      imageUrl: 'assets/images/gear_badminton_set.jpg',
    ),
    GearImagePreset(
      title: 'Kingsley Reserve Cricket Bat',
      categoryId: 'cricket',
      imageUrl: 'assets/images/gear_cricket_bat.jpg',
    ),
    GearImagePreset(
      title: 'Trek Fuel Mountain Bike',
      categoryId: 'mountain_bikes',
      imageUrl:
          'https://images.unsplash.com/photo-1576435728678-68d0fbf94e91?auto=format&fit=crop&w=1200&q=80',
    ),
    GearImagePreset(
      title: 'Specialized Trail Bike',
      categoryId: 'mountain_bikes',
      imageUrl:
          'https://images.unsplash.com/photo-1485965120184-e220f721d03e?auto=format&fit=crop&w=1200&q=80',
    ),
    GearImagePreset(
      title: '4-Person Dome Camping Tent',
      categoryId: 'camping',
      imageUrl:
          'https://images.unsplash.com/photo-1504280390367-361c6d9f38f4?auto=format&fit=crop&w=1200&q=80',
    ),
    GearImagePreset(
      title: 'Osprey 65L Hiking Backpack',
      categoryId: 'camping',
      imageUrl:
          'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?auto=format&fit=crop&w=1200&q=80',
    ),
    GearImagePreset(
      title: 'Tandem Touring Kayak',
      categoryId: 'water_sports',
      imageUrl:
          'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=1200&q=80',
    ),
    GearImagePreset(
      title: 'Stand-Up Paddleboard (SUP)',
      categoryId: 'water_sports',
      imageUrl:
          'https://images.unsplash.com/photo-1508873696983-2df5293cb395?auto=format&fit=crop&w=1200&q=80',
    ),
    GearImagePreset(
      title: 'Burton All-Mountain Snowboard',
      categoryId: 'winter_sports',
      imageUrl:
          'https://images.unsplash.com/photo-1565992441121-4367c2967103?auto=format&fit=crop&w=1200&q=80',
    ),
    GearImagePreset(
      title: 'Sony Alpha A7 IV Camera Kit',
      categoryId: 'cameras',
      imageUrl:
          'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=1200&q=80',
    ),
    GearImagePreset(
      title: 'DJI Mini Pro Drone Bundle',
      categoryId: 'cameras',
      imageUrl:
          'https://images.unsplash.com/photo-1508614589041-895b88991e3e?auto=format&fit=crop&w=1200&q=80',
    ),
    GearImagePreset(
      title: 'DeWalt 20V Max Power Drill Kit',
      categoryId: 'tools',
      imageUrl:
          'https://images.unsplash.com/photo-1504148455328-c376907d081c?auto=format&fit=crop&w=1200&q=80',
    ),
  ];
}

/// Helper methods for image capturing, encoding and presentation.
class ImageHelper {
  ImageHelper._();

  static final ImagePicker _picker = ImagePicker();

  /// Captures an image from Camera and returns base64 or file path.
  static Future<String?> pickFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (photo == null) return null;
      return await _fileToBase64DataUrl(photo);
    } catch (e) {
      debugPrint('Error picking from camera: $e');
      return null;
    }
  }

  /// Picks an image from device Gallery and returns base64 or file path.
  static Future<String?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image == null) return null;
      return await _fileToBase64DataUrl(image);
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
      return null;
    }
  }

  /// Converts an [XFile] to base64 data URL string so it can be stored directly.
  static Future<String> _fileToBase64DataUrl(XFile file) async {
    final bytes = await file.readAsBytes();
    final base64String = base64Encode(bytes);
    return 'data:image/jpeg;base64,$base64String';
  }

  /// Uploads listing photo to Cloud Storage; returns public download URL only.
  static Future<String> uploadEquipmentPhoto(
    String equipmentId,
    Uint8List bytes,
  ) async {
    if (bytes.isEmpty || bytes.length > 4 * 1024 * 1024) {
      throw StateError('Equipment photo must be under 4 MB.');
    }
    final ref =
        FirebaseStorage.instance.ref('equipment_photos/$equipmentId.jpg');
    await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  /// Converts base64 data URLs / local paths to a Storage download URL when needed.
  static Future<String> resolveEquipmentImageUrl(
    String equipmentId,
    String imageSource,
  ) async {
    final trimmed = imageSource.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('assets/')) {
      return trimmed;
    }

    Uint8List? bytes;
    if (trimmed.startsWith('data:image/') && trimmed.contains('base64,')) {
      bytes = base64Decode(trimmed.split('base64,').last);
    } else if (!kIsWeb && File(trimmed).existsSync()) {
      bytes = await File(trimmed).readAsBytes();
    }
    if (bytes == null) return trimmed;
    return uploadEquipmentPhoto(equipmentId, bytes);
  }
}

/// Robust image viewer that handles Network URLs, Base64 data URLs, and file paths.
class EquipmentImageViewer extends StatelessWidget {
  final String imageSource;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;

  const EquipmentImageViewer({
    super.key,
    required this.imageSource,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.fallbackIcon = Icons.inventory_2_outlined,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    final trimmed = imageSource.trim();

    if (trimmed.isEmpty) {
      content = _buildPlaceholder();
    } else if (trimmed.startsWith('data:image/') && trimmed.contains('base64,')) {
      try {
        final base64Data = trimmed.split('base64,').last;
        final decodedBytes = base64Decode(base64Data);
        content = Image.memory(
          decodedBytes,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, _, _) => _buildPlaceholder(),
        );
      } catch (_) {
        content = _buildPlaceholder();
      }
    } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      content = Image.network(
        trimmed,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: AppColors.backgroundLight,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            ),
          );
        },
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    } else if (trimmed.startsWith('assets/')) {
      content = Image.asset(
        trimmed,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    } else if (!kIsWeb && File(trimmed).existsSync()) {
      content = Image.file(
        File(trimmed),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    } else {
      content = _buildPlaceholder();
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }

    return content;
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFEAEFF5),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              fallbackIcon,
              color: AppColors.textMutedLight,
              size: (height != null && height! < 100) ? 28 : 42,
            ),
            if (height == null || height! >= 120) ...[
              const SizedBox(height: 6),
              const Text(
                'GearGo Equipment',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
