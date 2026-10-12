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
export const routes: Routes = [
  { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
  { path: 'dashboard', component: DashboardComponent },
  { path: 'add-tour', component: Addtour },
  { path: 'add-guide', component: AddGuide },
  { path: 'members', component: MemberComponent },
  { path: 'members/:googleId', component: MemberComponent },
  { path: 'chat', component: ChatComponent },
  { path: 'manage-tour', component: ManageTour },
  { path: 'edit-tour/:tourId', component: EditTour },
  { path: 'manage-round/:tourId', component: ManageRound },
  { path: 'booking-approval', component: BookingApproval },
  {path: 'memberlist-roundtour/:roundId', component: MemberListComponent},
  { path: '**', redirectTo: 'dashboard' },
];
