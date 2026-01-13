import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/images_picker_grid.dart';
import 'package:daad_app/core/utils/notification_utils/notification_utils.dart';
import 'package:daad_app/core/utils/services/deep_link_handler.dart';
import 'package:daad_app/core/utils/helpers/debouncer.dart';

import 'package:daad_app/features/contact/voice_message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard/Haptic
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:flutter_linkify/flutter_linkify.dart'; // Clickable Links
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:record/record.dart'; // Voice Recording
import 'package:url_launcher/url_launcher.dart';

// ============================================
// 1. SUPPORT CHATS TAB (LIST OF CHATS)
// ============================================

class SupportChatsTab extends StatefulWidget {
  const SupportChatsTab({super.key});

  @override
  State<SupportChatsTab> createState() => _SupportChatsTabState();
}

class _SupportChatsTabState extends State<SupportChatsTab> {
  static const int _pageSize = 10;
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final List<DocumentSnapshot> _chats = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _currentUserId;
  String? _currentUserRole;
  List<String> _assignedUserIds =
      []; // Stores the array from your user document
  final Debouncer _searchDebouncer = Debouncer(
    milliseconds: 300,
  ); // Debounce search

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Get the current Sales/Admin user document
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!mounted) return;

    setState(() {
      _currentUserId = user.uid;
      _currentUserRole = userDoc.data()?['role'] ?? 'client';

      // 2. STRICTLY USE 'assignedUsers' ARRAY FOR SALES
      if (_currentUserRole == 'sales') {
        final rawList = userDoc.data()?['assignedUsers'];
        if (rawList is List) {
          _assignedUserIds = List<String>.from(rawList);
        }
      }
    });

    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebouncer.dispose(); // Dispose debouncer
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      if (!_isLoadingMore && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() {
      _chats.clear();
      _lastDocument = null;
      _hasMore = true;
    });

    // --- SALES LOGIC (Using assignedUsers array) ---
    if (_currentUserRole == 'sales') {
      if (_assignedUserIds.isEmpty) {
        if (!mounted) return;
        setState(() => _hasMore = false);
        return; // No users assigned
      }

      // Firestore 'whereIn' is limited to 10 items.
      // We must split the array into chunks of 10.
      const int batchSize = 10;
      List<DocumentSnapshot> allChats = [];

      for (int i = 0; i < _assignedUserIds.length; i += batchSize) {
        final end = (i + batchSize < _assignedUserIds.length)
            ? i + batchSize
            : _assignedUserIds.length;
        final batch = _assignedUserIds.sublist(i, end);

        // Find chats where the chat's 'userId' matches one of the assigned users
        final snapshot = await FirebaseFirestore.instance
            .collection('support_chats')
            .where('userId', whereIn: batch)
            .get();

        allChats.addAll(snapshot.docs);
      }

      // Sort combined results by time
      allChats.sort((a, b) {
        final aTime =
            (a.data() as Map<String, dynamic>)['lastMessageAt'] as Timestamp?;
        final bTime =
            (b.data() as Map<String, dynamic>)['lastMessageAt'] as Timestamp?;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      if (mounted) {
        setState(() {
          _chats.addAll(allChats);
          _lastDocument = null; // No pagination needed for batch loading
          _hasMore = false;
        });
      }
    }
    // --- ADMIN LOGIC (Show All) ---
    else {
      Query query = FirebaseFirestore.instance
          .collection('support_chats')
          .orderBy('lastMessageAt', descending: true);

      final snapshot = await query.limit(_pageSize).get();

      if (mounted) {
        setState(() {
          _chats.addAll(snapshot.docs);
          _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
          _hasMore = snapshot.docs.length == _pageSize;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_lastDocument == null || !_hasMore || _isLoadingMore) return;
    if (_currentUserRole == 'sales') return; // Sales loads all at once

    if (!mounted) return;
    setState(() => _isLoadingMore = true);

    try {
      Query query = FirebaseFirestore.instance
          .collection('support_chats')
          .orderBy('lastMessageAt', descending: true);

      final snapshot = await query
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize)
          .get();

      if (mounted) {
        setState(() {
          _chats.addAll(snapshot.docs);
          _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
          _hasMore = snapshot.docs.length == _pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  List<DocumentSnapshot> _getFilteredChats() {
    if (_searchQuery.isEmpty) return _chats;
    return _chats.where((chat) {
      final data = chat.data() as Map<String, dynamic>;
      final userName = (data['userName'] ?? '').toString().toLowerCase();
      final userPhone = (data['userPhone'] ?? '').toString().toLowerCase();
      final userEmail = (data['userEmail'] ?? '').toString().toLowerCase();
      return userName.contains(_searchQuery) ||
          userPhone.contains(_searchQuery) ||
          userEmail.contains(_searchQuery);
    }).toList();
  }

  Future<void> _assignToSales(String chatId, String userId) async {
    final salesUsers = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'sales')
        .get();
    if (!mounted) return;

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryColor.withOpacity(0.95),
        title: const AppText(title: 'اختر دعم فني'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: salesUsers.docs.length,
            itemBuilder: (context, index) {
              final sales = salesUsers.docs[index];
              final data = sales.data();
              return ListTile(
                title: AppText(title: data['name'] ?? 'مندوب مبيعات'),
                subtitle: AppText(
                  title: data['email'] ?? '',
                  fontSize: 12,
                  color: Colors.white70,
                ),
                onTap: () => Navigator.pop(context, sales.id),
              );
            },
          ),
        ),
      ),
    );

    if (selected != null) {
      // Add user to Sales Agent's assignedUsers array
      await FirebaseFirestore.instance.collection('users').doc(selected).update(
        {
          'assignedUsers': FieldValue.arrayUnion([userId]),
        },
      );

      // Update Chat info (Optional but good for tracking)
      await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(chatId)
          .update({
            'assignedSalesId': selected,
            'unreadBySales': FieldValue.increment(1),
          });

      await NotificationService.sendNotification(
        title: '👤 تم تعيين عميل جديد لك',
        body: 'لديك محادثة دعم جديدة',
        userId: selected,
        deepLink: DeepLinkHandler.supportLink(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: AppText(title: 'تم التعيين بنجاح')),
        );
        _loadInitialData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredChats = _getFilteredChats();
    final isAdmin = _currentUserRole == 'admin';
    final isSales = _currentUserRole == 'sales';

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12.r),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'بحث عن مستخدم...',
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(Icons.search, color: Colors.white60),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white60),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.secondaryColor.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
              ),
              // Use debouncer to prevent excessive rebuilds
              onChanged: (value) {
                _searchDebouncer.run(() {
                  if (mounted) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  }
                });
              },
            ),
          ),
          Expanded(
            child: _chats.isEmpty && !_isLoadingMore
                ? const Center(child: CircularProgressIndicator())
                : filteredChats.isEmpty
                ? const Center(
                    child: AppText(
                      title: "لا توجد محادثات",
                      color: Colors.white60,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadInitialData,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(horizontal: 12.r),
                      itemCount:
                          filteredChats.length +
                          (_hasMore && _searchQuery.isEmpty && isAdmin ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= filteredChats.length) {
                          return _isLoadingMore
                              ? const Center(child: CircularProgressIndicator())
                              : const SizedBox.shrink();
                        }

                        final chat = filteredChats[index];
                        final data = chat.data() as Map<String, dynamic>;
                        final userName = data['userName'] ?? 'مستخدم';
                        final userPhone = data['userPhone'] ?? '';
                        final userId = data['userId'] ?? '';
                        final assignedSalesId = data['assignedSalesId'];
                        final lastMessage = data['lastMessage'] ?? '';
                        final lastMessageAt =
                            data['lastMessageAt'] as Timestamp?;
                        final unread = isAdmin
                            ? data['unreadByAdmin'] ?? 0
                            : data['unreadBySales'] ?? 0;

                        return Card(
                          color: AppColors.secondaryColor.withOpacity(0.2),
                          margin: EdgeInsets.only(bottom: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 25.r,
                                  backgroundColor: AppColors.primaryColor
                                      .withOpacity(0.3),
                                  child: Text(
                                    userName.isNotEmpty
                                        ? userName[0].toUpperCase()
                                        : 'U',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                if (unread > 0)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '$unread',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: AppText(
                                    title: userName,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (lastMessageAt != null)
                                  AppText(
                                    title: _formatTime(lastMessageAt),
                                    fontSize: 12,
                                    color: Colors.white60,
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (userPhone.isNotEmpty) ...[
                                  SizedBox(height: 4.h),
                                  AppText(
                                    title: '📞 $userPhone',
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ],
                                // Show Assigned Sales Info
                                if (assignedSalesId != null) ...[
                                  SizedBox(height: 4.h),
                                  FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(assignedSalesId)
                                        .get(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        final salesName =
                                            snapshot.data?.data()
                                                as Map<String, dynamic>?;
                                        return AppText(
                                          title:
                                              '💼 ${salesName?['name'] ?? 'مندوب مبيعات'}',
                                          fontSize: 12,
                                          color: Colors.blue[300],
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ],
                                SizedBox(height: 4.h),
                                AppText(
                                  title: lastMessage,
                                  fontSize: 13,
                                  color: Colors.white60,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            trailing: isAdmin
                                ? PopupMenuButton(
                                    icon: const Icon(
                                      Icons.more_vert,
                                      color: Colors.white70,
                                    ),
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'assign',
                                        child: AppText(title: 'تعيين لمندوب'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'open',
                                        child: AppText(title: 'فتح'),
                                      ),
                                    ],
                                    onSelected: (value) {
                                      if (value == 'assign') {
                                        _assignToSales(chat.id, userId);
                                      } else if (value == 'open')
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AdminChatScreen(
                                              chatId: chat.id,
                                              userName: userName,
                                              userPhone: userPhone,
                                              userEmail: '',
                                            ),
                                          ),
                                        ).then((_) => _loadInitialData());
                                    },
                                  )
                                : const Icon(
                                    Icons.chevron_right,
                                    color: Colors.white70,
                                  ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => isAdmin
                                      ? AdminChatScreen(
                                          chatId: chat.id,
                                          userName: userName,
                                          userPhone: userPhone,
                                          userEmail: '',
                                        )
                                      : SalesChatScreen(
                                          chatId: chat.id,
                                          userName: userName,
                                          userPhone: userPhone,
                                          userEmail: '',
                                        ),
                                ),
                              ).then((_) => _loadInitialData());
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    // Format time in 12-hour with AM/PM
    final hour = date.hour == 0
        ? 12
        : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'م' : 'ص'; // ص = AM, م = PM in Arabic
    final timeStr = '$hour:$minute $period';

    if (messageDate == today) {
      return 'اليوم $timeStr';
    } else if (messageDate == yesterday) {
      return 'أمس $timeStr';
    } else if (now.difference(date).inDays < 7) {
      // Within last week - show day name
      final dayNames = [
        'الأحد',
        'الإثنين',
        'الثلاثاء',
        'الأربعاء',
        'الخميس',
        'الجمعة',
        'السبت',
      ];
      return '${dayNames[date.weekday % 7]} $timeStr';
    } else {
      // Older - show date
      return '${date.day}/${date.month}/${date.year} $timeStr';
    }
  }
}

// ============================================
// 2. SHARED CHAT LOGIC (Mixin)
// ============================================

class _SharedSupportChat extends StatefulWidget {
  final String chatId;
  final String userName;
  final String userPhone;
  final String userId;
  final bool isAdmin;

  const _SharedSupportChat({
    required this.chatId,
    required this.userName,
    required this.userPhone,
    required this.userId,
    required this.isAdmin,
  });

  @override
  State<_SharedSupportChat> createState() => _SharedSupportChatState();
}

class _SharedSupportChatState extends State<_SharedSupportChat> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  // DISABLED: Voice recording feature
  // final AudioRecorder _audioRecorder = AudioRecorder();

  String? _userId;
  // bool _isRecording = false;
  bool _isUploadingMedia = false;
  // Timer? _recordingTimer;
  // int _recordDuration = 0;
  Map<String, dynamic>? _replyMessage;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
    _getChatUserId();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // _audioRecorder.dispose(); // DISABLED
    // _recordingTimer?.cancel(); // DISABLED
    super.dispose();
  }

  Future<void> _getChatUserId() async {
    final chatDoc = await FirebaseFirestore.instance
        .collection('support_chats')
        .doc(widget.chatId)
        .get();
    setState(() {
      _userId = chatDoc.data()?['userId'];
    });
  }

  Future<void> _markMessagesAsRead() async {
    final batch = FirebaseFirestore.instance.batch();
    final field = widget.isAdmin ? 'unreadByAdmin' : 'unreadBySales';

    batch.update(
      FirebaseFirestore.instance.collection('support_chats').doc(widget.chatId),
      {field: 0},
    );

    final unreadMessages = await FirebaseFirestore.instance
        .collection('support_chats')
        .doc(widget.chatId)
        .collection('messages')
        .where('isFromAdmin', isEqualTo: false)
        .where('isFromSales', isEqualTo: false)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // --- REPLY LOGIC ---
  void _startReply(Map<String, dynamic> message) {
    HapticFeedback.lightImpact();
    setState(() => _replyMessage = message);
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _cancelReply() => setState(() => _replyMessage = null);

  // --- RECORDING --- DISABLED
  // Future<void> _startRecording() async {
  //   try {
  //     var status = await Permission.microphone.status;
  //     if (status.isDenied) status = await Permission.microphone.request();
  //
  //     if (await _audioRecorder.hasPermission()) {
  //       final dir = await getTemporaryDirectory();
  //       final path =
  //           '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
  //       await _audioRecorder.start(
  //         const RecordConfig(encoder: AudioEncoder.aacLc),
  //         path: path,
  //       );
  //       setState(() {
  //         _isRecording = true;
  //         _recordDuration = 0;
  //       });
  //       _recordingTimer = Timer.periodic(
  //         const Duration(seconds: 1),
  //         (timer) => setState(() => _recordDuration++),
  //       );
  //     }
  //   } catch (e) {
  //     print(e);
  //   }
  // }
  //
  // Future<void> _stopRecording({bool send = true}) async {
  //   final path = await _audioRecorder.stop();
  //   _recordingTimer?.cancel();
  //   setState(() => _isRecording = false);
  //   if (send && path != null) {
  //     setState(() => _isUploadingMedia = true);
  //     final audioUrl = await WordPressMediaService.uploadAudio(File(path));
  //     setState(() => _isUploadingMedia = false);
  //     if (audioUrl != null) {
  //       await _sendMessage(audioUrl: audioUrl, messageType: 'audio');
  //     }
  //   }
  // }
  //
  // Future<void> _cancelRecording() async {
  //   await _stopRecording(send: false);
  //   setState(() {
  //     _recordDuration = 0;
  //   });
  // }

  // --- SEND MESSAGE ---
  Future<void> _sendMessage({
    String? imageUrl,
    String? fileUrl,
    String? audioUrl,
    String? messageType,
  }) async {
    final text = _messageController.text.trim();
    if (text.isEmpty &&
        imageUrl == null &&
        fileUrl == null &&
        audioUrl == null) {
      return;
    }
    if (_userId == null) return;

    _messageController.clear();
    final reply = _replyMessage;
    _cancelReply();
    setState(() {}); // Clear text field immediately

    // Determine Reply info
    String? replyToId, replyToText, replyToName;
    if (reply != null) {
      replyToId = reply['id'];
      replyToName = reply['isFromAdmin']
          ? "الإدارة"
          : reply['isFromSales']
          ? "المبيعات"
          : "العميل";
      final type = reply['messageType'];
      replyToText = type == 'text'
          ? reply['text']
          : (type == 'image'
                ? '📷 صورة'
                : (type == 'audio' ? '🎤 صوت' : '📎 ملف'));
    }

    final batch = FirebaseFirestore.instance.batch();
    final msgRef = FirebaseFirestore.instance
        .collection('support_chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc();

    final senderId = widget.isAdmin
        ? 'admin'
        : (FirebaseAuth.instance.currentUser?.uid ?? 'sales');

    batch.set(msgRef, {
      'text': text,
      'senderId': senderId,
      'isFromAdmin': widget.isAdmin,
      'isFromSales': !widget.isAdmin,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'messageType': messageType ?? 'text',
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (audioUrl != null) 'audioUrl': audioUrl,
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToText != null) 'replyToText': replyToText,
      if (replyToName != null) 'replyToName': replyToName,
    });

    final chatRef = FirebaseFirestore.instance
        .collection('support_chats')
        .doc(widget.chatId);
    final lastMsg = messageType == 'image'
        ? '📷 صورة'
        : messageType == 'audio'
        ? '🎤 صوت'
        : text;

    batch.update(chatRef, {
      'lastMessage': lastMsg,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadByUser': FieldValue.increment(1),
    });

    await batch.commit();
    await NotificationService.sendNotification(
      title: widget.isAdmin ? '👨‍💼 الإدارة' : '💼 المبيعات',
      body: lastMsg,
      userId: _userId!,
      deepLink: DeepLinkHandler.supportLink(),
    );

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // --- MEDIA ---
  Future<void> _pickAndSendImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image == null) return;
    setState(() => _isUploadingMedia = true);
    final url = await WordPressMediaService.uploadImage(image);
    setState(() => _isUploadingMedia = false);
    if (url != null) await _sendMessage(imageUrl: url, messageType: 'image');
  }

  Future<void> _pickAndSendFile() async {
    final file = await WordPressMediaService.pickPdfFile();
    if (file == null) return;
    setState(() => _isUploadingMedia = true);
    final url = await WordPressMediaService.uploadPdf(file);
    setState(() => _isUploadingMedia = false);
    if (url != null) await _sendMessage(fileUrl: url, messageType: 'file');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: AppBar(
        backgroundColor: AppColors.secondaryColor.withOpacity(0.3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              title: widget.userName,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            if (widget.userPhone.isNotEmpty)
              AppText(
                title: widget.userPhone,
                fontSize: 12,
                color: Colors.white70,
              ),
          ],
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('support_chats')
                    .doc(widget.chatId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا توجد رسائل',
                        style: TextStyle(color: Colors.white60),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    reverse: true,
                    controller: _scrollController,
                    padding: EdgeInsets.all(16.r),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      data['id'] = docs[index].id;
                      return _MessageBubble(
                        message: data,
                        onReply: _startReply,
                      );
                    },
                  );
                },
              ),
            ),

            // Reply Bar
            if (_replyMessage != null)
              Container(
                padding: EdgeInsets.all(12.r),
                color: Colors.black26,
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 35,
                      color: AppColors.secondaryColor,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "الرد على رسالة",
                            style: TextStyle(
                              color: AppColors.secondaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _replyMessage!['messageType'] == 'text'
                                ? _replyMessage!['text']
                                : 'مرفق',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: _cancelReply,
                    ),
                  ],
                ),
              ),

            // Input Bar
            Container(
              padding: EdgeInsets.all(16.r),
              color: Colors.white10,
              // DISABLED: Recording UI removed
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _isUploadingMedia
                        ? null
                        : () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: AppColors.secondaryColor,
                              builder: (_) => Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(
                                      Icons.image,
                                      color: Colors.white,
                                    ),
                                    title: const Text(
                                      'صورة',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickAndSendImage();
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(
                                      Icons.attach_file,
                                      color: Colors.white,
                                    ),
                                    title: const Text(
                                      'ملف',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickAndSendFile();
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                    child: Container(
                      width: 44.w,
                      height: 44.h,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(24.r),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: _isUploadingMedia
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.attach_file, color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onChanged: (val) => setState(() {}),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'اكتب ردك...',
                        hintStyle: TextStyle(color: Colors.white60),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: _messageController.text.trim().isNotEmpty
                        ? () => _sendMessage()
                        : null, // Mic disabled
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // String _formatDuration(int s) =>
  //     '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

// ============================================
// 3. WRAPPER CLASSES (Admin & Sales)
// ============================================

class AdminChatScreen extends StatelessWidget {
  final String chatId, userName, userPhone, userEmail;
  const AdminChatScreen({
    super.key,
    required this.chatId,
    required this.userName,
    required this.userPhone,
    required this.userEmail,
  });
  @override
  Widget build(BuildContext context) => _SharedSupportChat(
    chatId: chatId,
    userName: userName,
    userPhone: userPhone,
    userId: '',
    isAdmin: true,
  );
}

class SalesChatScreen extends StatelessWidget {
  final String chatId, userName, userPhone, userEmail;
  const SalesChatScreen({
    super.key,
    required this.chatId,
    required this.userName,
    required this.userPhone,
    required this.userEmail,
  });
  @override
  Widget build(BuildContext context) => _SharedSupportChat(
    chatId: chatId,
    userName: userName,
    userPhone: userPhone,
    userId: '',
    isAdmin: false,
  );
}

// ============================================
// 4. MESSAGE BUBBLE (With Linkify & Swipe)
// ============================================

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final Function(Map<String, dynamic>) onReply;

  const _MessageBubble({required this.message, required this.onReply});

  @override
  Widget build(BuildContext context) {
    final isFromAdmin = message['isFromAdmin'] ?? false;
    final isFromSales = message['isFromSales'] ?? false;
    final isFromSupport = isFromAdmin || isFromSales;

    final type = message['messageType'] ?? 'text';
    final text = message['text'] ?? '';
    final url = type == 'image'
        ? message['imageUrl']
        : type == 'file'
        ? message['fileUrl']
        : message['audioUrl'];
    final replyText = message['replyToText'];

    return Dismissible(
      key: Key(message['id'] ?? DateTime.now().toString()),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        onReply(message);
        return false;
      },
      background: const Align(
        alignment: Alignment.centerRight,
        child: Icon(Icons.reply, color: Colors.white),
      ),
      child: Align(
        alignment: isFromSupport
            ? Alignment.centerRight
            : Alignment.centerLeft, // Support (Right), User (Left) in RTL
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isFromSupport
                ? Colors.blue.withOpacity(0.2)
                : Colors.white10,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reply Display
              if (replyText != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: const BoxDecoration(
                    color: Colors.black26,
                    border: Border(
                      right: BorderSide(color: Colors.orange, width: 3),
                    ),
                  ),
                  child: Text(
                    replyText,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),

              // Content
              if (type == 'image')
                GestureDetector(
                  onTap: () => _openImage(context, url),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    placeholder: (_, __) => const CircularProgressIndicator(),
                    errorWidget: (_, __, ___) => const Icon(Icons.error),
                  ),
                ),
              // Voice messages currently disabled
              const Text(
                '🎤 الرسائل الصوتية معطلة مؤقتاً',
                style: TextStyle(
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (type == 'file')
                GestureDetector(
                  onTap: () => _openFile(context, url),
                  child: const Row(
                    children: [
                      Icon(Icons.file_present, color: Colors.white),
                      SizedBox(width: 8),
                      Text("ملف مرفق", style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              if (type == 'text')
                SelectableLinkify(
                  text: text,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  linkStyle: const TextStyle(color: Colors.blueAccent),
                  onOpen: (link) async {
                    final uri = Uri.parse(link.url);
                    try {
                      if (!await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      )) {
                        await launchUrl(uri);
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('لا يمكن فتح الرابط')),
                      );
                    }
                  },
                ),

              const SizedBox(height: 4),
              Text(
                _formatTime(message['timestamp']),
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(child: CachedNetworkImage(imageUrl: url)),
      ),
    );
  }

  Future<void> _openFile(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('لا يمكن فتح هذا الملف')));
    }
  }

  String _formatTime(Timestamp? t) {
    if (t == null) return '';
    final date = t.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    // Format time in 12-hour with AM/PM
    final hour = date.hour == 0
        ? 12
        : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'م' : 'ص';
    final timeStr = '$hour:$minute $period';

    if (messageDate == today) {
      return 'اليوم $timeStr';
    } else if (messageDate == yesterday) {
      return 'أمس $timeStr';
    } else if (now.difference(date).inDays < 7) {
      final dayNames = [
        'الأحد',
        'الإثنين',
        'الثلاثاء',
        'الأربعاء',
        'الخميس',
        'الجمعة',
        'السبت',
      ];
      return '${dayNames[date.weekday % 7]} $timeStr';
    } else {
      return '${date.day}/${date.month}/${date.year} $timeStr';
    }
  }
}
