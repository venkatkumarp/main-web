import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { PermissionService } from '../services/permission.service';

/* Guard to validate user acess to route */
export const permissionGuard: CanActivateFn = (route, state) => {
  const permission = inject(PermissionService); 
  const router = inject(Router); 
  let role: any = route.data['role'];
  if(permission.canAccess(permission.taskList.read[role as keyof typeof permission.taskList.read])){
    return true;
  }else{
    return router.navigateByUrl('/accessdenied'); 
  }
};
