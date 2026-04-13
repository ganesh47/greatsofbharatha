import json
import os
import sys
import time

import jwt
import requests

issuer = os.environ["APP_STORE_CONNECT_ISSUER_ID"]
key_id = os.environ["APP_STORE_CONNECT_KEY_ID"]
private_key = os.environ["APP_STORE_CONNECT_PRIVATE_KEY"]
app_id = os.environ["APP_STORE_CONNECT_APP_ID"]
target_version = os.environ["TARGET_VERSION"]

now = int(time.time())
token = jwt.encode(
    {
        "iss": issuer,
        "iat": now,
        "exp": now + 1200,
        "aud": "appstoreconnect-v1",
    },
    private_key,
    algorithm="ES256",
    headers={"kid": key_id, "typ": "JWT"},
)
headers = {"Authorization": f"Bearer {token}"}
url = f"https://api.appstoreconnect.apple.com/v1/builds?filter[app]={app_id}&limit=20&sort=-uploadedDate"
r = requests.get(url, headers=headers, timeout=30)
r.raise_for_status()
data = r.json().get("data", [])
for build in data:
    attrs = build.get("attributes", {})
    version = attrs.get("version")
    processing = attrs.get("processingState")
    print(json.dumps({"version": version, "processingState": processing}))
    if version == target_version and processing in {"PROCESSING", "VALID", "FAILED", "INVALID"}:
        sys.exit(0 if processing in {"VALID", "PROCESSING"} else 1)
print("Target build not found yet")
sys.exit(1)
