import { Routes } from '@angular/router';
import { Addtour } from './addtour/addtour';
import { AddGuide } from './addguide/addguide';
import { DashboardComponent } from './dashboard/dashboard.component';

export const routes: Routes = [
  { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
  { path: 'dashboard', component: DashboardComponent },
  { path: 'add-tour', component: Addtour },
  { path: 'add-guide', component: AddGuide },
  { path: '**', redirectTo: 'dashboard' },
];
