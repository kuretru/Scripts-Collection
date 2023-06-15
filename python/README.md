# Python脚本

## bark.py

[Bark App](https://bark.day.app/#/?id=bark)的Python客户端。

### 环境依赖

* pycryptodome：可选，如果需要加密发送内容，则需要安装此包

### 使用

```python
bark = Bark("device_token")
bark.push("测试", title="标题")

bark = Bark("device_token", aes_key="aes_key")
bark.push_ciphertext("加密测试", title="标题")
```
