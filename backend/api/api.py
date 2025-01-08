from fastapi import APIRouter
from .endpoints import sample
from .endpoints import mda_sys_reports

from services import sst_user_info
from repositories import fetch_update_user_data

router = APIRouter()
router.include_router(sample.router, prefix="/sample", tags=["Example"])
router.include_router(mda_sys_reports.router, prefix="/mda-sys-reports", tags=["MDA Systems Report"])


# Route to find user details for auto competition
# router.include_router(router,prefix="/users", tags=["users"])
@router.get("/")
async def test_user():
    # ToDo : Fetch the users from Graph API and and prepare the desired JSON format and send it back ON UI
    test_users = sst_user_info.get_dummy_user()
    return test_users


@router.get("/users")
async def fetch_user_details(search: str = None, email: str = None):
    # ToDo : Fetch the users from Graph API and and prepare the desired JSON format and send it back ON UI
    user_details = sst_user_info.get_user_details_from_graph_api(search, email)
    return user_details


@router.get("/company-names")
async def fetch_company_names(search: str = None):
    # ToDo : Fetch the users from Graph API and and prepare the desired JSON format and send it back ON UI
    company_names = fetch_update_user_data.get_all_company_name(search)
    return company_names


@router.get("/user-roles")
async def fetch_all_user_roles(search: str = None):
    # ToDo : Fetch the users from Graph API and and prepare the desired JSON format and send it back ON UI
    all_user_roles = fetch_update_user_data.get_all_user_roles(search)
    return all_user_roles


@router.get("/cost-center")
async def fetch_cost_center(search: str = None):
    # ToDo : Fetch the users from Graph API and and prepare the desired JSON format and send it back ON UI
    cost_center = fetch_update_user_data.get_all_cost_centers(search)
    return cost_center


@router.get("/sub-sub-function")
async def fetch_sub_sub_function(search: str = None):
    # ToDo : Fetch the users from Graph API and and prepare the desired JSON format and send it back ON UI
    sub_sub_function = fetch_update_user_data.get_sub_sub_function(search)
    return sub_sub_function
