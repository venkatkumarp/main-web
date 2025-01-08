import json
import http.client
from xmlrpc import client
import pandas as pd
# import pyodbc
import requests

from services import sst_user_info
from utils import utility_file

JOURNYX_USER = utility_file.get_secret().get('JOURNYX_USER')
JOURNYX_PASSWORD = utility_file.get_secret().get('JOURNYX_PASSWORD')
JXURL = utility_file.get_secret().get('JXURL')

def get_user_info_from_jx(search_string):
    with client.ServerProxy(JXURL + '/jtcgi/jxapi_xmlrpc.pyc') as request:
        skey = request.login(JOURNYX_USER, JOURNYX_PASSWORD)
    user_data = request.getUser(skey, {"user_login": search_string})
    user_details = dict()
    if user_data:
        # user_attribute = proxy.getUserAttributes(skey, 'CWID')
        fullName = user_data['full_name']
        # id = user_data['id']
        # roles=request.getUserRoles(skey,id)
        # user_role_list=get_user_role_list(roles)
        user_attribute = request.getUserAttributes(skey, user_data['id'])
        df_user_attributes = pd.DataFrame(user_attribute)
        user_attribute_json = df_user_attributes[[2, 3]].to_json(orient="records", index=False)
        user_details = sst_user_info.get_parse_user_data(user_attribute_json, fullName)
        return user_details
    else:
        return user_details


def get_all_cost_centers(search_string):
    cost_center_list = []
    cc1 = dict()
    cc1['cost_center'] = "CostCenter1"
    cc1['legalEntity'] = "legalEntity1"
    cc1['function'] = "function1"
    cc1['subFunction'] = "subFunction1"
    cc1['topFunction'] = "topFunction1"
    cc1['country'] = "country1"

    cc2 = dict()
    cc2['cost_center'] = "CostCenter2"
    cc2['legalEntity'] = "legalEntity2"
    cc2['function'] = "function2"
    cc2['subFunction'] = "subFunction2"
    cc2['topFunction'] = "topFunction2"
    cc2['country'] = "country2"

    cost_center_list.append(cc1)
    cost_center_list.append(cc2)
    return cost_center_list


def get_all_user_roles(search_string):
    with client.ServerProxy(JXURL + "/jtcgi/jxapi_xmlrpc.pyc") as request:
        skey = request.login(JOURNYX_USER, JOURNYX_PASSWORD)

        groups_data = request.getAllGroups(skey)
        df_groups = pd.DataFrame(groups_data)
        df_roles = df_groups[df_groups['name'].str.startswith('ROLE')].iloc[:, :3]
        if not df_roles.empty:
            all_roles = df_roles[['name']].to_json(orient="records", index=False)
            list_of_roles = sst_user_info.get_list_of_user_roles(all_roles)
            return list_of_roles
        else:
            return ""


def get_all_company_name(search_string):
    list_of_company = ['company1', 'company2', 'company3', 'company4', 'company5']
    return list_of_company


def get_user_role_list(roles):
    with client.ServerProxy(JXURL + "/jtcgi/jxapi_xmlrpc.pyc") as request:
        skey = request.login(JOURNYX_USER, JOURNYX_PASSWORD)
        user_roles = []
        if roles is None:
            return user_roles
        for item in roles:
            user_role = request.getUserRoleById(skey, item)
            user_roles.append(user_role)
    return user_roles


def get_sub_sub_function(search_string):
    list_of_sub_sub_function = ['ss1', 'ss2', 'ss3', 'ss4', 'ss5']
    return list_of_sub_sub_function


def add_user_data_to_jx():
    # ToDo
    with client.ServerProxy(JXURL + "/jtcgi/jxapi_xmlrpc.pyc") as request:
        skey = request.login(JOURNYX_USER, JOURNYX_PASSWORD)
