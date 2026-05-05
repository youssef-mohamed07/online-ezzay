import requests

url = "https://demo.onlineezzy.com/wp-json/ezzy/v1/shipments"
auth = ('ck_f39120cd330fd760dc139d9509f02e4b2eedf3a2', 'cs_446625012f0190865ee5a2c87c1bbd6d3edb6c62')
response = requests.get(url, auth=auth)
print("Status Code:", response.status_code)
try:
    print(response.json())
except:
    print(response.text)
