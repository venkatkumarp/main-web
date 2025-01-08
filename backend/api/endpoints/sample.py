from fastapi import APIRouter

router = APIRouter()

@router.get("/")
async def get_message():
    return {"message": "sample hello from time tracking!"}