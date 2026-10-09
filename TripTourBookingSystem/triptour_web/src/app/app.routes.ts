import { Routes } from '@angular/router';
import { Addtour } from './addtour/addtour';
import { AddGuide } from './addguide/addguide';
import { DashboardComponent } from './dashboard/dashboard.component';
import { MemberComponent } from './member-component/member-component';
import { ChatComponent } from './chat-component/chat-component';
import { ManageTour } from './manage-tour/manage-tour';
import { EditTour } from './edit-tour/edit-tour';
import { ManageRound } from './manage-round/manage-round';
import { BookingApproval } from './booking-approval/booking-approval';
export const routes: Routes = [
  { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
  { path: 'dashboard', component: DashboardComponent },
  { path: 'add-tour', component: Addtour },
  { path: 'add-guide', component: AddGuide },
  { path: 'members', component: MemberComponent },
  { path: 'chat', component: ChatComponent },
  { path: 'manage-tour', component: ManageTour },
  { path: 'edit-tour/:tourId', component: EditTour },
  { path: 'manage-round/:tourId', component: ManageRound },
  { path: 'booking-approval', component: BookingApproval },
  { path: '**', redirectTo: 'dashboard' },
];
