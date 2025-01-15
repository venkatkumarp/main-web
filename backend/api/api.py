from fastapi import APIRouter

from .endpoints import sample
from services.sst_user_info import *

# import json

router = APIRouter()
router.include_router(sample.router, prefix="/sample", tags=["Example"])

# Route to find user details for auto competition
# router.include_router(router,prefix="/users", tags=["users"])
@router.get("/")
async def test_user():
        #ToDo : Fetch the users from Graph API and and prepare the desired JSON format and send it back ON UI
    test_users=get_dummy_user()
    return test_users