import { Component } from '@angular/core';
import { ControlContainer, FormControl, FormGroup, FormGroupDirective, FormsModule, ReactiveFormsModule } from '@angular/forms';
import { FloatLabelModule } from 'primeng/floatlabel';
import { InputTextModule } from 'primeng/inputtext';
import { CalendarModule } from 'primeng/calendar';
import { InputSwitchModule } from 'primeng/inputswitch';
import { CommonModule } from '@angular/common';
import { TooltipModule } from 'primeng/tooltip';
import { HttpClientModule } from '@angular/common/http';
@Component({
  selector: 'app-status',
  standalone: true,
  imports: [InputTextModule,ReactiveFormsModule,FloatLabelModule,CalendarModule,InputSwitchModule,FormsModule,CommonModule,TooltipModule,HttpClientModule],
  templateUrl: './status.component.html',
  styleUrl: './status.component.css',
  viewProviders: [{ provide: ControlContainer, useExisting: FormGroupDirective }]

})
export class StatusComponent {
  childForm: any;
  status: boolean = false;
  constructor(public parentForm: FormGroupDirective) {}

  tooltip: any = {
    end: `<b> Employee End Date </b><br><p style="text-align: left;">A given "Employee End Date" will initiate deactivation of the account. Afterwards the user is no longer able to log into the TimeTracking system. Also Timesheets can no longer be modified or entered. No further Timesheets will be created.<br><br>
To set an employee end date click into the field to activate the date picker and choose a date.<br><br>
It is resonable to choose a employee end date in the future or just the actual day. Any past date will also set the account inactive but already existing Timesheets will not be deleted.</p>`,
    start: `<b> Employee Start Date </b><br><p style="text-align: left;">The "Employee Start Date" will initiate the activation of an account on the given date. Afterwards the system will begin to create a new TimeSheet every week. To set an employee start date click into the field to activate the date picker and choose a date.</p>`,
    status: `<b> Active User </b><br><p style="text-align: left;">The Status of an Account is given here. To be able to log into the TimeTracking system the status needs to be "Active". For all active User a new Timesheet will be created every week. To change the status just check or uncheck the box.</p>`,
  }
  ngOnInit() {
    this.childForm = this.parentForm.form;
    this.childForm?.addControl(
      'statusData',
      new FormGroup({
        employeeEndDate: new FormControl(null),
        employeeStartDate: new FormControl(null),
        
      })
    );
    this.getStaus()
  }

  getStaus(){
    console.log(this.childForm.value.statusData)
    const startDateStr: string = this.childForm.value.statusData.employeeStartDate;
    const endDateStr: string = this.childForm.value.statusData.employeeEndDate;
    const startDate: Date = new Date(startDateStr);
    const endDate: Date = new Date(endDateStr);
    const now = new Date()
  if (!startDateStr && !endDateStr) {
    this.status = true
  }
  else if (!startDateStr && endDateStr) {
    this.status = (endDate > now)
  }
  else if (startDateStr && !endDateStr) {
    this.status = (startDate <= now)
  }
  else {
    this.status = ((startDate<= endDate) && (startDate<= now) && (endDate> now))
  }
  }
}
