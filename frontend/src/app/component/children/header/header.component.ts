import { Component } from '@angular/core';
import { AuthService } from '../../../services/auth.service';
import { SidebarModule } from 'primeng/sidebar';
import { CardModule } from 'primeng/card';
import { AvatarModule } from 'primeng/avatar';
import { TagModule } from 'primeng/tag';
import { CommonModule } from '@angular/common';
import { NavigationEnd, Router } from '@angular/router';
import { PermissionService } from '../../../services/permission.service';
@Component({
  selector: 'app-header',
  standalone: true,
  imports: [SidebarModule,CardModule,AvatarModule,TagModule,CommonModule],
  templateUrl: './header.component.html',
  styleUrl: './header.component.css'
})
export class HeaderComponent {

  
  constructor(private readonly authService: AuthService, private readonly router : Router, private readonly permission : PermissionService){
    this.router.events.subscribe(event => {
      if (event instanceof NavigationEnd) { 
       this.currentURL = this.router.url;
      }
    });
  }
  currentURL: string = ""
  user = this.authService.currentUserValue;
  sidebarVisible : boolean = false;

  get accessPermission(){
    return this.permission
  }
  
  navigate(url: string){
    this.router.navigateByUrl(url);
    this.sidebarVisible = false;
  }
}
