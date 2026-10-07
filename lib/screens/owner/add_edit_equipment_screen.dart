import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/image_helper.dart';
import '../../models/equipment.dart';
import '../../services/equipment_service.dart';
import 'widgets/category_selector.dart';
import 'widgets/image_picker_sheet.dart';

/// Form screen for creating or editing equipment listings.
class AddEditEquipmentScreen extends StatefulWidget {
  final String ownerId;
  final Equipment? equipment; // null = Create Mode, non-null = Edit Mode

  const AddEditEquipmentScreen({
    super.key,
    required this.ownerId,
    this.equipment,
  });

  @override
  State<AddEditEquipmentScreen> createState() => _AddEditEquipmentScreenState();
}

class _AddEditEquipmentScreenState extends State<AddEditEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = EquipmentService();

  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;

  late String _selectedCategoryId;
  late bool _availability;
  late String _imageUrl;
  late String _condition;

  bool _isSaving = false;

  bool get _isEditing => widget.equipment != null;

  @override
  void initState() {
    super.initState();
    final item = widget.equipment;
    _nameController = TextEditingController(text: item?.name ?? '');
    _priceController = TextEditingController(
      text: item != null ? item.price.toStringAsFixed(0) : '',
    );
    _descriptionController =
        TextEditingController(text: item?.description ?? '');
    _locationController =
        TextEditingController(text: item?.location ?? 'Denver, CO');

    _selectedCategoryId = item?.categoryId ?? 'mountain_bikes';
    _availability = item?.availability ?? true;
    _imageUrl = item?.image ?? '';
    _condition = item?.condition ?? 'Excellent';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid price greater than \$0.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final equipmentToSave = Equipment(
        id: widget.equipment?.id ?? '',
        ownerId: widget.ownerId,
        name: _nameController.text.trim(),
        categoryId: _selectedCategoryId,
        description: _descriptionController.text.trim(),
        price: price,
        availability: _availability,
        image: _imageUrl.trim(),
        createdAt: widget.equipment?.createdAt ?? now,
        updatedAt: now,
        condition: _condition,
        location: _locationController.text.trim(),
        rating: widget.equipment?.rating ?? 5.0,
        reviewsCount: widget.equipment?.reviewsCount ?? 0,
      );

      Equipment result;
      if (_isEditing) {
        result = await _service.updateEquipment(equipmentToSave);
      } else {
        result = await _service.createEquipment(equipmentToSave);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Listing updated successfully!'
                  : 'New equipment listed successfully!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving listing: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _openImagePicker() {
    ImagePickerSheet.show(
      context,
      onImageSelected: (newImage) {
        setState(() {
          _imageUrl = newImage;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Listing' : 'Add New Equipment',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.deepNavy,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _handleSave,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blue,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Upload Hero Box
                _buildImageUploadBox(),
                const SizedBox(height: 20),

                // Equipment Name Field
                _buildTextField(
                  controller: _nameController,
                  label: 'Equipment Name *',
                  hint: 'e.g. Trek Fuel EX 8 Gen 6 Mountain Bike',
                  prefixIcon: Icons.directions_bike_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please provide equipment name';
                    }
                    if (value.trim().length < 3) {
                      return 'Name must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category Selector
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: CategorySelector(
                    selectedCategoryId: _selectedCategoryId,
                    onCategoryChanged: (catId) {
                      setState(() => _selectedCategoryId = catId);
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Price and Availability Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price Field
                    Expanded(
                      flex: 5,
                      child: _buildTextField(
                        controller: _priceController,
                        label: 'Price per day (\$USD) *',
                        hint: '45',
                        prefixText: '\$ ',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter daily price';
                          }
                          final parsed = double.tryParse(value.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Invalid price';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Condition Dropdown
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Condition',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.deepNavy,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _condition,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Brand New',
                                    child: Text('Brand New'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Like New',
                                    child: Text('Like New'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Excellent',
                                    child: Text('Excellent'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Good',
                                    child: Text('Good'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Fair',
                                    child: Text('Fair'),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _condition = val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description Field
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description *',
                  hint:
                      'Describe your gear condition, included accessories, sizing, rules, or pickup details...',
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please provide a description of the equipment';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Location Field
                _buildTextField(
                  controller: _locationController,
                  label: 'Pickup Location',
                  hint: 'e.g. Denver, CO (Capitol Hill)',
                  prefixIcon: Icons.location_on_rounded,
                ),
                const SizedBox(height: 16),

                // Set Availability Switch Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _availability
                              ? AppColors.success.withValues(alpha: 0.12)
                              : AppColors.textMutedLight.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _availability
                              ? Icons.check_circle_outline_rounded
                              : Icons.pause_circle_outline_rounded,
                          color: _availability
                              ? AppColors.success
                              : AppColors.textSecondaryLight,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _availability
                                  ? 'Listing is Available'
                                  : 'Listing is Paused / Hidden',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepNavy,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _availability
                                  ? 'Active and discoverable for rental bookings.'
                                  : 'Renters cannot see or request this gear.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _availability,
                        activeThumbColor: AppColors.success,
                        onChanged: (val) {
                          setState(() => _availability = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Primary Save Button (Orange CTA matching GearGo brand guide)
                FilledButton.icon(
                  onPressed: _isSaving ? null : _handleSave,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    _isSaving
                        ? 'Saving...'
                        : (_isEditing ? 'Save Changes' : 'Publish Equipment'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 1,
                  ),
                ),
                const SizedBox(height: 12),

                // Cancel Button
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: AppColors.borderLight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadBox() {
    final hasImage = _imageUrl.trim().isNotEmpty;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            EquipmentImageViewer(
              imageSource: _imageUrl,
              borderRadius: BorderRadius.circular(17),
            )
          else
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _openImagePicker,
                borderRadius: BorderRadius.circular(18),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.blue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_a_photo_rounded,
                          color: AppColors.blue,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Upload Equipment Image',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap to choose Camera, Gallery, URL, or Presets',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Overlay Buttons when image exists
          if (hasImage)
            Positioned(
              right: 12,
              bottom: 12,
              child: Row(
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black87,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _openImagePicker,
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Change Photo'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                    ),
                    tooltip: 'Remove photo',
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    onPressed: () {
                      setState(() => _imageUrl = '');
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? prefixIcon,
    String? prefixText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.deepNavy,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
            prefixText: prefixText,
            prefixStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.deepNavy,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
