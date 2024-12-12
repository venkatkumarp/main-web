import { Component } from '@angular/core';
import { ControlContainer, FormControl, FormGroup, FormGroupDirective, ReactiveFormsModule } from '@angular/forms';
import { FloatLabelModule } from 'primeng/floatlabel';
import { InputTextModule } from 'primeng/inputtext';
import { APIService } from '../../../services/api.service';
import { AutoCompleteModule } from 'primeng/autocomplete';
import { HighlightPipe } from '../../../pipe/highlight.pipe';
import { InputSwitchModule } from 'primeng/inputswitch';
import { AvatarModule } from 'primeng/avatar';
import { TooltipModule } from 'primeng/tooltip';
import { HttpClientModule } from '@angular/common/http';

@Component({
  selector: 'app-line-management',
  standalone: true,
  imports: [InputTextModule,ReactiveFormsModule,FloatLabelModule,AutoCompleteModule,HighlightPipe,InputSwitchModule,AvatarModule,TooltipModule,HttpClientModule],
  templateUrl: './line-management.component.html',
  styleUrl: './line-management.component.css',
  viewProviders: [{ provide: ControlContainer, useExisting: FormGroupDirective }]
})
export class LineManagementComponent {
  childForm: any;
  companyHighlight: any;
  supervisorSuggestion: any[] = [];
  supervisorHighlight: any;
  backupHighlight: any;
  backupSuggestion: any[] = [];
  timeAssist2Highlight: any;
  timeAssistHighlight: any;
  timeAssistSuggestion: any[] = [];
  timeAssist2Suggestion: any[] = [];
  constructor(public parentForm: FormGroupDirective, private readonly api: APIService) {}

  tooltip: any = {
    selfapprover : '<b> Selfapprover </b><br><p style="text-align: left;">A Selfapprover is able to approve her / his own TimeSheets. To allow a user to do so please check the Box "Selfapprover". Also add the CWID of the Selfapprover User as Supervisor.<br><br> This change will take 24h until it becomes effective. Please note this new approval line is relevant only for those timesheets submitted after this change.</p>',
    supervisor : '<b> Supervisor </b><br><p style="text-align: left;">A Supervisor is responsible to check Timesheets of this user for accuracy and consistency. She / he approves or rejects Timesheets and is able to run a report for this user. <br><br> A Supervisor needs to be a active TimeTracking User. <br><br> This change will take 24h until it becomes effective. Please note this new approval line is relevant only for those timesheets submitted after this change. <br><br> To choose a Supervisor just start typing. A list of matching accounts will appear. To choose an account just click it. "Supervisor" is a mandatory field.</p>',
    backup : `<b> Backup Approver </b><br><p style="text-align: left;">The Backup Approver is the Supervisors deputy. She / he is also able to approve / reject Timesheets.<br><br> To nominate a Backup Approver it is necessary to add one in the Account of the Supervisor one should deputize. So it is not possible to add a Backup Approver induvidual for every TimeTracking User. If there is no Backup Approver listed the Supervisor of the Supervisor is automatically acting as Backup Approver.<br><br>To choose a Backup Approver just start typing. A list of matching accounts will appear. To choose an account just click it.<br><br>This change will take 24h until it becomes effective. Please note this new approval line is relevant only for those timesheets submitted after this change.</p>`,
    ttassist : `<b> Timekeeping Assistant </b><br><p style="text-align: left;">The Timekeeping Assistants are nominated by the Supervisor. They are able to view, log and change hours or submit Timesheets for subordinates of a Supervisor. All submissions of a Timekeeping Assistant on behalf of a User are tracked. Reports within the TimeTracking application for Supervisor's group can also be executed by the Timekeeping Assistant.<br><br>To choose a Timekeeping Assistant just start typing. A list of matching accounts will appear. To choose an account just click it</p>`,
    ttassist2 : `<b> Timekeeping Assistant 2 </b><br><p style="text-align: left;">The Timekeeping Assistants are nominated by the Supervisor. They are able to view, log and change hours or submit Timesheets for subordinates of a Supervisor. All submissions of a Timekeeping Assistant on behalf of a User are tracked. Reports within the TimeTracking application for Supervisor's group can also be executed by the Timekeeping Assistant.<br><br>To choose a Timekeeping Assistant just start typing. A list of matching accounts will appear. To choose an account just click it</p>`,
  }
  ngOnInit() {
    this.childForm = this.parentForm.form;
    this.childForm.addControl(
      'lineManagementData',
      new FormGroup({
        selfApprover: new FormControl(null),
        supervisorId: new FormControl(null),
        backupId: new FormControl(null),
        timekeepingAssistantId: new FormControl(null),
        timekeepingAssistant2Id: new FormControl(null),
        
      })
    );
  }

  autoCompleteSearch(event: any,type:string){
    
    this.api.searchByEmail(event.query).subscribe(
      res => {
        switch (type) {
          case 'supervisorId':
            this.supervisorHighlight = event.query;
            this.supervisorSuggestion=res;
            break;
        
          case 'backupId':
            this.backupHighlight = event.query;
            this.backupSuggestion = res;          
            break;
          case 'timekeepingAssistantId':
            this.timeAssistHighlight = event.query;
            this.timeAssistSuggestion = res;          
            break;
          case 'timekeepingAssistant2Id':
            this.timeAssist2Highlight = event.query;
            this.timeAssist2Suggestion = res;          
            break;
                  
          default:
            break;
        }
        
        
      }
    )
  }
  getInitials(fullName: string) {
    return fullName
      .split(', ')
      .map((x: string) => x.charAt(0))
      .join('')
  }
}
