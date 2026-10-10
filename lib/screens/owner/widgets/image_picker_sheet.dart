import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/image_helper.dart';

/// Modal bottom sheet allowing equipment owners to pick or supply an equipment image.
class ImagePickerSheet extends StatelessWidget {
  final ValueChanged<String> onImageSelected;

  const ImagePickerSheet({
    super.key,
    required this.onImageSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<String> onImageSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ImagePickerSheet(onImageSelected: onImageSelected),
    );
  }

  void _showUrlInputDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Image URL',
          style: TextStyle(
            color: AppColors.deepNavy,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste a direct public link to your equipment photo:',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: 'https://example.com/gear.jpg',
                prefixIcon: const Icon(Icons.link_rounded, color: AppColors.blue),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () => controller.clear(),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.blue),
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                onImageSelected(url);
                Navigator.of(dialogCtx).pop();
                Navigator.of(context).pop();
              }
            },
            child: const Text('Use Image'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const Text(
                'Upload Equipment Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepNavy,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'High-quality gear photos receive up to 3x more rental inquiries.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 18),

              // Upload options row
              Row(
                children: [
                  Expanded(
                    child: _UploadOptionCard(
                      icon: Icons.camera_alt_rounded,
                      title: 'Camera',
                      subtitle: 'Snap new',
                      color: AppColors.blue,
                      onTap: () async {
                        final result = await ImageHelper.pickFromCamera();
                        if (result != null) {
                          onImageSelected(result);
                          if (context.mounted) Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _UploadOptionCard(
                      icon: Icons.photo_library_rounded,
                      title: 'Gallery',
                      subtitle: 'Upload photo',
                      color: AppColors.orange,
                      onTap: () async {
                        final result = await ImageHelper.pickFromGallery();
                        if (result != null) {
                          onImageSelected(result);
                          if (context.mounted) Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _UploadOptionCard(
                      icon: Icons.link_rounded,
                      title: 'URL Link',
                      subtitle: 'Direct link',
                      color: const Color(0xFF6366F1),
                      onTap: () => _showUrlInputDialog(context),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Gear Presets Section
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.orange,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Or Pick a Curated Gear Preset',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.deepNavy,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${GearImagePreset.presets.length} Presets',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: GearImagePreset.presets.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final preset = GearImagePreset.presets[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        onImageSelected(preset.imageUrl);
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: 110,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: EquipmentImageViewer(
                                imageSource: preset.imageUrl,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(11),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 6,
                              ),
                              decoration: const BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(11),
                                ),
                              ),
                              child: Text(
                                preset.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.deepNavy,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _UploadOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.deepNavy,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
