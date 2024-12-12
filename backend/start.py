import os
from fastapi import FastAPI
from api.api import router as api_router
from mangum import Mangum
import uvicorn
from fastapi.middleware.cors import CORSMiddleware
from config import Settings

API_VERSION = '/api/v1'

app = FastAPI(
    title="Time Tracking FASTAPI 🚀",
    description="""
Time Tracking Application helps build financial assessments 📚.

## Authentication 🔒️

First authenticate to use APIs.

## Functionalities 👷

You are able to try out everything here but if you prefer the redoc, visit ` /redoc `.

## Contact 📱

**PH RND Time Tracking Engineering Team**, `54fe7143.bayergroup.onmicrosoft.com@emea.teams.ms`

""",
    root_path= os.environ.get('environment_selected')
)

settings = Settings()

origins = ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix=API_VERSION)
handler = Mangum(app)

if __name__ == "__main__":
   uvicorn.run(app, host="0.0.0.0", port=8080)