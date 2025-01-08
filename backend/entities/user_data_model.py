from typing import Optional
from pydantic import BaseModel, Field
from typing import List

class JournyxUserAttributes(BaseModel):
    # id: str
      title:str
      emailAddress: str
      cwid: str
      company: str
      hoursWeek:int
      roles:[]
      country: str
      legalEntity:str
      topFunction:str
      subFunction:str
      subSubFunction:str
      backupId: int
      timekeepingAssistantId: str
      timekeepingAssistant2Id: str
      employeeStartDate: str
      employeeEndDate: str
      backupApprover:str
      costCenter: str
      employeeType: str
      externalFlag: int
      function: str
      supervisorFlag: str
      supervisorId: str
      fullName:str
      isExistingUser:str
    # team_skills: str
    # user_bill_rate_type: str
    # user_overhead_percent: str
    # user_pay_rate_type: int
    # user_work_hours_per_week: str

class JournyxUserAttributesList(BaseModel):
    userAttributes: List[JournyxUserAttributes]


class CostCenterDetails(BaseModel):
  cost_center: str
  legal_entity: str
  function: str
  sub_function: str
  sub_sub_function: str
  country: str

class CostCenterDetailsList(BaseModel):
  ccDetails: List[CostCenterDetails]

class search_user(BaseModel):
    full_name: str
    email_address: str
    cwid: str
    status:str

class search_user_with_mail(BaseModel):
  full_name: str
  email_address: str
  cwid: str
  companyName: str