import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/services/offline_cache_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widget/custom_button.dart';
import '../../../core/widget/offline_banner.dart';
import '../../../core/widget/safe_item_image.dart';
import '../../ai_assistant/services/ai_shopping_assistant_service.dart';
import '../../chat/screens/chat_detail_screen.dart';
import '../../chat/services/chat_service.dart';
import '../services/listings_service.dart';

class ItemDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  bool _isConnecting = false;
  bool _isFav = false;
  late Map<String, dynamic> _item;
  final ListingsService _listingsService = ListingsService();
  final AiShoppingAssistantService _aiService = AiShoppingAssistantService();
  late ItemDealAnalysis _dealAnalysis;

  @override
  void initState() {
    super.initState();
    _item = Map<String, dynamic>.from(widget.item);
    _dealAnalysis = _aiService.analyzeListingDeal(_item);
    _loadFavoriteState();
  }

  void _loadFavoriteState() {
    final id = _item['id']?.toString();
    if (id != null) {
      final isFav = OfflineCacheService.instance.isFavorite(id);
      if (mounted) setState(() => _isFav = isFav);
    }
  }

  void _toggleFav() async {
    final id = _item['id']?.toString();
    if (id != null) {
      final newFav = await OfflineCacheService.instance.toggleFavorite(id);
      if (mounted) setState(() => _isFav = newFav);
    }
  }

  void _messageSeller([String? initialMessage]) async {
    final chatService = ChatService();
    final sellerId = _item['seller_id']?.toString();
    final currentUserId = chatService.currentUser?.id;

    if (sellerId != null && sellerId == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You are the seller of this item.")),
      );
      return;
    }

    setState(() => _isConnecting = true);

    try {
      final room = await chatService.getOrCreateChatRoom(
        listingId: _item['id']?.toString() ?? 'item_unknown',
        sellerId: sellerId ?? '',
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            chatRoomId: room['id']?.toString() ?? '',
            itemTitle: _item['title'] ?? 'Chat',
            listingItem: _item,
            initialDraft: initialMessage,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final appError = AppError.fromException(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appError.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  void _markSold() async {
    final id = _item['id']?.toString();
    if (id == null) return;

    await _listingsService.markListingSold(id);
    setState(() {
      _item['status'] = 'sold';
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Listing marked as SOLD! 🎉"),
          backgroundColor: AppTheme.accentGreen,
        ),
      );
    }
  }

  void _deleteListing() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("Delete Listing?"),
        content: const Text("Are you sure you want to remove this item?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final id = _item['id']?.toString();
    if (id == null) return;

    await _listingsService.deleteListing(id);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _item['title'] ?? 'No Title';
    final price = _item['price'] ?? 0;
    final courseCode = _item['course_code'] ?? 'GENERAL';
    final category = _item['category'] ?? 'General';
    final condition = _item['condition'] ?? 'Good';
    final description = _item['description'] ?? '';
    final sellerName = _item['seller_name'] ?? 'Student';
    final sellerCollege = _item['seller_college'] ?? 'Campus Community';
    final isSold = _item['status'] == 'sold';

    final currentUserId = ChatService().currentUser?.id;
    final isOwner =
        _item['seller_id'] != null && _item['seller_id'] == currentUserId;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text(
          "Item Details",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFav ? Colors.redAccent : AppTheme.textPrimary,
            ),
            tooltip: _isFav ? "Saved" : "Save Item",
            onPressed: _toggleFav,
          ),
          const ConnectionStatusChip(),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 768;

              // Image Section
              final imageWidget = Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: SafeItemImage(
                        imageUrl: _item['image_url']?.toString(),
                        category: category,
                        height: isWide ? 420 : 300,
                        width: double.infinity,
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    if (isSold)
                      Container(
                        height: isWide ? 420 : 300,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            "ITEM SOLD",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );

              // Details Column
              final detailsWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price and Course Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "\$$price",
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryIris,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppTheme.heroGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryIris.withValues(
                                alpha: 0.25,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          courseCode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      height: 1.3,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Metadata Badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildDetailBadge(
                        Icons.category_rounded,
                        category,
                        AppTheme.textSecondary,
                      ),
                      _buildDetailBadge(
                        Icons.verified_rounded,
                        condition,
                        AppTheme.accentGreen,
                      ),
                      _buildDetailBadge(
                        Icons.school_rounded,
                        sellerCollege,
                        AppTheme.primaryIris,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 🤖 CartAI Deal & Safety Evaluator Card
                  _buildAiDealInspector(_dealAnalysis),
                  const SizedBox(height: 18),

                  // Description
                  const Text(
                    "Item Description",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description.isNotEmpty
                        ? description
                        : "Verified genuine campus item in $condition condition. Ready for pickup on campus.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Seller Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.modernCardDecoration(),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppTheme.primaryLight,
                          child: Text(
                            sellerName.isNotEmpty ? sellerName[0] : 'S',
                            style: const TextStyle(
                              color: AppTheme.primaryIris,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sellerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Row(
                                children: [
                                  Icon(
                                    Icons.verified,
                                    size: 14,
                                    color: AppTheme.accentGreen,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "Verified Campus Student",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.accentGreen,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 18,
                                  color: Colors.amber,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  "5.0",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              "12 ratings",
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Campus Verified Safe Trade Hubs
                  _buildSafeTradeZonesCard(),
                  const SizedBox(height: 24),

                  // Action Buttons
                  if (isOwner) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: AppTheme.primaryIris,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "You are the owner of this listing.",
                            style: TextStyle(
                              color: AppTheme.primaryDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        if (!isSold)
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentGreen,
                              ),
                              onPressed: _markSold,
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text("Mark as Sold"),
                            ),
                          ),
                        if (!isSold) const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                            onPressed: _deleteListing,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text("Delete"),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    CustomButton(
                      text: _isConnecting
                          ? "Connecting to Seller..."
                          : "Message Seller 💬",
                      onPressed: _isConnecting ? () {} : () => _messageSeller(),
                    ),
                  ],
                  const SizedBox(height: 36),
                ],
              );

              if (isWide) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: imageWidget),
                      const SizedBox(width: 36),
                      Expanded(flex: 6, child: detailsWidget),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    imageWidget,
                    const SizedBox(height: 20),
                    detailsWidget,
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// AI Deal & Bargaining Inspector Widget
  Widget _buildAiDealInspector(ItemDealAnalysis analysis) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.aiContainerDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: AppTheme.aiGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "CartAI Deal & Safety Evaluator",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppTheme.primaryDark,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.dealGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentGreen.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  analysis.dealScore,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            analysis.summary,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFC7D2FE), height: 1),
          const SizedBox(height: 10),

          // Polite Negotiation Scripts
          const Row(
            children: [
              Icon(
                Icons.handshake_outlined,
                size: 16,
                color: AppTheme.primaryIris,
              ),
              SizedBox(width: 6),
              Text(
                "Polite Bargaining Coach (Tap to send offer directly)",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...analysis.negotiationScripts.map((script) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: InkWell(
                onTap: () => _messageSeller(script),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 14,
                        color: AppTheme.primaryIris,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          script,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: AppTheme.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 10),
          // In-Person Inspection Checklist
          const Row(
            children: [
              Icon(
                Icons.checklist_rounded,
                size: 16,
                color: AppTheme.accentGreen,
              ),
              SizedBox(width: 6),
              Text(
                "In-Person Inspection Checklist",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...analysis.inspectionChecklist.map((check) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "• ",
                    style: TextStyle(
                      color: AppTheme.accentGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      check,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Campus Safe Trade Hubs Card
  Widget _buildSafeTradeZonesCard() {
    final zones = AppConfig.campusSafeTradeZones;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: AppTheme.accentGreen,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                "Verified Campus Safe Trade Hubs",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Color(0xFF166534),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "Avoid strangers and meet at verified campus locations monitored by staff and 24/7 security.",
            style: TextStyle(fontSize: 12, color: Color(0xFF15803D)),
          ),
          const SizedBox(height: 10),
          ...zones.take(2).map((zone) {
            final name = zone['name'] ?? 'Safe Spot';
            final desc = zone['description'] ?? '';
            final badge = zone['safety_level'] ?? 'Monitored';

            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: InkWell(
                onTap: () => _messageSeller(
                  "📍 Can we meet at the $name for this item?",
                ),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDCFCE7)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: AppTheme.accentGreen,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: Color(0xFF14532D),
                              ),
                            ),
                            Text(
                              desc,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF166534),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDetailBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
