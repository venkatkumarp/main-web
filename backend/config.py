import os
from pydantic_settings import BaseSettings, SettingsConfigDict

envFileName = os.environ.get('environment_selected')
DOTENV = ".env.dev" if envFileName == None else os.path.join(os.path.dirname(__file__), (".env." + envFileName))

class Settings(BaseSettings):
    
    model_config = SettingsConfigDict(env_file=DOTENV, extra='forbid')