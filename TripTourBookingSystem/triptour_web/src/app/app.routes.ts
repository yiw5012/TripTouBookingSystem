import { Routes } from '@angular/router';
import { Addtour } from './addtour/addtour';
import { AddGuide } from './addguide/addguide';

export const routes: Routes = [
    { path: 'add-tour', component: Addtour },
    { 
    path: 'add-guide', component: AddGuide }
];
