import { RouterModule, Routes } from '@angular/router';
import { SstComponent } from './component/sst/sst.component';
import { BulkuploadComponent } from './component/bulkupload/bulkupload.component';
import { XpwdComponent } from './component/xpwd/xpwd.component';
import { NgModule } from '@angular/core';
import { LandingComponent } from './component/landing/landing.component';
import { AccessdeniedComponent } from './component/children/accessdenied/accessdenied.component';
import { permissionGuard } from './guards/permission.guard';

export const routes: Routes = [
    {
        path:'sst',
        loadComponent: () => import('./component/sst/sst.component').then(m => m.SstComponent),
        canActivate: [permissionGuard],
        data:{role:'sst'}
    },{
        path:'bulkupload',
        loadComponent: () => import('./component/bulkupload/bulkupload.component').then(m => m.BulkuploadComponent),
        canActivate: [permissionGuard],
        data:{role:'bulkUpload'}
    },{
        path:'xpwd',
        loadComponent: () => import('./component/xpwd/xpwd.component').then(m => m.XpwdComponent),
        canActivate: [permissionGuard],
        data:{role:'xpwd'}
    },{
        path:'accessdenied',
        component: AccessdeniedComponent
    },{
        path:'',
        component: LandingComponent
    }
];

@NgModule({ 
    imports: [RouterModule.forRoot(routes, {
    })],
    exports: [RouterModule]
  })

  export class AppRoutingModule { }