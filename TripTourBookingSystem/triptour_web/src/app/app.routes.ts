import { Routes } from '@angular/router';
import { Addtour } from './component/addtour/addtour';
import { AddGuide } from './component/addguide/addguide';
import { DashboardComponent } from './component/dashboard/dashboard.component';
import { MemberComponent } from './component/member-component/member-component';
import { ChatComponent } from './component/chat-component/chat-component';
import { ManageTour } from './component/manage-tour/manage-tour';
import { EditTour } from './component/edit-tour/edit-tour';
import { ManageRound } from './component/manage-round/manage-round';
import { BookingApproval } from './booking-approval/booking-approval';
import { MemberListComponent } from './component/manage-round/member-list/member-list.component';
import { AdminLoginComponent } from './admin-login/admin-login.component';
import { adminGuard } from './admin-auth.guard';

export const routes: Routes = [
  { path: '', redirectTo: 'login', pathMatch: 'full' },
  { path: 'login', component: AdminLoginComponent },
  { path: 'dashboard', component: DashboardComponent, canActivate: [adminGuard] },
  { path: 'add-tour', component: Addtour, canActivate: [adminGuard] },
  { path: 'add-guide', component: AddGuide, canActivate: [adminGuard] },
  { path: 'members', component: MemberComponent, canActivate: [adminGuard] },
  { path: 'members/:googleId', component: MemberComponent, canActivate: [adminGuard] },
  { path: 'chat', component: ChatComponent, canActivate: [adminGuard] },
  { path: 'manage-tour', component: ManageTour, canActivate: [adminGuard] },
  { path: 'edit-tour/:tourId', component: EditTour, canActivate: [adminGuard] },
  { path: 'manage-round/:tourId', component: ManageRound, canActivate: [adminGuard] },
  { path: 'booking-approval', component: BookingApproval, canActivate: [adminGuard] },
  { path: 'memberlist-roundtour/:roundId', component: MemberListComponent, canActivate: [adminGuard] },
  { path: '**', redirectTo: 'login' },
];
