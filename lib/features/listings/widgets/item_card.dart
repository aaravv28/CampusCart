import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widget/safe_item_image.dart';

class ItemCard extends StatefulWidget {
  final String title;
  final String price;
  final String courseCode;
  final String condition;
  final String? imageUrl;
  final String? sellerName;
  final String? id;
  final String? status;
  final VoidCallback? onTap;

  const ItemCard({
    super.key,
    required this.title,
    required this.price,
    required this.courseCode,
    required this.condition,
    this.imageUrl,
    this.sellerName,
    this.id,
    this.status,
    this.onTap,
  });

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  late bool _isFav;

  @override
  void initState() {
    super.initState();
    _isFav = widget.id != null && AppConfig.instance.isFavorite(widget.id!);
  }

  void _toggleFav() {
    if (widget.id != null) {
      setState(() {
        _isFav = !_isFav;
      });
      AppConfig.instance.toggleFavorite(widget.id!);
    }
  }

  Color _getConditionColor(String cond) {
    switch (cond.toLowerCase()) {
      case 'new':
        return AppTheme.accentGreen;
      case 'like new':
        return AppTheme.primaryIris;
      case 'good':
        return AppTheme.accentCyan;
      case 'fair':
      default:
        return AppTheme.accentAmber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final conditionColor = _getConditionColor(widget.condition);
    final isSold = widget.status == 'sold';

    return Container(
      decoration: AppTheme.modernCardDecoration(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          mouseCursor: SystemMouseCursors.click,
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Image Header with Floating Badges
              Expanded(
                flex: 11,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SafeItemImage(
                      imageUrl: widget.imageUrl,
                      fit: BoxFit.cover,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(17),
                      ),
                    ),

                    // Condition Badge (Top Left)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: conditionColor.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.condition,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),

                    // Favorite Button (Top Right)
                    if (widget.id != null)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: _toggleFav,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isFav
                                    ? Icons.favorite
                                    : Icons.favorite_border_rounded,
                                size: 16,
                                color: _isFav
                                    ? Colors.redAccent
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Sold Banner Overlay
                    if (isSold)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(17),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "SOLD",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 2. Card Content Section
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Course Code & Price Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            widget.courseCode,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryIris,
                            ),
                          ),
                        ),
                        Text(
                          "\$${widget.price}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryIris,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Item Title
                    Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Seller snippet
                    if (widget.sellerName != null &&
                        widget.sellerName!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 13,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.sellerName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
