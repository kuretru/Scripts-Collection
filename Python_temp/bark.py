# coding=utf-8
# Bark Client for Python
# Packages required: pycryptodome
# Author: 呉真 < kuretru@gmail.com >
# Github: https://github.com/kuretru/Scripts-Collection/blob/master/python/bark.py
# Version: 1.0.230615

import base64
import json
import random
import string
from enum import Enum
from urllib import request


class Bark:
    class Level(Enum):
        ACTIVE = "active"
        TIME_SENSITIVE = "timeSensitive"
        PASSIVE = "passive"

    class CryptoMode(Enum):
        CBC = "CBC"
        ECB = "ECB"

    def __init__(self, device_token: str, server_url: str = "https://api.day.app",
                 aes_key: str = None, aes_iv: str = None, aes_mode: CryptoMode = CryptoMode.CBC):
        """
        初始化Bark服务，一个实例对应一个设备(用户)
        :param device_token: 苹果推送的真实设备Token
        :param server_url: 可选，推送服务地址，默认为Bark官方免费服务端
        :param aes_key: 可选，AES加密密钥，长度必须为：16位(AES128) 或 24位(AES192) 或 32位(AES256)
        :param aes_iv: 可选，初始向量，默认为随机生成(更安全)
        :param aes_mode: 可选，加密模式，默认为CBC模式(更安全)
        """
        self.device_token = device_token
        self.server_url = server_url
        self.aes_key = aes_key
        self.aes_iv = aes_iv
        self.aes_mode = aes_mode

    def push(self, body: str, title: str = None, level: Level = None, badge: int = None,
             auto_copy: bool = None, copy: str = None, sound: str = None, icon: str = None,
             group: str = None, is_archive: bool = None, url: str = None):
        """
        推送通知
        :param body: 推送内容
        :param title: 推送标题
        :param level: 推送中断级别：ACTIVE->默认值，系统会立即亮屏显示通知, TIME_SENSITIVE->时效性通知，可在专注状态下显示通知，PASSIVE->仅将通知添加到通知列表，不会亮屏提醒。
        :param badge: 推送角标，可以是任意数字。
        :param auto_copy: iOS14.5以下自动复制推送内容，iOS14.5以上需手动长按推送或下拉推送。
        :param copy: 复制推送时，指定复制的内容，不传此参数将复制整个推送内容。
        :param sound: 可以为推送设置不同的铃声。
        :param icon: 为推送设置自定义图标，设置的图标将替换默认Bark图标。图标会自动缓存在本机，相同的图标 URL 仅下载一次。
        :param group: 对消息进行分组，推送将按group分组显示在通知中心中。也可在历史消息列表中选择查看不同的群组。
        :param is_archive: 传 1 保存推送，传其他的不保存推送，不传按APP内设置来决定是否保存。
        :param url: 点击推送时，跳转的URL ，支持URL Scheme 和 Universal Link。
        :return: 返回服务端响应结果。
        """
        data = self._build_body(body, title, level, badge, auto_copy, copy, sound, icon, group, is_archive, url)
        data["device_key"] = self.device_token
        return self._http_post(self.server_url + "/push", data)

    def push_ciphertext(self, body: str, title: str = None, level: Level = None, badge: int = None,
                        auto_copy: bool = None, copy: str = None, sound: str = None, icon: str = None,
                        group: str = None, is_archive: bool = None, url: str = None):
        """
        推送通知
        :param body: 推送内容
        :param title: 推送标题
        :param level: 推送中断级别：ACTIVE->默认值，系统会立即亮屏显示通知, TIME_SENSITIVE->时效性通知，可在专注状态下显示通知，PASSIVE->仅将通知添加到通知列表，不会亮屏提醒。
        :param badge: 推送角标，可以是任意数字。
        :param auto_copy: iOS14.5以下自动复制推送内容，iOS14.5以上需手动长按推送或下拉推送。
        :param copy: 复制推送时，指定复制的内容，不传此参数将复制整个推送内容。
        :param sound: 可以为推送设置不同的铃声。
        :param icon: 为推送设置自定义图标，设置的图标将替换默认Bark图标。图标会自动缓存在本机，相同的图标 URL 仅下载一次。
        :param group: 对消息进行分组，推送将按group分组显示在通知中心中。也可在历史消息列表中选择查看不同的群组。
        :param is_archive: 传 1 保存推送，传其他的不保存推送，不传按APP内设置来决定是否保存。
        :param url: 点击推送时，跳转的URL ，支持URL Scheme 和 Universal Link。
        :return: 返回服务端响应结果。
        """
        from Crypto.Cipher import AES
        from Crypto.Util.Padding import pad

        if self.aes_key is None:
            raise KeyError("未指定加密密钥")
        if len(self.aes_key) != 16 and len(self.aes_key) != 24 and len(self.aes_key) != 32:
            raise ValueError("密钥长度必须为：16位(AES128) 或 24位(AES192) 或 32位(AES256)")
        data = self._build_body(body, title, level, badge, auto_copy, copy, sound, icon, group, is_archive, url)
        data = bytes(json.dumps(data), "utf-8")
        data = pad(data, AES.block_size, "pkcs7")

        mode = AES.MODE_CBC if self.aes_mode == Bark.CryptoMode.CBC else AES.MODE_ECB
        iv = self.aes_iv if self.aes_iv is not None else ''.join(random.sample(string.printable, 16))
        cipher = AES.new(bytes(self.aes_key, "utf-8"), mode, iv=bytes(iv, "utf-8"))
        ciphertext = cipher.encrypt(data)
        ciphertext = base64.b64encode(ciphertext).decode("utf-8")

        data = {
            "device_key": self.device_token,
            "ciphertext": ciphertext,
            "iv": iv
        }
        return self._http_post(self.server_url + "/push", data)

    @staticmethod
    def _build_body(body: str, title: str = None, level: Level = None, badge: int = None,
                    auto_copy: bool = None, copy: str = None, sound: str = None, icon: str = None,
                    group: str = None, is_archive: bool = None, url: str = None):
        data = {
            "body": body
        }
        if title is not None:
            data["title"] = title
        if level is not None:
            data["level"] = level.value
        if badge is not None:
            data["badge"] = badge
        if auto_copy is not None:
            data["autoCopy"] = 1 if auto_copy else 0
        if copy is not None:
            data["copy"] = copy
        if sound is not None:
            data["sound"] = sound
        if icon is not None:
            data["icon"] = icon
        if group is not None:
            data["group"] = group
        if is_archive is not None:
            data["isArchive"] = 1 if is_archive else 0
        if url is not None:
            data["url"] = url
        return data

    @staticmethod
    def _http_post(url: str, data: dict) -> dict:
        req = request.Request(url=url,
                              data=bytes(json.dumps(data), "utf-8"),
                              method="POST",
                              headers={
                                  "Content-Type": "application/json"
                              })
        response = request.urlopen(req).read().decode("utf-8")
        return json.loads(response)


def main():
    device_token = "device_token"
    aes_key = "01234567890123456789012345678901"
    bark = Bark(device_token, aes_key=aes_key)
    print(bark.push_ciphertext("加密测试", title="标题"))


if __name__ == "__main__":
    main()
