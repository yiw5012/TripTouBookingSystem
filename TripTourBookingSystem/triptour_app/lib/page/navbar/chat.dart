import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:triptour_app/page/navbar/memberDetail.dart';
import 'package:triptour_app/page/navbar/pdfService.dart' as PdfService;
import 'package:triptour_app/services/serverApi.dart';

// ==========================================
// 1. หน้าแสดงรายการห้องแชต (Chat List)
// ==========================================
class ChatPage extends StatefulWidget {
  final String userRole; // รับค่าบทบาทจากระบบล็อกอิน ('guide' หรือ 'user')
  final String? selectedRoomId;
  final String? selectedRoomName;

  const ChatPage({
    super.key,
    required this.userRole,
    this.selectedRoomId,
    this.selectedRoomName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final myUid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (myUid == null) {
      return const Scaffold(
        body: Center(child: Text("กรุณาเข้าสู่ระบบก่อนใช้งาน")),
      );
    }

    final directRoomId = (widget.selectedRoomId ?? '').trim();
    if (directRoomId.isNotEmpty) {
      return ChatRoomPage(
        roomId: directRoomId,
        roomName: (widget.selectedRoomName ?? 'ห้องแชต').trim().isNotEmpty
            ? widget.selectedRoomName ?? 'ห้องแชต'
            : 'ห้องแชต',
        myRole: widget.userRole,
      );
    }

    final isGuide = widget.userRole == 'guide';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F3),
      appBar: AppBar(
        title: Row(
          children: [
            Text(isGuide ? "รายการทริปที่ดูแล" : "ทริปท่องเที่ยวของคุณ"),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isGuide
                    ? const Color(0xFF1FAE5B)
                    : const Color(0xFF17A85B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isGuide ? "🧭GUIDE" : "👤USER",
                style: const TextStyle(
                  fontSize: 8,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFF1FAE5B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // ดึงเฉพาะห้องที่ Admin กำหนดสิทธิ์ให้ UID นี้ใน user_rooms
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('user_rooms/$myUid').onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("เกิดข้อผิดพลาด: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rawData = snapshot.data?.snapshot.value;
          if (rawData == null) {
            return const Center(
              child: Text("ยังไม่มีห้องแชตที่ได้รับการมอบหมายจากแอดมิน"),
            );
          }

          final userRoomsMap = Map<String, dynamic>.from(rawData as Map);
          final List<String> roomIds = userRoomsMap.keys
              .cast<String>()
              .toList();

          if (roomIds.isEmpty) {
            return const Center(
              child: Text("ยังไม่มีห้องแชตที่ได้รับการมอบหมายจากแอดมิน"),
            );
          }

          return ListView.builder(
            itemCount: roomIds.length,
            itemBuilder: (context, index) {
              final roomId = roomIds[index];

              return StreamBuilder<DatabaseEvent>(
                stream: FirebaseDatabase.instance.ref('rooms/$roomId').onValue,
                builder: (context, roomSnapshot) {
                  if (!roomSnapshot.hasData ||
                      roomSnapshot.data?.snapshot.value == null) {
                    return const SizedBox.shrink();
                  }

                  final room = Map<String, dynamic>.from(
                    roomSnapshot.data!.snapshot.value as Map,
                  );

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE7EAE6)),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: isGuide
                            ? const Color(0xFF1FAE5B).withOpacity(0.12)
                            : const Color(0xFF17A85B).withOpacity(0.12),
                        child: Icon(
                          isGuide
                              ? Icons.map_outlined
                              : Icons.chat_bubble_outline_rounded,
                          color: const Color(0xFF1FAE5B),
                        ),
                      ),
                      title: Text(
                        room['roomName'] ?? 'ไม่มีชื่อห้อง',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B1B1B),
                        ),
                      ),
                      subtitle: Text(
                        room['lastMessage'] ?? 'ยังไม่มีข้อความ',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.black45,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatRoomPage(
                              roomId: roomId,
                              roomName: room['roomName'] ?? 'ห้องแชต',
                              myRole: widget.userRole,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// 2. หน้าพูดคุยภายในห้อง (Chat Room)
// ==========================================
class ChatRoomPage extends StatefulWidget {
  final String roomId;
  final String roomName;
  final String myRole;

  const ChatRoomPage({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.myRole,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _msgController = TextEditingController();
  final myUid = FirebaseAuth.instance.currentUser?.uid;

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || myUid == null) return;

    _msgController.clear();
    final db = FirebaseDatabase.instance.ref();
    final newMsgRef = db.child('messages/${widget.roomId}').push();

    Map<String, dynamic> updates = {
      '/messages/${widget.roomId}/${newMsgRef.key}': {
        'senderId': myUid,
        'senderEmail': FirebaseAuth.instance.currentUser?.email ?? 'User',
        'senderType': 'user',
        'senderRole': widget.myRole,
        'text': text,
        'timestamp': ServerValue.timestamp,
      },
      '/rooms/${widget.roomId}/lastMessage': text,
      '/rooms/${widget.roomId}/lastUpdated': ServerValue.timestamp,
    };

    await db.update(updates);
  }

  @override
  Widget build(BuildContext context) {
    final isGuideUser = widget.myRole == 'guide';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1FAE5B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.roomName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          if (isGuideUser)
            TextButton.icon(
              onPressed: () {
                _showMembersList(context);
              },
              icon: const Icon(
                Icons.group_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: const Text(
                "ลูกทัวร์",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance
                  .ref('messages/${widget.roomId}')
                  .orderByChild('timestamp')
                  .onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rawData = snapshot.data?.snapshot.value;
                if (rawData == null) {
                  return const Center(
                    child: Text("เริ่มส่งข้อความสนทนาในห้องนี้"),
                  );
                }

                final Map<dynamic, dynamic> map =
                    rawData as Map<dynamic, dynamic>;
                final List<Map<String, dynamic>> messages = [];

                map.forEach((key, value) {
                  messages.add(Map<String, dynamic>.from(value as Map));
                });

                messages.sort(
                  (a, b) =>
                      (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0),
                );

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == myUid;
                    final isGuideSender = msg['senderRole'] == 'guide';

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? (isGuideSender
                                    ? const Color(0xFF1FAE5B).withOpacity(0.18)
                                    : const Color(0xFF17A85B).withOpacity(0.18))
                              : (isGuideSender
                                    ? const Color(0xFF1FAE5B).withOpacity(0.08)
                                    : Colors.white),
                          border: Border.all(
                            color: isGuideSender
                                ? const Color(0xFF1FAE5B).withOpacity(0.3)
                                : Colors.transparent,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isGuideSender) ...[
                                  const Icon(
                                    Icons.explore_rounded,
                                    size: 12,
                                    color: Color(0xFF1FAE5B),
                                  ),
                                  const SizedBox(width: 3),
                                  const Text(
                                    "[ไกด์] ",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1FAE5B),
                                    ),
                                  ),
                                ],
                                if (!isMe)
                                  Text(
                                    msg['senderEmail'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              msg['text'] ?? '',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: isGuideUser
                          ? 'พิมพ์ตอบลูกทัวร์...'
                          : 'พิมพ์ข้อความ...',
                      filled: true,
                      fillColor: const Color(0xFFF8FBF9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(color: Color(0xFFE7EAE6)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(color: Color(0xFFE7EAE6)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(
                          color: Color(0xFF1FAE5B),
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1FAE5B),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMembersList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        bool isPrintingAll = false;

        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(16),
              child: StreamBuilder<DatabaseEvent>(
                stream: FirebaseDatabase.instance
                    .ref('rooms/${widget.roomId}/members')
                    .onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData ||
                      snapshot.data?.snapshot.value == null) {
                    return const Center(child: Text("ไม่พบข้อมูลสมาชิก"));
                  }

                  final membersMap = Map<String, dynamic>.from(
                    snapshot.data!.snapshot.value as Map,
                  );

                  final entries = membersMap.entries.toList();

                  return Column(
                    children: [
                      // ส่วนหัวเรื่อง + ปุ่มพิมพ์รวมทั้งหมด
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              "สมาชิกในทริป (${entries.length} คน)",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B1B1B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1FAE5B),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              minimumSize: const Size(0, 0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: isPrintingAll
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.print_rounded, size: 18),
                            label: Text(
                              isPrintingAll ? "กำลังเตรียม..." : "พิมพ์ PDF",
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            onPressed: isPrintingAll
                                ? null
                                : () async {
                                    setStateModal(() => isPrintingAll = true);

                                    try {
                                      final futures = entries.map((e) async {
                                        final detail =
                                            await Serverapi.getMemberDetail(
                                              e.key,
                                            );
                                        if (detail != null) {
                                          detail['role'] = e.value.toString();
                                        }
                                        return detail;
                                      });

                                      final results = await Future.wait(
                                        futures,
                                      );

                                      final validMembers = results
                                          .whereType<Map<String, dynamic>>()
                                          .toList();

                                      if (validMembers.isNotEmpty) {
                                        await PdfService.generateAndPrintAllMembersPdf(
                                          validMembers,
                                        );
                                      }
                                    } catch (e) {
                                      debugPrint(
                                        "Error fetching all members: $e",
                                      );
                                    } finally {
                                      setStateModal(
                                        () => isPrintingAll = false,
                                      );
                                    }
                                  },
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Expanded(
                        child: ListView.builder(
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final uid = entries[index].key;
                            final role = entries[index].value.toString();
                            final isGuide = role == 'guide';

                            return FutureBuilder<Map<String, dynamic>?>(
                              future: Serverapi.getMemberDetail(uid),
                              builder: (context, userSnapshot) {
                                if (userSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const ListTile(
                                    leading: CircleAvatar(
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                    title: Text("กำลังโหลดข้อมูล..."),
                                  );
                                }

                                final userData = userSnapshot.data;
                                final firstName = userData?['first_name'] ?? '';
                                final lastName = userData?['last_name'] ?? '';
                                final fullName = "$firstName $lastName".trim();
                                final displayName = fullName.isNotEmpty
                                    ? fullName
                                    : "UID: ${uid.substring(0, 6)}...";
                                final profileImg = userData?['image_profile'];

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isGuide
                                        ? Colors.orange
                                        : Colors.blue.shade400,
                                    backgroundImage:
                                        (profileImg != null &&
                                            profileImg.toString().isNotEmpty)
                                        ? NetworkImage(profileImg)
                                        : null,
                                    child:
                                        (profileImg == null ||
                                            profileImg.toString().isEmpty)
                                        ? Icon(
                                            isGuide
                                                ? Icons.explore
                                                : Icons.person,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  title: Text(displayName),
                                  subtitle: Text(
                                    isGuide ? "ไกด์ผู้ดูแล" : "ลูกทัวร์",
                                    style: TextStyle(
                                      color: isGuide
                                          ? Colors.deepOrange
                                          : Colors.grey.shade700,
                                      fontWeight: isGuide
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),

                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            MemberDetailPage(targetUid: uid),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
