import { Component } from '@angular/core';
import { ControlContainer, FormControl, FormGroup, FormGroupDirective, ReactiveFormsModule } from '@angular/forms';
import { AutoCompleteModule } from 'primeng/autocomplete';
import { FloatLabelModule } from 'primeng/floatlabel';
import { InputTextModule } from 'primeng/inputtext';
import { HighlightPipe } from '../../../pipe/highlight.pipe';
import { AvatarModule } from 'primeng/avatar';
import { APIService } from '../../../services/api.service';
import { TooltipModule } from 'primeng/tooltip';
import { HttpClientModule } from '@angular/common/http';

@Component({
  selector: 'app-business-unit',
  standalone: true,
  imports: [InputTextModule,ReactiveFormsModule,AutoCompleteModule,FloatLabelModule,HighlightPipe,AvatarModule,TooltipModule,HttpClientModule],
  templateUrl: './business-unit.component.html',
  styleUrl: './business-unit.component.css',
  viewProviders: [{ provide: ControlContainer, useExisting: FormGroupDirective }]
})
export class BusinessUnitComponent {
  childForm: any;
  ccHighlight: any;
  costCenterSuggestion: any[] = [];
  subsubFnHighlight: any;
  ccSelected: any;
  subsubFnSuggestion: any[] = [];
  constructor(public parentForm: FormGroupDirective, private readonly api: APIService) {}
  ngOnInit() {
    this.childForm = this.parentForm.form;
    this.childForm.addControl(
      'businessUnitData',
      new FormGroup({
        costCenter: new FormControl(null),
        country: new FormControl(null),
        legalEntity: new FormControl(null),
        topFunction: new FormControl(null),
        function: new FormControl(null),
        subFunction: new FormControl(null),
        subSubFunction: new FormControl(null),
        
      })
    );
  }

  tooltip: any ={
    costcenter: `<b> Cost Center </b><br><p style="text-align: left;">A Business Unit is defined by the CostCenter. A Cost Center can be picked by typing the CostCenters name or any term from the CostCenter details, e.g. country.<br><br>Just start typing. A list of matching Cost Center will appear. To choose an account click it</p>`,
    country: `<b> Country </b><br><p style="text-align: left;">This field will be filled automatically after entering a Cost Center.</p>`,
    legal: `<b> Legal Entity </b><br><p style="text-align: left;">This field will be filled automatically after entering a Cost Center.</p>`,
    topfn: `<b> Top Function </b><br><p style="text-align: left;">This field will be filled automatically after entering a Cost Center.</p>`,
    fn: `<b> Function </b><br><p style="text-align: left;">This field will be filled automatically after entering a Cost Center.</p>`,
    subfn: `<b> Sub Function </b><br><p style="text-align: left;">This field will be filled automatically after entering a Cost Center.</p>`,
    subsubfn: `<b> Sub Sub Function </b><br><p style="text-align: left;">This field is optional. It is possible to add further Business Unit details. If there are already excisting Sub Sub Functions entered for your Business Unit they will appear while typing. Therefore a CostCenter have to be entered first.</p>`,
  }
  costCenterSearch(event:any){
    this.ccHighlight = event.query;
    this.api.getCostCenter(event.query).subscribe(res => {
      this.costCenterSuggestion = res
    })
  }

  getInitials(fullName: string) {
    return fullName
      .split(', ')
      .map((x: string) => x.charAt(0))
      .join('')
  }
  costCenterSelected(event:any){
    console.log(event);
    this.ccSelected = event.value.costCenter;
    this.childForm.patchValue({businessUnitData:{... event.value}})
  }

  searchsubsubFn(event: any){
    if(this.ccSelected){
      this.subsubFnHighlight = event.query;
      this.api.getSubSubFunction(this.ccSelected).subscribe(res => {
        this.subsubFnSuggestion = res;
      })
    }
    
  }
}
