import { Routes } from '@angular/router';
import { Addtour } from './addtour/addtour';
import { AddGuide } from './addguide/addguide';
import { DashboardComponent } from './dashboard/dashboard.component';
import { MemberComponent } from './member-component/member-component';
import { ChatComponent } from './chat-component/chat-component';
export const routes: Routes = [
  { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
  { path: 'dashboard', component: DashboardComponent },
  { path: 'add-tour', component: Addtour },
  { path: 'add-guide', component: AddGuide },
  { path: 'members', component: MemberComponent },
  { path: 'chat', component: ChatComponent },
  { path: '**', redirectTo: 'dashboard' },
];
