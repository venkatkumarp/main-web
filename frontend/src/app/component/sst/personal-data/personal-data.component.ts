import { Component } from '@angular/core';
import { ControlContainer, FormControl, FormGroup, FormGroupDirective, FormsModule, ReactiveFormsModule } from '@angular/forms';
import { InputTextModule } from 'primeng/inputtext';
import { InputGroupModule } from 'primeng/inputgroup';
import { InputGroupAddonModule } from 'primeng/inputgroupaddon';
import { FloatLabelModule } from 'primeng/floatlabel';
import { TooltipModule } from 'primeng/tooltip';
import { InputSwitchModule } from 'primeng/inputswitch';
import { AutoCompleteModule } from 'primeng/autocomplete';
import { APIService } from '../../../services/api.service';
import { HighlightPipe } from '../../../pipe/highlight.pipe';
import { CommonModule } from '@angular/common';
import { HttpClientModule } from '@angular/common/http';
@Component({
  selector: 'app-personal-data',
  standalone: true,
  imports: [FormsModule,InputTextModule,ReactiveFormsModule,InputGroupModule,InputGroupAddonModule,FloatLabelModule,TooltipModule,InputSwitchModule,AutoCompleteModule,HighlightPipe,CommonModule,HttpClientModule],
  templateUrl: './personal-data.component.html',
  styleUrl: './personal-data.component.css',
  viewProviders: [{ provide: ControlContainer, useExisting: FormGroupDirective }]
})
export class PersonalDataComponent  {
  // personalDataFormGroup: FormGroup = this.fb.group({
  //   name: null,
  //   email: null
  // });

    childForm: any;
  companySuggestion: string[] = [];
  companyHighlight: any;
  roleHighlight: any;
  roleSuggestion: string[] = [];
  Roles: string[] = [];
    constructor(public parentForm: FormGroupDirective, private readonly api: APIService) {}
    ngOnInit() {
      this.childForm = this.parentForm.form;
      this.childForm.addControl(
        'personalDataFormGroup',
        new FormGroup({
          name: new FormControl(null),
          emailAddress: new FormControl(null),
          externalFlag: new FormControl(null),
          cwid: new FormControl(null),
          hoursWeek: new FormControl(null),
          company: new FormControl(null),
          roles: new FormControl(null),
        })
      );
    }

    tooltip : any = {
      email: '<b> E-Mail </b><br><p style="text-align: left;">It is not possible to change an E-Mail Address within SST. If necessary please contact TimeTracking Support Team: support.timetracking@bayer.com</p>',
      externalflag: '<b> External Flag </b><br><p style="text-align: left;">Please check this box in case the User is with an external contractor.</p>',
      cwid: '<b> CWID </b><br><p style="text-align: left;">It is not possible to change the CWID within SST. If necessary please contact TimeTracking Support Team: support.timetracking@bayer.com</p>',
      company: '<b> Company </b><br><p style="text-align: left;">If the user is with an external contractor please add the company here. While typing there will be a list of similar matches, so you can also just pick the right match.</p>',
      hour: '<b> Hours per week </b><br><p style="text-align: left;">Please give the amount of working hours per week ( between 1 and 48 hours). Please use a dot as decimal seperator if necessary</p>',
      role: '<b> Add Role here </b><br><p style="text-align: left;">Assigning Roles to an Account is crucial to enable Projects / Studies as well as activities to a Users TimeTracking Account. It is possible to assign multiple Roles to an account. Please note at least one Role is mandatory. Excisting Roles also can be deleted by clicking the listed Roles name. Adding new Roles is possible by using the ADD ROLE picker.</p>'
    }
    searchCompany(event: any){
      this.companyHighlight = event.query
      this.api.getCompany().subscribe(res =>{
        this.companySuggestion = res.filter(e => e.toLowerCase().includes(event.query.toLowerCase()))
      })
    }

    searchRole(event: any){
      this.roleHighlight = event.query;
      this.api.getRoles(event.query).subscribe(res =>{
        this.roleSuggestion = res;
      })
    }

    roleSelected(event: any){
      if(event.value){
        this.Roles.push(event.value);
      }
    }
}
