import { HttpClientModule } from '@angular/common/http';
import { Component } from '@angular/core';
import { ReactiveFormsModule } from '@angular/forms';
import { RouterOutlet, RouterLink, RouterLinkActive } from '@angular/router';
// import { DashboardComponent } from './dashboard/dashboard.component';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatSidenavModule } from '@angular/material/sidenav';
import { MatListModule } from '@angular/material/list';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
@Component({
  selector: 'app-root',
  standalone: true,
  imports: [
    RouterOutlet,
    HttpClientModule,
    ReactiveFormsModule,
    RouterLink,
    RouterLinkActive,
    MatToolbarModule,
    MatSidenavModule,
    MatListModule,
    MatIconModule,
    MatButtonModule
  ],
  templateUrl: './app.html',
  styleUrl: './app.css',
})
export class App {
  protected title = 'triptour_web';
}
