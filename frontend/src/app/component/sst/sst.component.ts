import { Component, ViewEncapsulation } from '@angular/core';
import { FormBuilder, FormGroup, FormsModule, ReactiveFormsModule }   from '@angular/forms';
import { PermissionService } from '../../services/permission.service';
import { CommonModule } from '@angular/common';
import { APIService } from '../../services/api.service';
import { AutoCompleteModule } from 'primeng/autocomplete';
import { AvatarModule } from 'primeng/avatar';
import { HighlightPipe } from '../../pipe/highlight.pipe';
import { PersonalDataComponent } from './personal-data/personal-data.component';
import { LineManagementComponent } from './line-management/line-management.component';
import { BusinessUnitComponent } from './business-unit/business-unit.component';
import { StatusComponent } from './status/status.component';
import { ProgressSpinnerModule } from 'primeng/progressspinner';
import { HttpClientModule } from '@angular/common/http';
@Component({
  selector: 'app-sst',
  standalone: true,
  imports: [CommonModule,AutoCompleteModule,FormsModule,AvatarModule,HighlightPipe,PersonalDataComponent,LineManagementComponent,BusinessUnitComponent,StatusComponent,ReactiveFormsModule,ProgressSpinnerModule,HttpClientModule],
  templateUrl: './sst.component.html',
  styleUrl: './sst.component.css',
  encapsulation: ViewEncapsulation.None
})
export class SstComponent{
  toHighlight: any;
  headingDefault: string = "Start with choosing an account";
  heading: string = this.headingDefault;
  isLoading: boolean = false;
  sstFormGroup: FormGroup  = this.fb.group({
    personalDataFormGroup: this.fb.group({
      name: '',
      emailAddress: '',
      externalFlag: 'no',
      cwid: '',
      hoursWeek: '',
      company: '',
      roles: [],
    }),
    lineManagementData: this.fb.group({
      selfApprover: 'no',
      supervisorId: '',
      backupId: '',
      timekeepingAssistantId: '',
      timekeepingAssistant2Id: '',
    }),
    businessUnitData: this.fb.group({
      costCenter: '',
      country: '',
      legalEntity: '',
      topFunction: '',
      function: '',
      subFunction: '',
      subSubFunction: '',
    }),
    statusData: this.fb.group({
      employeeStartDate: '',
      employeeEndDate: ''
    })
  });
  detailsLoaded: boolean = false;

  constructor(private readonly permission : PermissionService, private readonly api : APIService,private readonly fb: FormBuilder){
  }

  
  selectedAccount: string = "";
  filteredAccount: any[] = [];

  get accessPermission(){
    return this.permission
  }

  autoCompleteSearch(event: any){
    this.toHighlight = event.query;
    this.api.searchByEmail(event.query).subscribe(
      res => {
        console.log(res);
        this.filteredAccount=res;
      }
    )
  }

  getInitials(fullName: string) {
    return fullName
      .split(', ')
      .map((x: string) => x.charAt(0))
      .join('')
  }

  onSubmit(){
    if (this.sstFormGroup.valid) {
      console.log(this.sstFormGroup.value);
    }
  }
  loadUserDetails(event:any){
    this.isLoading = true
    console.log(event)
    this.api.getUserData(event.value.email).subscribe(res =>{
      this.heading = res[0].fullName;
      this.sstFormGroup.patchValue({personalDataFormGroup: {... res[0]}})
      this.sstFormGroup.patchValue({lineManagementData: {... res[0]}})
      this.sstFormGroup.patchValue({businessUnitData: {... res[0]}})
      this.sstFormGroup.patchValue({statusData: {... res[0]}})
      this.detailsLoaded = true;
      this.isLoading = false
    })
  }

  cancel(){
    this.detailsLoaded = false;
    this.heading = this.headingDefault;
  }
}
