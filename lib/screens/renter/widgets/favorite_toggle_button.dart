import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/gear_item.dart';
import '../../../services/saved_equipment_service.dart';

/// Reusable interactive Heart / Bookmark button with micro-animation.
/// Connects to [SavedEquipmentService] to toggle and persist favorites in real-time.
class FavoriteToggleButton extends StatefulWidget {
  final String equipmentId;
  final String equipmentName;
  final String equipmentCategory;
  final String equipmentImage;
  final double dailyPrice;
  final double rating;
  final int reviewsCount;
  final bool available;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? backgroundColor;
  final VoidCallback? onToggled;

  const FavoriteToggleButton({
    super.key,
    required this.equipmentId,
    required this.equipmentName,
    required this.equipmentCategory,
    required this.equipmentImage,
    required this.dailyPrice,
    this.rating = 4.9,
    this.reviewsCount = 12,
    this.available = true,
    this.size = 22,
    this.activeColor,
    this.inactiveColor,
    this.backgroundColor,
    this.onToggled,
  });

  /// Factory constructor when using [GearItem].
  factory FavoriteToggleButton.fromGearItem(GearItem item, {double size = 22}) {
    final id = 'gear_${item.name.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';
    return FavoriteToggleButton(
      equipmentId: id,
      equipmentName: item.name,
      equipmentCategory: item.category,
      equipmentImage: item.image,
      dailyPrice: item.pricePerDay.toDouble(),
      rating: item.rating,
      reviewsCount: item.reviews,
      available: item.available,
      size: size,
    );
  }

  @override
  State<FavoriteToggleButton> createState() => _FavoriteToggleButtonState();
}

class _FavoriteToggleButtonState extends State<FavoriteToggleButton>
    with SingleTickerProviderStateMixin {
  final _service = SavedEquipmentService();
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isSaved = false;

  String get _currentUserId {
    return FirebaseAuth.instance.currentUser?.uid ?? 'guest_renter';
  }

  @override
  void initState() {
    super.initState();
    _isSaved = _service.isSaved(_currentUserId, widget.equipmentId);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant FavoriteToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.equipmentId != widget.equipmentId) {
      setState(() {
        _isSaved = _service.isSaved(_currentUserId, widget.equipmentId);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleToggle() async {
    _controller.forward(from: 0.0);

    final wasSaved = _isSaved;
    setState(() => _isSaved = !wasSaved);

    final nowSaved = await _service.toggleSaved(
      renterId: _currentUserId,
      equipmentId: widget.equipmentId,
      equipmentName: widget.equipmentName,
      equipmentCategory: widget.equipmentCategory,
      equipmentImage: widget.equipmentImage,
      dailyPrice: widget.dailyPrice,
      rating: widget.rating,
      reviewsCount: widget.reviewsCount,
      available: widget.available,
    );

    if (mounted) {
      setState(() => _isSaved = nowSaved);
      widget.onToggled?.call();

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: nowSaved ? AppColors.deepNavy : const Color(0xFF334155),
          content: Row(
            children: [
              Icon(
                nowSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: nowSaved ? AppColors.error : Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  nowSaved
                      ? 'Saved "${widget.equipmentName}" to Favourites'
                      : 'Removed from Favourites',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCol = widget.activeColor ?? AppColors.error;
    final inactiveCol = widget.inactiveColor ?? const Color(0xFF64748B);

    final button = ScaleTransition(
      scale: _scaleAnimation,
      child: IconButton(
        iconSize: widget.size,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints.tightFor(
          width: widget.size + 16,
          height: widget.size + 16,
        ),
        splashRadius: widget.size,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
          child: Icon(
            _isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            key: ValueKey<bool>(_isSaved),
            color: _isSaved ? activeCol : inactiveCol,
            size: widget.size,
          ),
        ),
        onPressed: _handleToggle,
      ),
    );

    if (widget.backgroundColor != null) {
      return Container(
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: button,
      );
    }

    return button;
  }
}
