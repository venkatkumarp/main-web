import datetime;
from fastapi import APIRouter

router = APIRouter()


@router.get("/mda-sys-reports-timestamp")
async def get_all_reports_latest_updated_timestamp():
    # ct = get_last_updated_timestamp_databrick_table(table_name)
    # ct stores current time

    reports_names = ["[projects", "roles_activities", "users", "cost_centers"]
    report_names_prefix = "mda_sys_report"

    # fetch the latest timestamp of each report
    response = []
    for rn in reports_names:

        # prepare report name
        report_name = f"{report_names_prefix}_{rn}"

        response_single_report = dict()

        # ToDO: Find the last updated timestamp of the each report timestamps from Databricks
        ct = datetime.datetime.now()
        ts = ct.timestamp()

        # prepare response
        response_single_report["report_name"] = report_name
        response_single_report["last_updated"] = ts
        response_single_report["status_code"] = 200  # To be handled using exceptional handling
        response.append(response_single_report)

    return response
