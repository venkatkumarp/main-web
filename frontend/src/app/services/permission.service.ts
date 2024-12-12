import { AuthService } from './auth.service';
import { matrix } from '../interface/matrix';
import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root',
})
export class PermissionService {
    
  constructor(private authService: AuthService) { }

  /* Task List as applicable in application */
  public taskList = {
    read:{
      sst: "ReadSST",
      bulkUpload: "ReadBulkUpload",
      xpwd: "ReadXPWD"
    },
    edit:{
      sst: "EditSST",
      bulkUpload: "EditBulkUpload",
      xpwd: "EditXPWD"
    }
  }

  /* Permission Matrix Role X Task */
  private permissionMatrix : matrix = {
    SSTUser : [
      this.taskList.read.sst,
      this.taskList.edit.sst
    ],
    bulkUploadUser: [
      this.taskList.read.bulkUpload,
      this.taskList.edit.bulkUpload
    ],
    XPWDUser : [
      this.taskList.read.xpwd,
      this.taskList.edit.xpwd
    ]
  }
  

  private validateAccess(task: string) : boolean{
    const loggedInUser = this.authService.currentUserValue;
    console.log("=>",loggedInUser, this.permissionMatrix)
    if (!loggedInUser) return false;

    
    return loggedInUser.roles.some((role : any) => this.permissionMatrix[role].includes(task))
  }

  /* 
  Public Method to Validate user access
    returns Boolean
  */
  public canAccess(task: string){
   
    if(this.validateAccess(task))
    return true

    return false
  }
}
