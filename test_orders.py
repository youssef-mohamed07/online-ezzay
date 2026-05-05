import urllib.request
import json
import base64

url = "https://demo.onlineezzy.com/wp-json/wc/v3/orders"
auth_str = b"ck_f39120cd330fd760dc139d9509f02e4b2eedf3a2:cs_446625012f0190865ee5a2c87c1bbd6d3edb6c62"
b64_auth = base64.b64encode(auth_str).decode("ascii")

req = urllib.request.Request(url)
req.add_header("Authorization", f"Basic {b64_auth}")

try:
    with urllib.request.urlopen(req) as response:
        data = json.loads(response.read().decode())
        print(json.dumps(data[0], indent=2))
except Exception as e:
    print("Error:", e)
