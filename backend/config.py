import os
# from dotenv import dotenv_values
from pydantic_settings import BaseSettings, SettingsConfigDict

envFileName = os.environ.get('environment_selected')
DOTENV = ".env.dev" if envFileName == None else os.path.join(os.path.dirname(__file__), (".env." + envFileName))


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=DOTENV, extra='forbid')

# class AppSettings(BaseSettings):
#     app_id: str
#     app_secret_name: str
#     secret_scope: str
#     bayer_tenant_id: str
#     mdm_projects_catalog: str
#     ttm_profit_catalog: str
#     ttm_journyx_catalog: str
#     ttm_reporting_catalog: str
#     journyx_secret_scope: str
#
#     # model_config = SettingsConfigDict(env_file=DOTENV, extra='forbid')
#
# class AppConfiguration(AppSettings):
#     app_id: str = os.getenv("app_id")
#     app_secret_name: str = os.getenv("app_secret_name")
#     secret_scope: str = os.getenv("secret_scope")
#     bayer_tenant_id: str = os.getenv("bayer_tenant_id")
#     mdm_projects_catalog: str = os.getenv("mdm_projects_catalog")
#     ttm_profit_catalog: str = os.getenv("ttm_profit_catalog")
#     ttm_journyx_catalog: str = os.getenv("ttm_journyx_catalog")
#     ttm_reporting_catalog: str = os.getenv("ttm_reporting_catalog")
#     journyx_secret_scope: str = os.getenv("journyx_secret_scope")
#
#
# config_env = dotenv_values(DOTENV)
# config_apps = AppConfiguration(config_env)

