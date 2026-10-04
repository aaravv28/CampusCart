import 'package:flutter/material.dart';

import '../../../core/services/offline_cache_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widget/safe_item_image.dart';
import '../../auth/services/auth_service.dart';
import '../../listings/screens/item_detail_screen.dart';
import '../../listings/services/listings_service.dart';
import '../services/ai_shopping_assistant_service.dart';

/// Message model for conversational shopping copilot
class CopilotMessage {
  final String sender; // 'user' or 'ai'
  final String text;
  final List<Map<String, dynamic>> recommendedListings;
  final List<String> followUps;
  final DateTime timestamp;
  final bool isOfflineEngine;

  CopilotMessage({
    required this.sender,
    required this.text,
    this.recommendedListings = const [],
    this.followUps = const [],
    DateTime? timestamp,
    this.isOfflineEngine = false,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AiShoppingCopilotScreen extends StatefulWidget {
  const AiShoppingCopilotScreen({super.key});

  @override
  State<AiShoppingCopilotScreen> createState() =>
      _AiShoppingCopilotScreenState();
}

class _AiShoppingCopilotScreenState extends State<AiShoppingCopilotScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiShoppingAssistantService _aiService = AiShoppingAssistantService();
  final ListingsService _listingsService = ListingsService();
  final AuthService _authService = AuthService();

  final List<CopilotMessage> _messages = [];
  List<Map<String, dynamic>> _availableListings = [];
  bool _isThinking = false;

  final List<String> _quickPrompts = [
    "📚 Textbooks under \$50",
    "🔢 Calculator for MATH150",
    "💻 Laptops & Monitors",
    "🔬 Lab Coat & Goggles",
    "🪑 Dorm Essentials",
    "🔥 Today's Best Deals",
  ];

  @override
  void initState() {
    super.initState();
    _loadListingsAndSeed();
  }

  void _loadListingsAndSeed() async {
    final cached = await OfflineCacheService.instance.getCachedListings();
    if (mounted) {
      setState(() {
        _availableListings = cached;
      });
    }
    _seedWelcomeMessage();

    // Refresh listings from cloud/cache
    try {
      final fresh = await _listingsService.getListings();
      if (mounted && fresh.isNotEmpty) {
        setState(() {
          _availableListings = fresh;
        });
      }
    } catch (_) {}
  }

  void _seedWelcomeMessage() {
    final user = _authService.currentUser;
    final userName = (user?.userMetadata?['full_name'] as String?)?.split(' ').first ?? 'there';

    _messages.add(
      CopilotMessage(
        sender: 'ai',
        text:
            "👋 **Hi $userName! I'm CartAI, your personal campus shopping copilot.**\n\n"
            "Tell me what courses you're taking, what gear you need, or your budget. "
            "I'll instantly scan student listings across your university, find the best prices, and help you save money!\n\n"
            "Tap any quick suggestion below or ask me anything.",
        recommendedListings: _availableListings.take(2).toList(),
        followUps: [
          "Calculators for MATH150",
          "CHEM210 Organic Chemistry book",
          "Dorm study lamp under \$25",
        ],
        isOfflineEngine: true,
      ),
    );
  }

  void _sendMessage([String? quickText]) async {
    final query = (quickText ?? _inputController.text).trim();
    if (query.isEmpty || _isThinking) return;

    if (quickText == null) {
      _inputController.clear();
    }

    setState(() {
      _messages.add(CopilotMessage(sender: 'user', text: query));
      _isThinking = true;
    });

    _scrollToBottom();

    try {
      final response = await _aiService.askAssistant(
        query: query,
        availableListings: _availableListings,
      );

      if (!mounted) return;

      setState(() {
        _isThinking = false;
        _messages.add(
          CopilotMessage(
            sender: 'ai',
            text: response.message,
            recommendedListings: response.recommendedListings,
            followUps: response.suggestedFollowUps,
            isOfflineEngine: response.isOfflineEngine,
          ),
        );
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isThinking = false;
        _messages.add(
          CopilotMessage(
            sender: 'ai',
            text: "⚠️ I ran into a minor hiccup analyzing that query. Here are the top items available right now on campus:",
            recommendedListings: _availableListings.take(2).toList(),
            isOfflineEngine: true,
          ),
        );
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutQuad,
        );
      }
    });
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _seedWelcomeMessage();
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: AppTheme.aiGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryIndigo.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      "CartAI Copilot",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "AI ACTIVE",
                        style: TextStyle(
                          color: AppTheme.accentGreen,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const Text(
                  "Campus Deal Hunter & Course Matcher",
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Reset AI Conversation",
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            children: [
              // 1. Engine Status Banner
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC7D2FE), width: 1),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.offline_bolt_rounded,
                      color: AppTheme.primaryIris,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Offline Ready • Powered by Local Campus Knowledge & Gemini API",
                        style: TextStyle(
                          color: AppTheme.primaryDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Chat Messages List
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: _messages.length + (_isThinking ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isThinking) {
                      return _buildThinkingBubble();
                    }
                    final msg = _messages[index];
                    return _buildMessageItem(msg);
                  },
                ),
              ),

              // 3. Quick Suggestions Chips
              if (_messages.isNotEmpty &&
                  _messages.last.followUps.isNotEmpty &&
                  !_isThinking) ...[
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _messages.last.followUps.length,
                    itemBuilder: (context, i) {
                      final chipText = _messages.last.followUps[i];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ActionChip(
                          avatar: const Icon(
                            Icons.auto_awesome,
                            size: 13,
                            color: AppTheme.primaryIris,
                          ),
                          label: Text(
                            chipText,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryIris,
                            ),
                          ),
                          backgroundColor: Colors.white,
                          side: const BorderSide(
                            color: Color(0xFFC7D2FE),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onPressed: () => _sendMessage(chipText),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ] else ...[
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _quickPrompts.length,
                    itemBuilder: (context, i) {
                      final prompt = _quickPrompts[i];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ActionChip(
                          label: Text(
                            prompt,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          backgroundColor: Colors.white,
                          side: const BorderSide(
                            color: AppTheme.borderLight,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onPressed: () => _sendMessage(prompt),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // 4. Input Bar
              Container(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: AppTheme.borderLight, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.bgLight,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppTheme.borderLight,
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _inputController,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (val) => _sendMessage(),
                          decoration: const InputDecoration(
                            hintText: "Ask CartAI (e.g. Find ME201 book or cheap monitor)...",
                            hintStyle: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            prefixIcon: Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: AppTheme.primaryIndigo,
                              size: 19,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.aiGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryIris.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: _isThinking ? null : () => _sendMessage(),
                      ),
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

  Widget _buildThinkingBubble() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.aiGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.borderLight, width: 1),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryIris,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  "CartAI is evaluating campus listings...",
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(CopilotMessage msg) {
    final isUser = msg.sender == 'user';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: AppTheme.aiGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryIndigo.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 15,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: isUser
                      ? BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.primaryIris,
                              AppTheme.primaryIndigo,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(6),
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryIris.withValues(
                                alpha: 0.25,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        )
                      : BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                          border: Border.all(
                            color: AppTheme.borderLight,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A)
                                  .withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: isUser ? Colors.white : AppTheme.textPrimary,
                      fontWeight: isUser ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),

                // Recommended Product Cards embedded in AI Response
                if (msg.recommendedListings.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...msg.recommendedListings.map(
                    (item) => _buildEmbeddedProductCard(item),
                  ),
                ],
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 15,
                color: AppTheme.primaryIris,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmbeddedProductCard(Map<String, dynamic> item) {
    final title = item['title'] ?? 'Listing Item';
    final price = (item['price'] as num?)?.toDouble() ?? 0.0;
    final condition = item['condition'] ?? 'Good';
    final courseCode = item['course_code'] ?? 'GENERAL';
    final sellerName = item['seller_name'] ?? 'Student Seller';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC7D2FE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryIndigo.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 64,
              height: 64,
              child: SafeItemImage(
                imageUrl: item['image_url']?.toString(),
                category: item['category']?.toString(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        courseCode,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryIris,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.bgLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        condition,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "\$${price.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: AppTheme.accentGreen,
                      ),
                    ),
                    Text(
                      "by $sellerName",
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Action button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: AppTheme.primaryIris,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemDetailScreen(item: item),
                ),
              );
            },
            child: const Text(
              "Inspect",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
