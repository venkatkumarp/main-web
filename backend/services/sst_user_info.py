import json


def get_dummy_user():
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

    return json.dumps(users_data, indent=4)