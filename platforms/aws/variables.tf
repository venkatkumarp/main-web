variable "aws_account_id" {
  type        = string
  description = "Account ID AWS"
}

variable "client_secret" {}

variable "code_verifier" {}

variable "code_challenge" {}

#variable "commit_id" {}

#cwid db details
#variable "db_server" {}
#variable "database_name" {}
#variable "db_user" {}
#variable "db_password" {}
#variable "db_driver" {}

variable "CWID_DB_SERVER" {} 
variable "CWID_DATABASE" {}  
variable "CWID_DB_USERNAME" {}
variable "CWID_DB_PASSWORD" {}
variable "CWID_DB_DRIVER" {}

# joutnyx details
variable "JXURL" {}
variable "JOURNYX_USER" {}
variable "JOURNYX_PASSWORD" {}

#SAP details
variable "sapuser" {}
variable "sapid" {}
