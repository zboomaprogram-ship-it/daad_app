import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/images_picker_grid.dart'; // Keep your imports
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/utils/notification_utils/notification_utils.dart';
import 'package:daad_app/features/contact/voice_message_bubble.dart';
import 'package:daad_app/features/contact/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard & HapticFeedback
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';

// ============================================
// 1. CONTACT SCREEN
// ============================================

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  String _contactMethod = 'app';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const GlassBackButton(),
        title: const Text(
          'تواصل معنا',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(color: AppColors.primaryColor),
        child: SafeArea(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                SizedBox(height: 20.h),
                Center(
                  child: GlassContainer(
                    width: 100.w,
                    height: 100.h,
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                const Center(
                  child: Text(
                    'اختر طريقة التواصل',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Center(
                  child: Text(
                    'يمكنك التواصل معنا عبر الدردشة أو الواتساب',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ContactMethodCard(
                          icon: Icons.chat_rounded,
                          title: 'دردشة داخل التطبيق',
                          isSelected: _contactMethod == 'app',
                          onTap: () => setState(() => _contactMethod = 'app'),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: _ContactMethodCard(
                          icon: Icons.chat_bubble_rounded,
                          title: 'واتساب مباشر',
                          isSelected: _contactMethod == 'whatsapp',
                          onTap: () =>
                              setState(() => _contactMethod = 'whatsapp'),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ContactGlassButton(
                    onPressed: () {
                      if (_contactMethod == 'app') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserChatScreen(),
                          ),
                        );
                      } else {
                        launchUrl(
                          Uri.parse(
                            'https://wa.me/+966564639466?text=أرغب باستشارة تسويقية',
                          ),
                        );
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _contactMethod == 'app'
                              ? Icons.chat_rounded
                              : Icons.chat_bubble_rounded,
                          size: 20,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          _contactMethod == 'app'
                              ? 'بدء المحادثة'
                              : 'فتح الواتساب',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _ContactMethodCard({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isSelected
                    ? Colors.white.withOpacity(0.4)
                    : Colors.white.withOpacity(0.15),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, size: 40, color: Colors.white),
                SizedBox(height: 12.h),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================
// 2. USER CHAT SCREEN
// ============================================

class UserChatScreen extends StatefulWidget {
  const UserChatScreen({super.key});

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  Timer? _recordingTimer;
  int _recordDuration = 0;

  Map<String, dynamic>? _replyMessage;

  String? _chatId;
  String? _assignedSalesId;
  bool _isLoading = true;
  bool _isUploadingMedia = false;

  static const int _messagesLimit = 30;
  DocumentSnapshot? _lastDocument;
  bool _hasMoreMessages = true;
  bool _isLoadingMore = false;

  StreamSubscription<QuerySnapshot>? _messagesSubscription;
  final List<Map<String, dynamic>> _messages = [];
  String? _assignedSalesName; // For call button
  @override
  void initState() {
    super.initState();
    _initializeChat();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messagesSubscription?.cancel();
    _audioRecorder.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels <= 100 &&
        !_isLoadingMore &&
        _hasMoreMessages &&
        _chatId != null) {
      _loadMoreMessages();
    }
  }

  // --- REPLY LOGIC ---
  void _startReply(Map<String, dynamic> message) {
    HapticFeedback.lightImpact(); // Small vibration on reply
    setState(() {
      _replyMessage = message;
    });
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _cancelReply() {
    setState(() {
      _replyMessage = null;
    });
  }

  Future<void> _initializeChat() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final existingChat = await FirebaseFirestore.instance
          .collection('support_chats')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (existingChat.docs.isNotEmpty) {
        _chatId = existingChat.docs.first.id;
        final chatData = existingChat.docs.first.data();
        _assignedSalesId = chatData['assignedSalesId'];

        // Get assigned sales name for call
        if (_assignedSalesId != null) {
          final salesDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(_assignedSalesId)
              .get();
          _assignedSalesName = salesDoc.data()?['name'] ?? 'دعم فني';
        }

        await _markMessagesAsRead();
        await _loadInitialMessages();
        _setupRealtimeListener();
      } else {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final userData = userDoc.data() ?? {};

        final chatRef = await FirebaseFirestore.instance
            .collection('support_chats')
            .add({
              'userId': user.uid,
              'userName': userData['name'] ?? user.displayName ?? 'مستخدم',
              'userEmail': userData['email'] ?? user.email ?? '',
              'userPhone': userData['phone'] ?? '',
              'assignedSalesId': null,
              'createdAt': FieldValue.serverTimestamp(),
              'lastMessageAt': FieldValue.serverTimestamp(),
              'lastMessage': 'بدأت المحادثة',
              'unreadByAdmin': 0,
              'unreadBySales': 0,
              'unreadByUser': 0,
              'status': 'active',
            });
        _chatId = chatRef.id;
        _setupRealtimeListener();
      }
      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Error initializing chat: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadInitialMessages() async {
    if (_chatId == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(_chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(_messagesLimit)
          .get();

      setState(() {
        _messages.clear();
        for (var doc in snapshot.docs.reversed) {
          _messages.add({'id': doc.id, ...doc.data()});
        }
        if (snapshot.docs.isNotEmpty) {
          _lastDocument = snapshot.docs.last;
          _hasMoreMessages = snapshot.docs.length == _messagesLimit;
        } else {
          _hasMoreMessages = false;
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      print('❌ Error loading initial: $e');
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_chatId == null || !_hasMoreMessages || _lastDocument == null) return;
    setState(() => _isLoadingMore = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(_chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_messagesLimit)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMoreMessages = false;
          _isLoadingMore = false;
        });
        return;
      }

      setState(() {
        for (var doc in snapshot.docs.reversed) {
          _messages.insert(0, {'id': doc.id, ...doc.data()});
        }
        _lastDocument = snapshot.docs.last;
        _hasMoreMessages = snapshot.docs.length == _messagesLimit;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  void _setupRealtimeListener() {
    if (_chatId == null) return;
    final now = Timestamp.now();
    _messagesSubscription = FirebaseFirestore.instance
        .collection('support_chats')
        .doc(_chatId)
        .collection('messages')
        .where('timestamp', isGreaterThan: now)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final newMessage = {'id': change.doc.id, ...change.doc.data()!};
              if (!_messages.any((m) => m['id'] == newMessage['id'])) {
                setState(() => _messages.add(newMessage));
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });
                if (newMessage['isFromAdmin'] == true ||
                    newMessage['isFromSales'] == true) {
                  _markSingleMessageAsRead(change.doc.id);
                }
              }
            }
          }
        });
  }

  Future<void> _markMessagesAsRead() async {
    if (_chatId == null) return;
    final batch = FirebaseFirestore.instance.batch();
    batch.update(
      FirebaseFirestore.instance.collection('support_chats').doc(_chatId),
      {'unreadByUser': 0},
    );
    final unreadMessages = await FirebaseFirestore.instance
        .collection('support_chats')
        .doc(_chatId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .limit(50)
        .get();
    for (final doc in unreadMessages.docs) {
      final data = doc.data();
      if (data['isFromAdmin'] == true || data['isFromSales'] == true) {
        batch.update(doc.reference, {'isRead': true});
      }
    }
    await batch.commit();
  }

  Future<void> _markSingleMessageAsRead(String messageId) async {
    if (_chatId == null) return;
    await FirebaseFirestore.instance
        .collection('support_chats')
        .doc(_chatId)
        .collection('messages')
        .doc(messageId)
        .update({'isRead': true});
    await FirebaseFirestore.instance
        .collection('support_chats')
        .doc(_chatId)
        .update({'unreadByUser': FieldValue.increment(-1)});
  }

  // --- RECORDING FUNCTIONS ---
  Future<void> _startRecording() async {
    try {
      var status = await Permission.microphone.status;
      if (status.isDenied) status = await Permission.microphone.request();

      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path =
            '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        const config = RecordConfig(encoder: AudioEncoder.aacLc);

        await _audioRecorder.start(config, path: path);

        setState(() {
          _isRecording = true;
          _recordDuration = 0;
        });

        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordDuration++;
          });
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("يرجى تفعيل صلاحية الميكروفون")),
        );
      }
    } catch (e) {
      print("Error starting record: $e");
    }
  }

  Future<void> _stopRecording({bool send = true}) async {
    try {
      final path = await _audioRecorder.stop();
      _recordingTimer?.cancel();
      setState(() {
        _isRecording = false;
      });

      if (send && path != null) {
        final file = File(path);
        setState(() => _isUploadingMedia = true);
        final audioUrl = await WordPressMediaService.uploadAudio(file);
        setState(() => _isUploadingMedia = false);

        if (audioUrl != null) {
          await _sendMessage(audioUrl: audioUrl, messageType: 'audio');
        }
      }
    } catch (e) {
      print("Error stopping record: $e");
      setState(() => _isUploadingMedia = false);
    }
  }

  Future<void> _cancelRecording() async {
    await _stopRecording(send: false);
    setState(() {
      _recordDuration = 0;
    });
  }

  String _formatRecordDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  // --- MEDIA FUNCTIONS ---
  Future<void> _pickAndSendImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image == null) return;
      setState(() => _isUploadingMedia = true);
      final imageUrl = await WordPressMediaService.uploadImage(image);
      if (imageUrl == null) throw Exception('فشل رفع الصورة');
      await _sendMessage(imageUrl: imageUrl, messageType: 'image');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ في رفع الصورة: $e')));
    } finally {
      setState(() => _isUploadingMedia = false);
    }
  }

  Future<void> _pickAndSendFile() async {
    try {
      final file = await WordPressMediaService.pickPdfFile();
      if (file == null) return;
      setState(() => _isUploadingMedia = true);
      final fileUrl = await WordPressMediaService.uploadPdf(file);
      if (fileUrl == null) throw Exception('فشل رفع الملف');
      await _sendMessage(fileUrl: fileUrl, messageType: 'file');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ في رفع الملف: $e')));
    } finally {
      setState(() => _isUploadingMedia = false);
    }
  }

  // --- SEND MESSAGE ---
  Future<void> _sendMessage({
    String? imageUrl,
    String? fileUrl,
    String? audioUrl,
    String? messageType,
  }) async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty &&
        imageUrl == null &&
        fileUrl == null &&
        audioUrl == null)
      return;
    if (_chatId == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _messageController.clear();

    // Capture and Clear Reply
    final replyData = _replyMessage;
    _cancelReply();
    setState(() {});

    // Prepare Reply Fields
    String? replyToId;
    String? replyToText;
    String? replyToName;
    String? replyToType;

    if (replyData != null) {
      replyToId = replyData['id'];
      replyToName = (replyData['isFromAdmin'] == true)
          ? "الإدارة"
          : (replyData['isFromSales'] == true)
          ? "المبيعات"
          : "أنت";
      replyToType = replyData['messageType'] ?? 'text';

      if (replyToType == 'text') {
        replyToText = replyData['text'];
      } else if (replyToType == 'image') {
        replyToText = "📷 صورة";
      } else if (replyToType == 'audio') {
        replyToText = "🎤 رسالة صوتية";
      } else if (replyToType == 'file') {
        replyToText = "📎 ملف";
      }
    }

    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final optimisticMessage = {
      'id': tempId,
      'text': messageText,
      'senderId': user.uid,
      'isFromAdmin': false,
      'isFromSales': false,
      'timestamp': Timestamp.now(),
      'isRead': false,
      'messageType': messageType ?? 'text',
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (audioUrl != null) 'audioUrl': audioUrl,
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToText != null) 'replyToText': replyToText,
      if (replyToName != null) 'replyToName': replyToName,
    };

    setState(() {
      _messages.add(optimisticMessage);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      final batch = FirebaseFirestore.instance.batch();
      final messageRef = FirebaseFirestore.instance
          .collection('support_chats')
          .doc(_chatId)
          .collection('messages')
          .doc();

      batch.set(messageRef, {
        'text': messageText,
        'senderId': user.uid,
        'isFromAdmin': false,
        'isFromSales': false,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'messageType': messageType ?? 'text',
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (fileUrl != null) 'fileUrl': fileUrl,
        if (audioUrl != null) 'audioUrl': audioUrl,
        if (replyToId != null) 'replyToId': replyToId,
        if (replyToText != null) 'replyToText': replyToText,
        if (replyToName != null) 'replyToName': replyToName,
        if (replyToType != null) 'replyToType': replyToType,
      });

      final chatRef = FirebaseFirestore.instance
          .collection('support_chats')
          .doc(_chatId);
      final lastMessage = messageType == 'image'
          ? '📷 صورة'
          : messageType == 'file'
          ? '📎 ملف'
          : messageType == 'audio'
          ? '🎤 رسالة صوتية'
          : messageText;

      batch.update(chatRef, {
        'lastMessage': lastMessage,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadByAdmin': FieldValue.increment(1),
        if (_assignedSalesId != null) 'unreadBySales': FieldValue.increment(1),
      });

      await batch.commit();
      setState(() {
        _messages.removeWhere((m) => m['id'] == tempId);
      });
      _notifyAdminAndSales(lastMessage);
    } catch (e) {
      print('❌ Error sending message: $e');
      setState(() {
        _messages.removeWhere((m) => m['id'] == tempId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل إرسال الرسالة. حاول مرة أخرى.')),
      );
    }
  }

  Future<void> _notifyAdminAndSales(String messageText) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userName = userDoc.data()?['name'] ?? 'مستخدم';

      // ✅ FIXED: Query by 'role' field not 'isAdmin'
      final admins = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(10)
          .get();

      // Notify all admins
      for (final admin in admins.docs) {
        await NotificationService.sendNotification(
          title: '💬 رسالة جديدة من $userName',
          body: messageText,
          userId: admin.id,
          deepLink: 'chat/${user.uid}',
        );
      }

      // Notify assigned sales (if exists and not already an admin)
      if (_assignedSalesId != null && _assignedSalesId!.isNotEmpty) {
        final isAlreadyNotified = admins.docs.any(
          (doc) => doc.id == _assignedSalesId,
        );
        if (!isAlreadyNotified) {
          await NotificationService.sendNotification(
            title: '💬 رسالة جديدة من $userName',
            body: messageText,
            userId: _assignedSalesId!,
            deepLink: 'chat/${user.uid}',
          );
        }
      }
    } catch (e) {
      print('❌ Error notifying admin/sales: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.primaryColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const GlassBackButton(),
          title: const Text(
            'الدعم الفني',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: _buildShimmerLoading(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const GlassBackButton(),
        title: const Text(
          'الدعم الفني',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        // actions: [
        //   // Voice Call Button - only show if sales agent is assigned
        //   if (_assignedSalesId != null)
        //     Padding(
        //       padding: EdgeInsets.only(left: 12.w),
        //       child: CallButton(
        //         receiverId: _assignedSalesId!,
        //         receiverName: 'دعم فني',
        //       ),
        //     ),
        // ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16.r),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _MessageBubble(
                        message: message,
                        onReply: _startReply,
                      );
                    },
                  ),
                  if (_isLoadingMore)
                    Positioned(
                      top: 10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // --- REPLY PREVIEW BAR ---
            if (_replyMessage != null)
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4.w,
                      height: 35.h,
                      color: AppColors.secondaryColor,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "الرد على: ${(_replyMessage!['isFromAdmin'] == true)
                                ? "الإدارة"
                                : (_replyMessage!['isFromSales'] == true)
                                ? "المبيعات"
                                : "أنت"}",
                            style: TextStyle(
                              color: AppColors.secondaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
                            ),
                          ),
                          Text(
                            _getReplyPreviewText(_replyMessage!),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: _cancelReply,
                    ),
                  ],
                ),
              ),

            // --- INPUT BAR ---
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              child: _isRecording
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: _cancelRecording,
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              _formatRecordDuration(_recordDuration),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const Text(
                          "جاري التسجيل...",
                          style: TextStyle(color: Colors.white70),
                        ),
                        SizedBox(width: 10.w),
                        GestureDetector(
                          onTap: () => _stopRecording(send: true),
                          child: CircleAvatar(
                            backgroundColor: AppColors.primaryColor,
                            radius: 24.r,
                            child: const Icon(Icons.send, color: Colors.white),
                          ),
                        ),
                      ],
                    )
                  : Row(
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
                                            'إرسال صورة',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
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
                                            'إرسال ملف',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
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
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(24.r),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: _isUploadingMedia
                                ? const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.attach_file,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24.r),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(24.r),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: TextField(
                                  controller: _messageController,
                                  onChanged: (val) {
                                    setState(() {});
                                  },
                                  style: const TextStyle(color: Colors.white),
                                  maxLines: null,
                                  decoration: const InputDecoration(
                                    hintText: 'اكتب رسالتك...',
                                    hintStyle: TextStyle(color: Colors.white60),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        GestureDetector(
                          onTap: () {
                            if (_messageController.text.trim().isNotEmpty ||
                                _replyMessage != null) {
                              _sendMessage();
                            } else {
                              _startRecording();
                            }
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24.r),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                width: 44.w,
                                height: 44.h,
                                decoration: BoxDecoration(
                                  color:
                                      (_messageController.text
                                              .trim()
                                              .isNotEmpty ||
                                          _replyMessage != null)
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.red.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(24.r),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                child: Icon(
                                  (_messageController.text.trim().isNotEmpty ||
                                          _replyMessage != null)
                                      ? Icons.send_rounded
                                      : Icons.mic_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _getReplyPreviewText(Map<String, dynamic> msg) {
    String type = msg['messageType'] ?? 'text';
    if (type == 'image') return "📷 صورة";
    if (type == 'audio') return "🎤 رسالة صوتية";
    if (type == 'file') return "📎 ملف";
    return msg['text'] ?? '';
  }

  Widget _buildShimmerLoading() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView.builder(
        padding: EdgeInsets.all(16.r),
        itemCount: 8,
        itemBuilder: (context, index) {
          final isFromAdmin = index % 3 == 0;
          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: Row(
              mainAxisAlignment: isFromAdmin
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.end,
              children: [
                if (!isFromAdmin) const Spacer(),
                Flexible(
                  child: Shimmer.fromColors(
                    baseColor: Colors.white.withOpacity(0.1),
                    highlightColor: Colors.white.withOpacity(0.3),
                    child: Container(
                      width:
                          MediaQuery.of(context).size.width *
                          (isFromAdmin ? 0.7 : 0.6),
                      height: index % 2 == 0 ? 80.h : 60.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                  ),
                ),
                if (isFromAdmin) const Spacer(),
              ],
            ),
          );
        },
      ),
    );
  }
}
// ============================================
// 3. MESSAGE BUBBLE WITH SWIPE & LONG PRESS REPLY
// ============================================

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final Function(Map<String, dynamic>) onReply;

  const _MessageBubble({required this.message, required this.onReply});

  @override
  Widget build(BuildContext context) {
    final isFromAdmin = message['isFromAdmin'] ?? false;
    final isFromSales = message['isFromSales'] ?? false;
    final text = message['text'] ?? '';
    final timestamp = message['timestamp'] as Timestamp?;
    final messageType = message['messageType'] ?? 'text';
    final imageUrl = message['imageUrl'];
    final fileUrl = message['fileUrl'];
    final audioUrl = message['audioUrl'];

    final replyToText = message['replyToText'];
    final replyToName = message['replyToName'];

    final isFromSupport = isFromAdmin || isFromSales;

    return Dismissible(
      key: Key(message['id']),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        onReply(message);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.reply, color: Colors.white),
      ),
      child: GestureDetector(
        onLongPress: () {
          _showMessageOptions(context, text, imageUrl, fileUrl, audioUrl);
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: isFromSupport
                ? MainAxisAlignment.start
                : MainAxisAlignment.end,
            children: [
              if (!isFromSupport) const Spacer(),
              Flexible(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isFromSupport
                            ? Colors.white.withOpacity(0.15)
                            : Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isFromSales) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                ' دعم فني',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 8.h),
                          ],
                          if (isFromAdmin) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '👨‍💼 الإدارة',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 8.h),
                          ],

                          if (replyToText != null) ...[
                            Container(
                              margin: EdgeInsets.only(bottom: 8.h),
                              padding: EdgeInsets.all(8.r),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8.r),
                                border: const Border(
                                  right: BorderSide(
                                    color: AppColors.secondaryColor,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    replyToName ?? "مستخدم",
                                    style: TextStyle(
                                      color: AppColors.secondaryColor,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    replyToText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (messageType == 'audio' && audioUrl != null) ...[
                            VoiceMessageBubble(
                              audioUrl: audioUrl,
                              isSender: !isFromSupport,
                            ),
                            if (text.isNotEmpty) SizedBox(height: 8.h),
                          ],

                          if (messageType == 'image' && imageUrl != null) ...[
                            GestureDetector(
                              onTap: () => _showFullImage(context, imageUrl),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12.r),
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  width: 200.w,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    width: 200.w,
                                    height: 150.h,
                                    color: Colors.white.withOpacity(0.1),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        width: 200.w,
                                        height: 150.h,
                                        color: Colors.red.withOpacity(0.2),
                                        child: const Center(
                                          child: Icon(
                                            Icons.error,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                ),
                              ),
                            ),
                            if (text.isNotEmpty) SizedBox(height: 8.h),
                          ],

                          if (messageType == 'file' && fileUrl != null) ...[
                            GestureDetector(
                              onTap: () => _openFile(context, fileUrl),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.insert_drive_file,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    SizedBox(width: 8.w),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'ملف مرفق',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'اضغط للفتح',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.7,
                                              ),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (text.isNotEmpty) SizedBox(height: 8.h),
                          ],

                          // --- UPDATED TEXT WIDGET WITH LINK SUPPORT ---
                          if (text.isNotEmpty)
                            SelectableLinkify(
                              text: text,
                              onOpen: (link) async {
                                final uri = Uri.parse(link.url);
                                try {
                                  // 1. Try launching specifically in an external app (Browser)
                                  if (!await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  )) {
                                    // 2. If that fails, try the default platform mode (fallback)
                                    if (!await launchUrl(
                                      uri,
                                      mode: LaunchMode.platformDefault,
                                    )) {
                                      throw 'Could not launch $uri';
                                    }
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('لا يمكن فتح الرابط'),
                                    ),
                                  );
                                }
                              },
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                              linkStyle: const TextStyle(
                                color: AppColors.secondaryTextColor,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.secondaryTextColor,
                              ),
                              options: const LinkifyOptions(humanize: false),
                            ),

                          if (timestamp != null) ...[
                            SizedBox(height: 4.h),
                            Text(
                              _formatTime(timestamp),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (isFromSupport) const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  // ... Keep existing helper methods (_showMessageOptions, _showFullImage, _openFile, _formatTime) ...
  void _showMessageOptions(
    BuildContext context,
    String text,
    String? imageUrl,
    String? fileUrl,
    String? audioUrl,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.secondaryColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.reply, color: Colors.white),
                title: const Text('رد', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  onReply(message);
                },
              ),
              if (text.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.copy, color: Colors.white),
                  title: const Text(
                    'نسخ النص',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: text));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم نسخ النص')),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Icon(Icons.error, color: Colors.white, size: 50),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openFile(BuildContext context, String fileUrl) async {
    try {
      final uri = Uri.parse(fileUrl);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $fileUrl';
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('لا يمكن فتح هذا الملف')));
    }
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
