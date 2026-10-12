import { Injectable } from '@angular/core';
import { initializeApp } from 'firebase/app';
import { 
  getDatabase, 
  ref, 
  onValue, 
  push, 
  set, 
  update, 
  query, 
  orderByChild 
} from 'firebase/database';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment.development';

export interface ChatRoom {
  roomId?: string;
  userId: string;
  userName?: string;
  userAvatar?: string;
  lastMessage?: string;
  lastUpdated?: number;
  unreadByAdmin?: number;
}

export interface ChatMessage {
  id?: string;
  senderType?: 'user' | 'admin';
  senderRole?: 'user' | 'admin';
  senderId?: string;
  text?: string;
  timestamp?: number;
}

@Injectable({
  providedIn: 'root'
})
export class AdminChatService {
  private app = initializeApp(environment.firebaseConfig);
  private db = getDatabase(this.app);

  /**
   * ใช้ room id 
   * - ปัจจุบัน: rooms/{userId} และ messages/{userId}
   * - Legacy: roomPrivate_{userId}
   *
   * จึงต้อง fallback เพื่อให้ chat แสดงได้ทั้งกรณีเก่าและใหม่
   */
  private getRoomPathId(id: string): string {
    if (!id) return '';
    return id;
  }

  // ดึงรายการห้องแชททั้งหมด (เรียงตามเวลาล่าสุด)
  getChatRooms(): Observable<ChatRoom[]> {
    return new Observable((observer) => {
      const roomsRef = query(ref(this.db, 'rooms'), orderByChild('lastUpdated'));
      
      const unsubscribe = onValue(roomsRef, (snapshot) => {
        const rooms: ChatRoom[] = [];
        snapshot.forEach((childSnapshot) => {
          const val = childSnapshot.val();
          const key = childSnapshot.key as string;

          rooms.push({
            roomId: val.roomId || key,
            userId: val.userId || key,
            ...val
          });
        });
        
        observer.next(rooms.reverse());
      }, (error) => {
        observer.error(error);
      });

      return () => unsubscribe();
    });
  }

  // ดึงข้อความสนทนาภายในห้อง
  getMessages(roomIdOrUserId: string): Observable<ChatMessage[]> {
    return new Observable((observer) => {
      const targetRoomIds = [this.getRoomPathId(roomIdOrUserId)];
      const legacyRoomId = roomIdOrUserId.startsWith('roomPrivate_') ? roomIdOrUserId : `roomPrivate_${roomIdOrUserId}`;
      if (legacyRoomId !== targetRoomIds[0]) {
        targetRoomIds.push(legacyRoomId);
      }

      const finalRef = ref(this.db, `messages/${targetRoomIds[0]}`);
      const unsubscribe = onValue(finalRef, (snapshot) => {
        const messages: ChatMessage[] = [];
        snapshot.forEach((childSnapshot) => {
          const value = childSnapshot.val() as Partial<ChatMessage>;
          messages.push({
            id: childSnapshot.key as string,
            ...value,
            senderType: value.senderType ?? value.senderRole ?? 'user',
          });
        });
        observer.next(messages);
      }, (error) => {
        observer.error(error);
      });

      return () => unsubscribe();
    });
  }

  // ส่งข้อความในนาม Admin
  async sendMessage(roomIdOrUserId: string, text: string, adminId: string = 'admin_01'): Promise<void> {
    const targetRoomId = this.getRoomPathId(roomIdOrUserId);
    const timestamp = Date.now();

    const messageData: ChatMessage = {
      senderType: 'admin',
      senderRole: 'admin',
      senderId: adminId,
      text: text,
      timestamp: timestamp
    };

    const newMessageRef = push(ref(this.db, `messages/${targetRoomId}`));
    await set(newMessageRef, messageData);

    const roomRef = ref(this.db, `rooms/${targetRoomId}`);
    await update(roomRef, {
      lastMessage: text,
      lastUpdated: timestamp,
      unreadByAdmin: 0
    });
  }

  // เคลียร์จำนวนข้อความยังไม่อ่าน
  async markAsRead(roomIdOrUserId: string): Promise<void> {
    const targetRoomId = this.getRoomPathId(roomIdOrUserId);
    const roomRef = ref(this.db, `rooms/${targetRoomId}`);
    await update(roomRef, { unreadByAdmin: 0 });
  }
}