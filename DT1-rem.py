import requests
from requests.exceptions import HTTPError, JSONDecodeError

API_URL = 'http://192.168.89.145/thruk/r'
HEADERS = {
    'X-Thruk-Auth-Key': 'd2f54235347e2f3a9af44d05d80accb4c93c1bcbefb2d5c1e15cc1f10bdba599_1',
    'X-Thruk-Auth-User': 'thrukadmin'
}


def get_json(url):
    try:
        response = requests.get(url, headers=HEADERS)
        response.raise_for_status()  # Raise an HTTPError for bad responses (4xx or 5xx)
        return response.json()
    except HTTPError as http_err:
        print('HTTP error occurred: {}'.format(http_err))
    except JSONDecodeError as json_err:
        print('JSON decoding error occurred: {}'.format(json_err))
    return None


def remove_downtime_for_host(host_name):
    url = '{}/hosts/{}/cmd/del_active_host_downtimes'.format(API_URL, host_name)
    response = requests.post(url, headers=HEADERS)
    return response.text


def remove_downtime_for_service(host_name, service_description):
    url = '{}/services/{}/cmd/del_active_service_downtimes'.format(API_URL, '/'.join([host_name, service_description]))
    response = requests.post(url, headers=HEADERS)
    return response.text


def check_comment(host_name, cmt, json_dt_data):
    for obj in json_dt_data:
        if obj.get("host_name") == host_name and obj.get("comment") == cmt and not obj.get("service_description"):
            print('{} {} {} <<<<'.format(obj.get("host_name"), obj.get("comment"), obj.get("service_description")))
            return True
    return False


def main():
    url_dt = '{}/downtimes'.format(API_URL)
    json_dt_data = get_json(url_dt)
    comment = "test11"
    hostgroup_name_to_remove_DT = 'linux-servers'
    url_hg = '{}/hostgroups/{}'.format(API_URL, hostgroup_name_to_remove_DT)
    members_list = get_json(url_hg)[0].get('members', [])

    for hostname in members_list:
        url_host = '{}/hosts/{}'.format(API_URL, hostname)
        json_data = get_json(url_host)

        # Extract values
        scheduled_downtime_depth = json_data[0].get("scheduled_downtime_depth", None)
        services = json_data[0].get("services", [])
        state = json_data[0].get("state", None)

        # Print the extracted values
        print(hostname)
        print("scheduled_downtime_depth:", scheduled_downtime_depth)
        print("services:", services)
        print("state:", state)
        c_status = check_comment(hostname, comment, json_dt_data)

        if scheduled_downtime_depth == 1 and state == 0 and c_status:
            print("Condition match")
            remove_downtime_for_host(hostname)
            for service in services:
                remove_downtime_for_service(hostname, service)


if __name__ == "__main__":
    main()
