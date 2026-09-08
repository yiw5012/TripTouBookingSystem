import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:triptour_app/page/navbar/memberDetail.dart';
import 'package:triptour_app/page/navbar/pdfService.dart' as PdfService;
import 'package:triptour_app/serverApi.dart';

// ==========================================
// 1. หน้าแสดงรายการห้องแชต (Chat List)
// ==========================================
class ChatPage extends StatefulWidget {
  final String userRole; // รับค่าบทบาทจากระบบล็อกอิน ('guide' หรือ 'user')

  const ChatPage({super.key, required this.userRole});

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

    final isGuide = widget.userRole == 'guide';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(isGuide ? "รายการทริปที่ดูแล" : "ทริปท่องเที่ยวของคุณ"),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isGuide ? Colors.deepOrange : Colors.blue.shade700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isGuide ? "🧭 GUIDE" : "👤 USER",
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isGuide ? Colors.amber.shade300 : Colors.greenAccent,
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

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isGuide ? Colors.orange : Colors.green,
                      child: Icon(
                        isGuide ? Icons.map : Icons.chat,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      room['roomName'] ?? 'ไม่มีชื่อห้อง',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      room['lastMessage'] ?? 'ยังไม่มีข้อความ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
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
      appBar: AppBar(
        backgroundColor: isGuideUser
            ? Colors.amber.shade300
            : Colors.greenAccent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. ชื่อห้องแชต
            Text(
              widget.roomName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),

            // 2. ป้ายแสดงบทบาท (Badge)
          ],
        ),
        actions: [
          // 3. ปุ่มดูรายชื่อลูกทัวร์/สมาชิก แยกมาไว้ที่ actions
          if (isGuideUser)
            TextButton.icon(
              onPressed: () {
                // TODO: เปิด BottomSheet หรือ Dialog แสดงรายชื่อสมาชิก
                _showMembersList(context);
              },
              icon: const Icon(Icons.group, color: Colors.black87, size: 18),
              label: const Text(
                "ลูกทัวร์",
                style: TextStyle(color: Colors.black87, fontSize: 12),
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
                                    ? Colors.amber.shade200
                                    : Colors.greenAccent.shade200)
                              : (isGuideSender
                                    ? Colors.orange.shade100
                                    : Colors.grey.shade300),
                          border: isGuideSender
                              ? Border.all(
                                  color: Colors.orange.shade400,
                                  width: 1.5,
                                )
                              : null,
                          borderRadius: BorderRadius.circular(12),
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
                                    Icons.explore,
                                    size: 12,
                                    color: Colors.deepOrange,
                                  ),
                                  const SizedBox(width: 3),
                                  const Text(
                                    "[ไกด์] ",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepOrange,
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
            padding: const EdgeInsets.all(8),
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: isGuideUser ? Colors.orange : Colors.green,
                  ),
                  onPressed: _sendMessage,
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
                        children: [
                          Text(
                            "สมาชิกในทริป (${entries.length} คน)",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // ปุ่มพิมพ์ทั้งหมด (วางไว้ข้างหัวข้อ)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
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
                              isPrintingAll ? "กำลังเตรียม..." : "พิมพ์ทั้งหมด",
                            ),
                            onPressed: isPrintingAll
                                ? null
                                : () async {
                                    setStateModal(() => isPrintingAll = true);

                                    try {
                                      // ดึงข้อมูลสมาชิกทุกคน พร้อมระบุบทบาท (Role)
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
