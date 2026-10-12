import {
  Component,
  OnInit,
  OnDestroy,
  inject,
  ChangeDetectorRef,
  ViewChild,
  ElementRef,
  AfterViewChecked
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Subscription } from 'rxjs';
import { AdminChatService, ChatRoom, ChatMessage } from '../../server/service-chat';

@Component({
  selector: 'app-chat',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './chat-component.html',
  styleUrls: ['./chat-component.css']
})
export class ChatComponent implements OnInit, OnDestroy, AfterViewChecked {
  private chatService = inject(AdminChatService);
  private cdr = inject(ChangeDetectorRef);

  @ViewChild('messageList') private messageListContainer?: ElementRef<HTMLElement>;

  rooms: ChatRoom[] = [];
  messages: ChatMessage[] = [];
  selectedRoom: ChatRoom | null = null;
  newMessageText = '';

  private shouldScrollToBottom = false;
  private isFirstLoad = true;
  private roomsSub?: Subscription;
  private messagesSub?: Subscription;

  ngOnInit(): void {
    this.roomsSub = this.chatService.getChatRooms().subscribe({
      next: (rooms) => {
        this.rooms = [...rooms].sort((a, b) => (b.lastUpdated ?? 0) - (a.lastUpdated ?? 0));

        if (!this.selectedRoom && this.rooms.length > 0) {
          this.selectRoom(this.rooms[0]);
          return;
        }

        this.cdr.detectChanges();
      },
      error: (err) => console.error('Error loading rooms:', err)
    });
  }

  ngAfterViewChecked(): void {
    if (this.shouldScrollToBottom) {
      this.scrollToBottom();
      this.shouldScrollToBottom = false;
    }
  }

  // ใช้เช็คห้องที่เลือกใน template ได้ถ้าต้องการ
  private getRoomKey(room: ChatRoom | null): string {
    return room ? (room.roomId || room.userId || '') : '';
  }

  selectRoom(room: ChatRoom): void {
    const targetId = room.roomId || room.userId;
    if (this.getRoomKey(this.selectedRoom) === targetId) return;

    this.selectedRoom = room;
    this.messages = [];
    this.isFirstLoad = true; // เปิดห้องใหม่ = เลื่อนทันที ไม่ต้อง smooth

    this.chatService.markAsRead(targetId);
    this.messagesSub?.unsubscribe();

    this.messagesSub = this.chatService.getMessages(targetId).subscribe({
      next: (messages) => {
        this.messages = messages;
        this.shouldScrollToBottom = true;
        this.cdr.detectChanges();
        this.chatService.markAsRead(targetId); // ข้อความใหม่ระหว่างเปิดห้อง = อ่านแล้ว
      },
      error: (err) => console.error('Error loading messages:', err)
    });
  }

  async onSendMessage(): Promise<void> {
    if (!this.selectedRoom || !this.newMessageText.trim()) return;

    const targetId = this.selectedRoom.roomId || this.selectedRoom.userId;
    const textToSend = this.newMessageText.trim();
    this.newMessageText = '';

    try {
      await this.chatService.sendMessage(targetId, textToSend, 'admin_01');
      this.shouldScrollToBottom = true;
      this.cdr.detectChanges();
    } catch (error) {
      console.error('Error sending message:', error);
      this.newMessageText = textToSend;
      alert('ไม่สามารถส่งข้อความได้ กรุณาตรวจสอบการเชื่อมต่อ');
    }
  }

  trackByMessage(index: number, m: ChatMessage): any {
    return (m as any).id ?? m.timestamp ?? index;
  }

  private scrollToBottom(): void {
    const el = this.messageListContainer?.nativeElement;
    if (!el) return;

    requestAnimationFrame(() => {
      el.scrollTo({
        top: el.scrollHeight,
        behavior: this.isFirstLoad ? 'auto' : 'smooth'
      });
      if (this.messages.length > 0) this.isFirstLoad = false;
    });
  }

  ngOnDestroy(): void {
    this.roomsSub?.unsubscribe();
    this.messagesSub?.unsubscribe();
  }
}