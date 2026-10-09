import { Routes } from '@angular/router';
import { Addtour } from './component/addtour/addtour';
import { AddGuide } from './component/addguide/addguide';
import { DashboardComponent } from './component/dashboard/dashboard.component';
import { MemberComponent } from './component/member-component/member-component';
import { ChatComponent } from './component/chat-component/chat-component';
export const routes: Routes = [
  { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
  { path: 'dashboard', component: DashboardComponent },
  { path: 'add-tour', component: Addtour },
  { path: 'add-guide', component: AddGuide },
  { path: 'members', component: MemberComponent },
  { path: 'members/:googleId', component: MemberComponent },
  { path: 'chat', component: ChatComponent },
  { path: '**', redirectTo: 'dashboard' },
];
