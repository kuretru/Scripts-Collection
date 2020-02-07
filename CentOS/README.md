# CentOS相关脚本

## CentOS-setup.sh

将全新系统一键初始化，支持CentOS 7/8。

### 功能

* 将系统软件包更新到最新
* 安装基本软件包(SS、Nginx、PHP)
* 基本系统配置(SSH、防火墙)
* 个人配置
* 配置一个自带探针的虚拟主机
* 云探针、X探针
* Shadowsocks-manage ssmgr管理服务端

### 使用方法

```bash
# For CentOS 7
sh -c "$(wget https://github.com/kuretru/Scripts-Collection/raw/master/CentOS/CentOS7-setup.sh -O -)"

# For CentOS 8
sh -c "$(wget https://github.com/kuretru/Scripts-Collection/raw/master/CentOS/CentOS8-setup.sh -O -)"
```
