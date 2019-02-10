# CentOS7相关脚本
## CentOS7-setup.sh
将全新系统一键初始化
##### 功能
* 将系统软件包更新到最新
* 安装基本软件包(SS、Nginx、PHP)
* 基本系统配置(SSH、防火墙)
* 个人配置
* 配置一个自带探针的虚拟主机
##### 使用方法
```
sh -c "$(wget https://raw.githubusercontent.com/kuretru/Scripts-Collection/master/CentOS7/CentOS7-setup.sh -O -)"
```
