import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { ServerApi } from '../../server/server';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { AddGuide } from '../addguide/addguide';
@Component({
  selector: 'app-member-component',
  standalone: true,
  imports: [AddGuide, CommonModule, FormsModule, MatProgressSpinnerModule],
  templateUrl: './member-component.html',
  styleUrl: './member-component.css',
})
export class MemberComponent implements OnInit {
  private serverApi = inject(ServerApi);
  private cdr = inject(ChangeDetectorRef);
  private route = inject(ActivatedRoute);
  private router = inject(Router);

  members: any[] = [];
  selectedTab: 'all' | 'user' | 'guide' | 'history' | 'add-guide' | undefined   ;
  isLoading = false;
  errorMessage = '';
  selectedMember: any = null;
  editingGuide: any = null;

  guideForm = {
    first_name: '',
    last_name: '',
    phone: '',
    address: '',
    age: '',
    birthday: '',
    password: ''
  };

  get filteredMembers(): any[] {
    return this.members.filter((m) => {
      const suspended = this.isSuspended(m.status);
      if (this.selectedTab === 'history') return suspended;
      if (suspended) return false;

      if (this.selectedTab === 'user') return m.role === 'สมาชิก';
      if (this.selectedTab === 'guide') return m.role === 'ไกด์';
      return true;
    });
  }

  ngOnInit(): void {
  this.route.paramMap.subscribe((params) => {
    const googleId = params.get('googleId');
    this.loadAllData(); // โหลดรายการทั้งหมดเสมอ
    if (googleId) {
      this.viewMemberDetailById(googleId);
    }
  });
}

  async loadAllData(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const res = await this.serverApi.getDashboardData('member/allmember');
      if (res.statusCode === 200) {
        const rawData = Array.isArray(res.body) ? res.body : res.body?.data ?? [];
        this.members = rawData.map((m: any) => this.normalizeMember(m));
      } else {
        this.errorMessage = res.body?.message || 'เกิดข้อผิดพลาดในการโหลดข้อมูล';
      }
    } catch {
      this.errorMessage = 'ไม่สามารถติดต่อเซิร์ฟเวอร์ได้';
    } finally {
      this.isLoading = false;
      this.cdr.detectChanges();
    }
  }

  async toggleMemberStatus(member: any): Promise<void> {
    const nextStatus = this.isSuspended(member.status) ? 'active' : 'inactive';
    if (!confirm(`ยืนยันการ ${nextStatus === 'active' ? 'เปิดใช้งาน' : 'ระงับ'} บัญชีนี้?`)) return;

    const res = await this.serverApi.patchData(`member/status/${member.googleId}`, { status: nextStatus });
    if (res.statusCode === 200) {
      member.status = nextStatus;
      this.selectedTab = this.isSuspended(nextStatus) ? 'history' : 'all';
      await this.loadAllData();
    } else {
      this.errorMessage = res.body?.message || 'ไม่สามารถเปลี่ยนสถานะได้';
    }
  }

  viewMemberDetail(member: any): void {
    if (member?.googleId) this.router.navigate(['/members', member.googleId]);
  }

  async viewMemberDetailById(googleId: string): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const res = await this.serverApi.postData('member/detail', { targetUid: googleId });
      const detail = res.statusCode === 200 ? (res.body?.data ?? res.body) : null;

      if (!detail) {
        this.errorMessage = 'ไม่พบข้อมูลสมาชิกนี้';
        return;
      }

      let member = this.normalizeMember({ ...detail, google_id: detail.google_id ?? googleId });

      if (member.role === 'ไกด์') {
        const guideRes = await this.serverApi.getDashboardData(`add-guide/profile/${googleId}`);
        if (guideRes.statusCode === 200 && guideRes.body) {
          const guideData = guideRes.body?.data ?? guideRes.body;
          member = this.normalizeMember({ ...member, ...guideData, role: 'ไกด์' });
        }
      }
      this.selectedMember = member;
    } catch {
      this.errorMessage = 'ไม่สามารถดูข้อมูลคนนี้ได้';
    } finally {
      this.isLoading = false;
      this.cdr.detectChanges();
    }
  }

  openEditGuide(member: any): void {
    this.editingGuide = member;
    this.selectedMember = member;
    this.guideForm = {
      first_name: member.first_name || '',
      last_name: member.last_name || '',
      phone: member.phone || '',
      address: member.address || '',
      age: member.age || '',
      birthday: member.birthday || '',
      password: ''
    };
  }

  async saveGuideChanges(): Promise<void> {
  const cleanGoogleId = this.editingGuide?.googleId?.toString().trim();
  if (!cleanGoogleId) return;

  this.errorMessage = ''; // ล้างข้อความ Error เก่าออกก่อน

  try {
    const res = await this.serverApi.putData(`add-guide/profile/${cleanGoogleId}`, this.guideForm);

    if (res.statusCode === 200 || res.body?.success) {
      const updated = res.body?.data ?? res.body;
      const merged = this.normalizeMember({ ...this.editingGuide, ...updated, role: 'ไกด์' });

      const idx = this.members.findIndex((m) => m.googleId === cleanGoogleId);
      if (idx >= 0) {
        this.members[idx] = merged;
      }

      this.selectedMember = merged;
      this.editingGuide = null;

      // บังคับให้ Angular ตรวจสอบการเปลี่ยนแปลงการแสดงผล
      this.cdr.detectChanges();
    } else {
      this.errorMessage = res.body?.message || 'ไม่สามารถแก้ไขข้อมูลไกด์ได้';
    }
  } catch (error) {
    this.errorMessage = 'เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์';
  }
}
  closeHistoryView(): void {
    this.selectedMember = null;
    this.editingGuide = null;
    this.selectedTab = 'all';
    this.router.navigate(['/members']);
    this.loadAllData();
  }

  isSuspended(status: string | null | undefined): boolean {
    const s = String(status ?? '').toLowerCase();
    return s === 'inactive';
  }

  private normalizeMember(m: any): any {
    const isGuide = Boolean(m.guide_id || m.guide_code || m.role === 'guide' || m.role === 'ไกด์');
    return {
      id: m.member_id ?? m.guide_id ?? m.google_id ?? '-',
      displayName: `${m.first_name ?? ''} ${m.last_name ?? ''}`.trim() || 'ไม่มีชื่อ',
      role: isGuide ? 'ไกด์' : 'สมาชิก',
      email: m.email ?? m.member_email ?? '-',
      phone: m.phone ?? '-',
      status: m.status ?? 'active',
      code: m.guide_code ?? m.member_code ?? '-',
      googleId: m.google_id ?? '-',
      first_name: m.first_name ?? '',
      last_name: m.last_name ?? '',
      address: m.address ?? '',
      age: m.age ?? '',
      birthday: m.birthday ?? '',
    };
  }
}