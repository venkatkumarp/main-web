import json
import pyodbc
import requests
from repositories.fetch_update_user_data import get_user_info_from_jx
from utils import utility_file

DRIVER = utility_file.get_secret_cwiddb().get('DRIVER')
SERVER = utility_file.get_secret_cwiddb().get('SERVER')
DATABASE = utility_file.get_secret_cwiddb().get('DATABASE')
USERNAME = utility_file.get_secret_cwiddb().get('USERNAME')
PASSWORD = utility_file.get_secret_cwiddb().get('PASSWORD')


def get_dummy_user():
    # user=search_user()
    # user.cwid=
    # dummy data
    user1 = dict()
    user1["fullName"] = "Test Users1"
    user1["title"] = "TESTCIWID1"
    user1["status"] = "0"
    user1["email"] = "test_user1@bayer.com"

    user2 = dict()
    user2["fullName"] = "Test Users2"
    user2["title"] = "TESTCIWID2"
    user2["status"] = "0"
    user2["email"] = "test_user2@bayer.com"

    user3 = dict()
    user3["fullName"] = "Test Users3"
    user3["title"] = "TESTCIWID3"
    user3["status"] = "0"
    user3["email"] = "test_user3@bayer.com"

    SSTAutoCompleteUsers = []
    SSTAutoCompleteUsers.append(user1)
    SSTAutoCompleteUsers.append(user2)
    SSTAutoCompleteUsers.append(user3)
    users_data = dict()
    users_data["data"] = {"SSTAutoCompleteUsers": SSTAutoCompleteUsers}

    return users_data


def fetch_cc_from_cwid_db(mail_id):
    connection_string = f'DRIVER={DRIVER};SERVER={SERVER};DATABASE={DATABASE};UID={USERNAME};PWD={PASSWORD}'
    # conn = pyodbc.connect(connection_string)
    conn = "pyodbc.connect(connection_string)"
    cursor = conn.cursor()
    query = "SELECT COST_CENTER FROM PUB.USERS5 WHERE MAIL_ADDRESS=" + mail_id
    cursor.execute(query)
    rows = cursor.fetchall()
    if rows:
        return rows[0]
    else:
        return ""


def get_user_details_from_graph_api(search, email):
    access_token = utility_file.generate_token()
    headers = {
        "Authorization": access_token,
        "Content-Type": "application/json",
        "ConsistencyLevel": "eventual",
    }
    if email:
        url = f"https://graph.microsoft.com/v1.0/users?$search=\"mail:{email}\"&$select=mail,displayName,mailNickname,companyName"
        # url = f"https://graph.microsoft.com/v1.0/users?$search=\"mail:abc@bayer.com\"&$select=displayName,givenName,surname,jobTitle,mail,accountEnabled,department,companyName,createdDateTime,mailNickname,manager",
    else:
        if search:
            url = f"https://graph.microsoft.com/v1.0/users?$search=\"displayName:{search}\"&$select=mail,displayName,mailNickname"
            # url = f"https://graph.microsoft.com/v1.0/users?&$search=\"displayName:al\"&$select=mail,displayName,mailNickname"
    response = requests.get(
        url=url,
        headers=headers,
    )
    # print(response)
    if search and response:
        search_users = parse_graphql_response(response)
        return search_users
        # return json.loads(response.text)
    elif email and response:
        user_attributes = get_user_info_from_jx(email)
        if not user_attributes and response:
            search_user_from_email = parse_graphql_response_from_email(response)
            return search_user_from_email
        else:
            return user_attributes
    else:
        raise Exception("An error occurred")


def parse_graphql_response(response):
    if response:
        response_dict = json.loads(response.text)
        users_value_list = response_dict.get("value")
        users = []

        if users_value_list is None:
            return users

        for u in users_value_list:
            user = dict()
            mail = u.get("mail")
            # display_name=u.get("displayName")
            if mail and '@bayer.com' in mail:
                user['full_name'] = u.get("displayName")
                user['email_address'] = mail
                user['cwid'] = u.get("mailNickname")
                user['status'] = 0
                users.append(user)
        if len(users) >= 40:
            users = users[0:40]
        return users


def parse_graphql_response_from_email(response):
    if response:
        response_dict = json.loads(response.text)
        users_value_list = response_dict.get("value")
        users = []

        if users_value_list is None:
            return users
        for u in users_value_list:
            user = dict()
            mail = u.get("mail")
            if mail and '@bayer.com' in mail:
                user['full_name'] = u.get("displayName")
                user['email_address'] = mail
                user['cwid'] = u.get("mailNickname")
                user['companyName'] = u.get("companyName")
                users.append(user)
        return users


def get_parse_user_data(user_attribute_json, fullName):
    user_details = dict()
    users = []
    user_details = json.loads(user_attribute_json)

    if user_details is None:
        return users

    user = dict()
    for row in user_details:
        user[row.get("2")] = row.get("3")
    user['full_name'] = fullName
    # user['role']=user_role_list
    users.append(user)
    dict_for_ui = mapping_attributes(users)
    return dict_for_ui


def mapping_attributes(users):
    key_mapping = {
        'Title': 'title',
        'Email Address': 'emailAddress',
        'CWID': 'cwid',
        'Company': 'company',
        'hours/week': 'hoursWeek',
        'Roles': 'roles',
        'Country': 'country',
        'Legal Entity': 'legalEntity',
        'top-function': 'topFunction',
        'sub-function': 'subFunction',
        'sub-sub-function': 'subSubFunction',
        'Backup ID': 'backupId',
        'Timekeeping Assistant ID': 'timekeepingAssistantId',
        'Timekeeping Assistant2 Id': 'timekeepingAssistant2Id',
        'Employee Start Date': 'employeeStartDate',
        'Employee End Date': 'employeeEndDate',
        'Backup Approver': 'backupApprover',
        'Cost Center': 'costCenter',
        'Employee Type': 'employeeType',
        'External Flag': 'externalFlag',
        'Function': 'function',
        'Supervisor ID': 'supervisorId',
        'Supervisor Flag': 'supervisorFlag',
        'full_name': 'fullName',
        'Is Existing User': 'isExistingUser'
    }
    renamed_dict = {key_mapping.get(k, k): v for k, v in users[0].items()}
    # print(renamed_dict)
    return renamed_dict


def get_list_of_user_roles(all_roles):
    list_of_roles = []
    user_roles = dict()
    user_roles = json.loads(all_roles)

    if user_roles is None:
        return list_of_roles

    for row in user_roles:
        roles = row.get("name")
        roles = roles.replace("ROLE: ", "")
        list_of_roles.append(roles)
    return list_of_roles
