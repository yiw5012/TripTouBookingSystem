import { Injectable } from '@angular/core';
import { initializeApp } from 'firebase/app';
import { 
  getDatabase, 
  ref, 
  onValue, 
  push, 
  set, 
  update, 
  get,
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

  private getRoomCandidates(id: string): string[] {
    if (!id) return [];

    const normalized = String(id).trim();
    if (!normalized) return [];

    const candidates = [normalized];

    if (normalized.startsWith('roomPrivate_')) {
      candidates.push(normalized.replace(/^roomPrivate_/, ''));
    } else {
      candidates.push(`roomPrivate_${normalized}`);
    }

    return [...new Set(candidates.filter(Boolean))];
  }

  private isRoundRoom(roomId: string, roomValue: any): boolean {
    if (!roomId) return true;
    if (roomId.startsWith('round_')) return true;
    if (typeof roomValue?.roundId !== 'undefined' && roomValue?.members) return true;
    return false;
  }

  private async resolveWritableRoomId(roomIdOrUserId: string): Promise<string> {
    const candidates = this.getRoomCandidates(roomIdOrUserId);

    for (const candidate of candidates) {
      const snap = await get(ref(this.db, `rooms/${candidate}`));
      if (snap.exists()) {
        return candidate;
      }
    }

    return candidates[0] || roomIdOrUserId;
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

          if (this.isRoundRoom(key, val)) {
            return;
          }

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
      const targetRoomIds = this.getRoomCandidates(roomIdOrUserId);
      const snapshots = new Map<string, ChatMessage[]>();
      const unsubscribers: Array<() => void> = [];

      const emitMessages = () => {
        for (const roomId of targetRoomIds) {
          const candidate = snapshots.get(roomId) || [];
          if (candidate.length > 0) {
            observer.next(candidate);
            return;
          }
        }

        observer.next([]);
      };

      targetRoomIds.forEach((roomId) => {
        const roomMessagesRef = ref(this.db, `messages/${roomId}`);
        const unsubscribe = onValue(roomMessagesRef, (snapshot) => {
          const messages: ChatMessage[] = [];
          snapshot.forEach((childSnapshot) => {
            const value = childSnapshot.val() as Partial<ChatMessage>;
            messages.push({
              id: childSnapshot.key as string,
              ...value,
              senderType: value.senderType ?? value.senderRole ?? 'user',
            });
          });
          snapshots.set(roomId, messages);
          emitMessages();
        }, (error) => {
          observer.error(error);
        });

        unsubscribers.push(unsubscribe);
      });

      return () => {
        unsubscribers.forEach((unsubscribe) => unsubscribe());
      };
    });
  }

  // ส่งข้อความในนาม Admin
  async sendMessage(roomIdOrUserId: string, text: string, adminId: string = 'admin_01'): Promise<void> {
    const targetRoomId = await this.resolveWritableRoomId(roomIdOrUserId);
    const timestamp = Date.now();
    const roomSnapshot = await get(ref(this.db, `rooms/${targetRoomId}`));
    const roomData = roomSnapshot.exists() ? roomSnapshot.val() : {};
    const defaultUserId = targetRoomId.startsWith('roomPrivate_')
      ? targetRoomId.replace(/^roomPrivate_/, '')
      : targetRoomId;

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
      roomId: roomData?.roomId || targetRoomId,
      userId: roomData?.userId || defaultUserId,
      type: roomData?.type || 'admin_support',
      createdAt: roomData?.createdAt || timestamp,
      lastMessage: text,
      lastUpdated: timestamp,
      unreadByAdmin: 0
    });
  }

  // เคลียร์จำนวนข้อความยังไม่อ่าน
  async markAsRead(roomIdOrUserId: string): Promise<void> {
    const targetRoomId = await this.resolveWritableRoomId(roomIdOrUserId);
    const roomRef = ref(this.db, `rooms/${targetRoomId}`);
    await update(roomRef, { unreadByAdmin: 0 });
  }
}