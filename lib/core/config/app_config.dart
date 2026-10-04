import 'dart:async';

import 'package:flutter/foundation.dart';

/// Central application configuration controlling Online vs. Offline Demo Mode
/// and holding local mock state for deterministic offline presentations.
class AppConfig {
  static final AppConfig instance = AppConfig._internal();

  AppConfig._internal() {
    _initDemoData();
  }

  // Notifier to broadcast when Demo Mode is toggled or reset
  final ValueNotifier<bool> isDemoModeNotifier = ValueNotifier<bool>(true);

  bool get isDemoMode => isDemoModeNotifier.value;
  set isDemoMode(bool value) {
    if (isDemoModeNotifier.value != value) {
      isDemoModeNotifier.value = value;
    }
  }

  // Current session mock user
  Map<String, dynamic>? _currentUser;
  Map<String, dynamic>? get currentDemoUser => _currentUser;

  // In-memory mock databases for offline presentation
  List<Map<String, dynamic>> _demoColleges = [];
  List<Map<String, dynamic>> _demoListings = [];
  List<Map<String, dynamic>> _demoChatRooms = [];
  List<Map<String, dynamic>> _demoSafeTradeZones = [];
  final Map<String, List<Map<String, dynamic>>> _demoMessages = {};
  final Set<String> _favoriteListingIds = {'list_1', 'list_5'};

  // Stream controllers for real-time offline messages
  final Map<String, StreamController<List<Map<String, dynamic>>>>
  _roomStreamControllers = {};

  List<Map<String, dynamic>> get demoColleges =>
      List.unmodifiable(_demoColleges);
  List<Map<String, dynamic>> get demoListings =>
      List.unmodifiable(_demoListings);
  List<Map<String, dynamic>> get demoChatRooms =>
      List.unmodifiable(_demoChatRooms);
  List<Map<String, dynamic>> get demoSafeTradeZones =>
      List.unmodifiable(_demoSafeTradeZones);

  bool isFavorite(String listingId) => _favoriteListingIds.contains(listingId);

  void toggleFavorite(String listingId) {
    if (_favoriteListingIds.contains(listingId)) {
      _favoriteListingIds.remove(listingId);
    } else {
      _favoriteListingIds.add(listingId);
    }
  }

  void _initDemoData() {
    _currentUser = {
      'id': 'demo_user_123',
      'email': 'alex.johnson@ddu.ac.in',
      'full_name': 'Alex Johnson',
      'department': 'Computer Engineering',
      'graduation_year': '2027',
      'contact_preference': 'In-App Messaging',
      'college_id': 'col_1',
      'colleges': {
        'id': 'col_1',
        'name': 'Dharmsinh Desai University',
        'domain': 'ddu.ac.in',
      },
    };

    _demoColleges = [
      {
        'id': 'col_1',
        'name': 'Dharmsinh Desai University',
        'domain': 'ddu.ac.in',
      },
      {'id': 'col_2', 'name': 'Nirma University', 'domain': 'nirmauni.ac.in'},
      {'id': 'col_3', 'name': 'IIT Bombay', 'domain': 'iitb.ac.in'},
      {
        'id': 'col_4',
        'name': 'BITS Pilani',
        'domain': 'pilani.bits-pilani.ac.in',
      },
      {'id': 'col_5', 'name': 'Stanford University', 'domain': 'stanford.edu'},
    ];

    _demoSafeTradeZones = [
      {
        'id': 'zone_1',
        'name': 'University Library Entrance',
        'description': 'Main ground floor lobby, monitored by 24/7 security desk and CCTV cameras.',
        'safety_level': 'High Security',
        'recommended_hours': '8:00 AM – 9:00 PM',
      },
      {
        'id': 'zone_2',
        'name': 'Student Center & Cafeteria',
        'description':
            'Open central dining area with high student traffic and seating.',
        'safety_level': 'Public Gathering Zone',
        'recommended_hours': '9:00 AM – 8:00 PM',
      },
      {
        'id': 'zone_3',
        'name': 'Campus Security Main Gate Post',
        'description':
            'Directly outside the campus security dispatch post with parking.',
        'safety_level': 'Officer On Duty',
        'recommended_hours': '24/7 Monitored',
      },
      {
        'id': 'zone_4',
        'name': 'Engineering Quad Building Foyer',
        'description': 'Spacious academic building hall with public benches and charging points.',
        'safety_level': 'Academic Building',
        'recommended_hours': '8:30 AM – 6:30 PM',
      },
    ];

    _demoListings = [
      {
        'id': 'list_1',
        'title': 'Organic Chemistry 8th Ed - Wade',
        'price': 45.0,
        'course_code': 'CHEM210',
        'category': 'Textbooks',
        'condition': 'Like New',
        'image_url': 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=600&auto=format&fit=crop&q=80',
        'description': 'Hardcover edition in pristine condition. No highlighted text or pen notes inside. Used for one semester in CHEM210. Must-have for exams!',
        'seller_id': 'seller_101',
        'seller_name': 'Sarah Miller',
        'seller_college': 'Dharmsinh Desai University',
        'college_id': 'col_1',
        'status': 'available',
        'created_at': DateTime.now()
            .subtract(const Duration(hours: 2))
            .toIso8601String(),
      },
      {
        'id': 'list_2',
        'title': 'TI-84 Plus CE Graphing Calculator',
        'price': 75.0,
        'course_code': 'MATH150',
        'category': 'Electronics',
        'condition': 'Good',
        'image_url': 'https://images.unsplash.com/photo-1587145820266-a5951ee6f620?w=600&auto=format&fit=crop&q=80',
        'description': 'Fully functional color graphing calculator. Battery holds charge for weeks. Includes original USB charging cable and black slide cover.',
        'seller_id': 'seller_102',
        'seller_name': 'David Chen',
        'seller_college': 'Dharmsinh Desai University',
        'college_id': 'col_1',
        'status': 'available',
        'created_at': DateTime.now()
            .subtract(const Duration(hours: 5))
            .toIso8601String(),
      },
      {
        'id': 'list_3',
        'title': 'Engineering Mechanics: Statics - Hibbeler',
        'price': 50.0,
        'course_code': 'ME201',
        'category': 'Textbooks',
        'condition': 'Good',
        'image_url': 'https://images.unsplash.com/photo-1532012164546-f432f2e3777f?w=600&auto=format&fit=crop&q=80',
        'description': 'Standard textbook for sophomore engineering statics course ME201. Cover has light edge wear, all practice problem sets intact.',
        'seller_id': 'demo_user_123', // User's own listing
        'seller_name': 'Alex Johnson',
        'seller_college': 'Dharmsinh Desai University',
        'college_id': 'col_1',
        'status': 'available',
        'created_at': DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
      },
      {
        'id': 'list_4',
        'title': 'Lab Coat & Safety Goggles (M)',
        'price': 25.0,
        'course_code': 'CHEM101',
        'category': 'Lab Gear',
        'condition': 'New',
        'image_url': 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=600&auto=format&fit=crop&q=80',
        'description': 'Unused white cotton unisex lab coat (Size Medium) with splash-resistant safety goggles. Meets all university chemistry department requirements.',
        'seller_id': 'seller_103',
        'seller_name': 'Priya Patel',
        'seller_college': 'Dharmsinh Desai University',
        'college_id': 'col_1',
        'status': 'available',
        'created_at': DateTime.now()
            .subtract(const Duration(days: 1, hours: 3))
            .toIso8601String(),
      },
      {
        'id': 'list_5',
        'title': 'Dell 24" IPS 1080p Monitor w/ HDMI',
        'price': 85.0,
        'course_code': 'CS101',
        'category': 'Electronics',
        'condition': 'Like New',
        'image_url': 'https://images.unsplash.com/photo-1527443224154-c4a3942d3acf?w=600&auto=format&fit=crop&q=80',
        'description': 'Great secondary screen for coding and studying in dorm. Crisp 1080p IPS panel, thin bezels, includes HDMI and power brick.',
        'seller_id': 'seller_101',
        'seller_name': 'Sarah Miller',
        'seller_college': 'Dharmsinh Desai University',
        'college_id': 'col_1',
        'status': 'available',
        'created_at': DateTime.now()
            .subtract(const Duration(days: 2))
            .toIso8601String(),
      },
      {
        'id': 'list_6',
        'title': 'Desk Study Lamp with USB Port',
        'price': 18.0,
        'course_code': 'DORM',
        'category': 'Dorm & Furniture',
        'condition': 'Good',
        'image_url': 'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=600&auto=format&fit=crop&q=80',
        'description': 'Dimmable LED desk lamp with 3 color temperature modes and integrated 5V USB output for charging your phone while studying.',
        'seller_id': 'seller_104',
        'seller_name': 'Ethan Wright',
        'seller_college': 'Dharmsinh Desai University',
        'college_id': 'col_1',
        'status': 'available',
        'created_at': DateTime.now()
            .subtract(const Duration(days: 2, hours: 8))
            .toIso8601String(),
      },
      {
        'id': 'list_7',
        'title': 'Digital Multimeter & Breadboard Kit',
        'price': 30.0,
        'course_code': 'EE204',
        'category': 'Electronics',
        'condition': 'Like New',
        'image_url': 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=600&auto=format&fit=crop&q=80',
        'description': 'Includes auto-ranging digital multimeter with test leads, 830-point solderless breadboard, and assortment of jumper wires.',
        'seller_id': 'seller_102',
        'seller_name': 'David Chen',
        'seller_college': 'Dharmsinh Desai University',
        'college_id': 'col_1',
        'status': 'available',
        'created_at': DateTime.now()
            .subtract(const Duration(days: 3))
            .toIso8601String(),
      },
      {
        'id': 'list_8',
        'title': 'Introduction to Algorithms (CLRS)',
        'price': 55.0,
        'course_code': 'CS204',
        'category': 'Textbooks',
        'condition': 'Fair',
        'image_url': 'https://images.unsplash.com/photo-1516979187457-637abb4f9353?w=600&auto=format&fit=crop&q=80',
        'description': 'Classic algorithms bible (3rd Edition). Binding is sturdy, mild highlighting in chapter 4 (Divide and Conquer). Very readable.',
        'seller_id': 'seller_103',
        'seller_name': 'Priya Patel',
        'seller_college': 'Dharmsinh Desai University',
        'college_id': 'col_1',
        'status': 'available',
        'created_at': DateTime.now()
            .subtract(const Duration(days: 4))
            .toIso8601String(),
      },
    ];

    _demoChatRooms = [
      {
        'id': 'room_1',
        'listing_id': 'list_1',
        'buyer_id': 'demo_user_123',
        'seller_id': 'seller_101',
        'college_id': 'col_1',
        'created_at': DateTime.now()
            .subtract(const Duration(hours: 1))
            .toIso8601String(),
        'listings': {
          'title': 'Organic Chemistry 8th Ed - Wade',
          'image_url': 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=600&auto=format&fit=crop&q=80',
          'price': 45.0,
        },
      },
      {
        'id': 'room_2',
        'listing_id': 'list_2',
        'buyer_id': 'demo_user_123',
        'seller_id': 'seller_102',
        'college_id': 'col_1',
        'created_at': DateTime.now()
            .subtract(const Duration(hours: 3))
            .toIso8601String(),
        'listings': {
          'title': 'TI-84 Plus CE Graphing Calculator',
          'image_url': 'https://images.unsplash.com/photo-1587145820266-a5951ee6f620?w=600&auto=format&fit=crop&q=80',
          'price': 75.0,
        },
      },
    ];

    _demoMessages.clear();
    _demoMessages['room_1'] = [
      {
        'id': 'msg_1',
        'chat_room_id': 'room_1',
        'sender_id': 'demo_user_123',
        'content':
            'Hi Sarah! Is the Organic Chemistry textbook still available?',
        'created_at': DateTime.now()
            .subtract(const Duration(minutes: 50))
            .toIso8601String(),
      },
      {
        'id': 'msg_2',
        'chat_room_id': 'room_1',
        'sender_id': 'seller_101',
        'content': 'Hey Alex! Yes it is. Barely used, no highlighting inside.',
        'created_at': DateTime.now()
            .subtract(const Duration(minutes: 42))
            .toIso8601String(),
      },
      {
        'id': 'msg_3',
        'chat_room_id': 'room_1',
        'sender_id': 'demo_user_123',
        'content':
            'Awesome! Can we meet at the campus library tomorrow around 2 PM?',
        'created_at': DateTime.now()
            .subtract(const Duration(minutes: 30))
            .toIso8601String(),
      },
      {
        'id': 'msg_4',
        'chat_room_id': 'room_1',
        'sender_id': 'seller_101',
        'content': 'Sure, let\'s meet near the 1st floor cafe!',
        'created_at': DateTime.now()
            .subtract(const Duration(minutes: 25))
            .toIso8601String(),
      },
    ];

    _demoMessages['room_2'] = [
      {
        'id': 'msg_21',
        'chat_room_id': 'room_2',
        'sender_id': 'demo_user_123',
        'content':
            'Hi David, does the calculator include the USB charging cable?',
        'created_at': DateTime.now()
            .subtract(const Duration(hours: 2, minutes: 30))
            .toIso8601String(),
      },
      {
        'id': 'msg_22',
        'chat_room_id': 'room_2',
        'sender_id': 'seller_102',
        'content':
            'Yes! Cable and slide cover are included. Holds charge perfectly.',
        'created_at': DateTime.now()
            .subtract(const Duration(hours: 2, minutes: 15))
            .toIso8601String(),
      },
    ];

    // Push updates to any active stream controllers
    for (final entry in _demoMessages.entries) {
      if (_roomStreamControllers.containsKey(entry.key)) {
        _roomStreamControllers[entry.key]!.add(
          List<Map<String, dynamic>>.from(entry.value),
        );
      }
    }
  }

  /// Reset demo data back to clean factory state
  void resetDemoData() {
    _initDemoData();
    isDemoMode = true;
  }

  // --- Local Demo Operations ---

  void addDemoCollege(Map<String, dynamic> college) {
    _demoColleges.add(college);
  }

  void addDemoListing(Map<String, dynamic> listing) {
    _demoListings.insert(0, listing);
  }

  void deleteDemoListing(String listingId) {
    _demoListings.removeWhere((l) => l['id'] == listingId);
  }

  void markDemoListingSold(String listingId) {
    final index = _demoListings.indexWhere((l) => l['id'] == listingId);
    if (index != -1) {
      final updated = Map<String, dynamic>.from(_demoListings[index]);
      updated['status'] = 'sold';
      _demoListings[index] = updated;
    }
  }

  void updateDemoProfile({
    String? name,
    String? department,
    String? graduationYear,
    String? contactPreference,
  }) {
    if (_currentUser != null) {
      if (name != null) {
        _currentUser!['full_name'] = name;
      }
      if (department != null) {
        _currentUser!['department'] = department;
      }
      if (graduationYear != null) {
        _currentUser!['graduation_year'] = graduationYear;
      }
      if (contactPreference != null) {
        _currentUser!['contact_preference'] = contactPreference;
      }
    }
  }

  void updateDemoUserPassword(String newPassword) {
    if (_currentUser != null) {
      _currentUser!['password'] = newPassword;
    }
  }

  Map<String, dynamic> getOrCreateDemoChatRoom({
    required String listingId,
    required String sellerId,
  }) {
    // Check existing
    final existing = _demoChatRooms.firstWhere(
      (r) =>
          r['listing_id'] == listingId && r['buyer_id'] == _currentUser?['id'],
      orElse: () => {},
    );

    if (existing.isNotEmpty) {
      return existing;
    }

    final listing = _demoListings.firstWhere(
      (l) => l['id'] == listingId,
      orElse: () => {'title': 'Listing', 'price': 0},
    );

    final newRoom = {
      'id': 'room_${DateTime.now().millisecondsSinceEpoch}',
      'listing_id': listingId,
      'buyer_id': _currentUser?['id'] ?? 'demo_user_123',
      'seller_id': sellerId,
      'college_id': _currentUser?['college_id'] ?? 'col_1',
      'created_at': DateTime.now().toIso8601String(),
      'listings': {
        'title': listing['title'] ?? 'Listing',
        'image_url': listing['image_url'],
        'price': listing['price'] ?? 0,
      },
    };

    _demoChatRooms.insert(0, newRoom);
    _demoMessages[newRoom['id']] = [];
    return newRoom;
  }

  Stream<List<Map<String, dynamic>>> getDemoMessagesStream(String chatRoomId) {
    if (!_roomStreamControllers.containsKey(chatRoomId) ||
        _roomStreamControllers[chatRoomId]!.isClosed) {
      _roomStreamControllers[chatRoomId] =
          StreamController<List<Map<String, dynamic>>>.broadcast();
    }

    final controller = _roomStreamControllers[chatRoomId]!;
    // Emit current list asynchronously
    final messages = _demoMessages[chatRoomId] ?? [];
    Future.microtask(() {
      if (!controller.isClosed) {
        controller.add(List<Map<String, dynamic>>.from(messages));
      }
    });

    return controller.stream;
  }

  void sendDemoMessage({required String chatRoomId, required String content}) {
    final list = _demoMessages.putIfAbsent(chatRoomId, () => []);
    final newMsg = {
      'id': 'msg_${DateTime.now().millisecondsSinceEpoch}',
      'chat_room_id': chatRoomId,
      'sender_id': _currentUser?['id'] ?? 'demo_user_123',
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    };
    list.add(newMsg);

    if (_roomStreamControllers.containsKey(chatRoomId) &&
        !_roomStreamControllers[chatRoomId]!.isClosed) {
      _roomStreamControllers[chatRoomId]!.add(
        List<Map<String, dynamic>>.from(list),
      );
    }
  }

  void loginDemoUser([String? email]) {
    isDemoMode = true;
    final cleanEmail = email?.trim().toLowerCase();
    final isAlex =
        cleanEmail == null ||
        cleanEmail.isEmpty ||
        cleanEmail == 'alex.johnson@ddu.ac.in';

    if (_currentUser == null) {
      if (_demoListings.isEmpty) {
        _initDemoData();
      }

      if (isAlex) {
        _currentUser = {
          'id': 'demo_user_123',
          'email': 'alex.johnson@ddu.ac.in',
          'full_name': 'Alex Johnson',
          'department': 'Computer Engineering',
          'graduation_year': '2027',
          'contact_preference': 'In-App Messaging',
          'college_id': 'col_1',
          'colleges': {
            'id': 'col_1',
            'name': 'Dharmsinh Desai University',
            'domain': 'ddu.ac.in',
          },
        };
      } else {
        final userName = cleanEmail.split('@').first.replaceAll('.', ' ');
        final capitalized = userName
            .split(' ')
            .map(
              (w) =>
                  w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
            )
            .join(' ');
        _currentUser = {
          'id': 'demo_user_${cleanEmail.hashCode.abs()}',
          'email': cleanEmail,
          'full_name': capitalized.isNotEmpty ? capitalized : 'Campus Student',
          'department': 'Engineering',
          'graduation_year': '2026',
          'contact_preference': 'In-App Messaging',
          'college_id': 'col_1',
          'colleges': {
            'id': 'col_1',
            'name': 'Dharmsinh Desai University',
            'domain': 'ddu.ac.in',
          },
        };
      }
    } else {
      if (cleanEmail != null && cleanEmail.isNotEmpty) {
        _currentUser!['email'] = cleanEmail;
      }
    }
  }

  void logoutDemoUser() {
    _currentUser = null;
    isDemoMode = false;
  }
}
