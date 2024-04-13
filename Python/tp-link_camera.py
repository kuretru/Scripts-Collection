import hashlib
import sys

import requests

URL = "http://192.168.91.67"


def get_nonce() -> str:
    url = URL + "/pc/Content.htm"
    response = requests.get(url)
    data = response.json()
    return data["data"]["nonce"]


def encrypt_password(data: str, nonce: str) -> str:
    return hashlib.md5(f"{data}:{nonce}".encode("utf-8")).hexdigest()


def login(username: str, password: str, nonce: str) -> str:
    password = encrypt_password(password, nonce)
    url = URL + "/"
    payload = {
        "method": "do",
        "login": {
            "username": username,
            "password": password,
            "encrypt_type": "2",
            "md5_encrypt_type": "1"
        }
    }
    response = requests.post(url, json=payload)
    data = response.json()
    print(data)
    return data["stok"]


def fill_light(token: str, mode: str):
    url = f"{URL}/stok={token}/ds"
    payload = {
        "method": "set",
        "image": {
            "common": {
                "inf_type": mode,
                "wtl_type": mode
            }
        }
    }
    response = requests.post(url, json=payload)
    print(response.json())


def fill_light_auto(token: str):
    fill_light(token, "auto")


def fill_light_on(token: str):
    fill_light(token, "on")


def lens_mask(token: str, enabled: str):
    url = f"{URL}/stok={token}/ds"
    payload = {
        "method": "set",
        "lens_mask": {
            "lens_mask_info": {
                "enabled": enabled
            }
        }
    }
    response = requests.post(url, json=payload)
    print(response.json())


def lens_mask_on(token: str):
    lens_mask(token, "on")


def lens_mask_off(token: str):
    lens_mask(token, "off")


def main():
    ip = sys.argv[1]
    username = sys.argv[2]
    password = sys.argv[3]
    module = sys.argv[4]
    command = sys.argv[5]

    execute_fn = None

    if module == "lens_mask":
        if command == "on":
            execute_fn = lens_mask_on
        elif command == "off":
            execute_fn = lens_mask_off
    elif module == "fill_light":
        if command == "on":
            execute_fn = fill_light_on
        elif command == "auto":
            execute_fn = fill_light_auto
    else:
        print(f"Unknown <module>: {module}")
        sys.exit(1)
    if execute_fn is None:
        print(f"Unknown <command>: {command}")
        sys.exit(1)

    global URL
    URL = URL.replace("192.168.91.67", ip)

    nonce = get_nonce()
    token = login(username, password, nonce)
    execute_fn(token)


if __name__ == "__main__":
    if len(sys.argv) < 6:
        print("Usage: python3 tp-link_camera.py <ip> <username> <password> <module> <command>")
        print("E.g.: python3 tp-link_camera.py 192.168.91.67 admin 123456 lens_mask on")
        print("E.g.: python3 tp-link_camera.py 192.168.91.67 admin 123456 lens_mask off")
        print("E.g.: python3 tp-link_camera.py 192.168.91.67 admin 123456 fill_light on")
        print("E.g.: python3 tp-link_camera.py 192.168.91.67 admin 123456 fill_light auto")
        sys.exit(1)
    main()

SECURITY_ENCODE_KEY = "RDpbLfCPsJZ7fiv"
SECURITY_ENCODE_TABLE = "yLwVl0zKqws7LgKPRQ84Mdt708T1qQ3Ha7xv3H7NyU84p21BriUWBU43odz3iP4rBL3cD02KZciXTysVXiV8ngg6vL48rPJyAUw0HurW20xqxv9aYb4M9wK1Ae0wlro510qXeU07kV57fQMc8L6aLgMLwygtc0F10a0Dg70TOoouyFhdysuRMO51yY5ZlOZZLEal1h0t9YQW0Ko7oBwmCAHoic4HYbUyVeU3sfQ1xtXcPcf1aT303wAQhv66qzW"


def security_encode(data: str) -> str:
    result = ""
    length = max(len(data), len(SECURITY_ENCODE_KEY))
    for i in range(length):
        x = y = 0xbb
        if i >= len(data):
            x = ord(SECURITY_ENCODE_KEY[i])
        elif i >= len(SECURITY_ENCODE_KEY):
            y = ord(data[i])
        else:
            x = ord(SECURITY_ENCODE_KEY[i])
            y = ord(data[i])
        result += SECURITY_ENCODE_TABLE[(x ^ y) % len(SECURITY_ENCODE_TABLE)]
    return result


def security_username_password(username: str, password: str) -> str:
    return hashlib.md5(f"{username}:TP-LINK IP-Camera:{password}".encode("utf-8")).hexdigest()
