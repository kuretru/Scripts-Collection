#!/bin/bash
#================================================================================
# OS Required:  CentOS8
# Description:  服务器一键初始化脚本
# Author:       呉真 < kuretru@gmail.com >
# Github:       https://github.com/kuretru/Scripts-Collection
# Version:      1.0.200207
#================================================================================

IPv4=$(wget -qO- -t1 -T2 ipv4.icanhazip.com)
IPv6=$(wget -qO- -t1 -T2 ipv6.icanhazip.com)

function main() {
    clear

    cat <<EOF
################################################################################
#                                                                              #
# 呉真的服务器一键初始化脚本，请务必保证当前是一个全新的环境                   #
# 如有疑惑，请访问https://github.com/kuretru/Scripts-Collection                #
#                                                                              #
################################################################################
EOF

    read -e -p "输入y开始安装(y/n)" ANSWER
    if [[ "$ANSWER" == 'y' ]] || [[ "$ANSWER" == 'yes' ]]; then
        sleep 1

        read -e -p "请输入主机名：" HOSTNAME
        read -e -p "请输入系统密码：" SYS_PASSWORD
        read -e -p "请输入SS密码：" SS_PASSWORD
        read -e -p "请输入监控用户名：" MONITOR_USERNAME
        read -e -p "请输入监控密码：" MONITOR_PASSWORD
        read -e -p "请输入SSMGR密码：" SSMGR_PASSWORD

        UpdatePackages
        InstallPackages
        ConfigSystem
        SSHConfig
        FirewallConfig
        InstallSSlibev
        InstallNginx
        InstallPHP
        InstalMonitor
        InstallNode
        ConfigPerson

        cat <<EOF
================================================================================

========================= 初始化完成，请重启服务器 =========================

================================================================================
EOF

    else
        echo '用户退出'
        exit
    fi
}

#软件包更新
function UpdatePackages() {
    cat <<EOF
================================================================================

============================== 开始更新软件包 ==============================

================================================================================
EOF

    echo "fastestmirror=true" >> /etc/dnf/dnf.conf
    dnf clean all
    dnf makecache
    dnf -y update
}

#安装基本软件包
function InstallPackages() {
    cat <<EOF
================================================================================

============================== 开始安装基本软件包 ==============================

================================================================================
EOF

    dnf -y install vim wget curl tree lsof epel-release bind-utils xz mtr \
        unzip crontabs git make gcc gcc-c++ firewalld chrony rsyslog zsh \
        sudo mailx python36 tar
    dnf clean all
}

#修改系统基本设置
function ConfigSystem() {
    cat <<EOF
================================================================================

============================== 开始修改系统基本设置 ==============================

================================================================================
EOF

    #修改主机名
    hostnamectl set-hostname $HOSTNAME
    #修改密码
    echo $SYS_PASSWORD | passwd --stdin root
    #关闭SELinux
    sed -i "s/^SELINUX=.*$/SELINUX=disabled/g" /etc/selinux/config
    setenforce 0
    #时间相关设置
    timedatectl set-timezone Asia/Shanghai
    systemctl enable crond.service
    systemctl enable chronyd.service
    systemctl start chronyd.service
    #配置DNS
    cat <<EOF >/etc/resolv.conf
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
}

#配置SSH
function SSHConfig() {
    cat <<EOF
================================================================================

============================== 开始配置SSH ==============================

================================================================================
EOF

    sed -i "s/^#Port .*$/Port 8022/g" /etc/ssh/sshd_config
    sed -i "s/^.*LoginGraceTime.*/LoginGraceTime 2m/g" /etc/ssh/sshd_config
    sed -i "s/^.*MaxAuthTries.*/MaxAuthTries 2/g" /etc/ssh/sshd_config
    sed -i "s/^.*PubkeyAuthentication.*/PubkeyAuthentication yes/g" /etc/ssh/sshd_config
    sed -i "s/^.*AuthorizedKeysFile/AuthorizedKeysFile/g" /etc/ssh/sshd_config
    sed -i "s/PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/sshd_config
    cd /root
    mkdir .ssh
    touch .ssh/authorized_keys
    cat <<EOF >.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDUnJJ+Yn4dgqtnFKWWvrs1ykceXt3nn9pmi6zFc29QkYjEa99dAeFX3ts2E+e9gswyJIwvh7xqRyfKvii9cAaUpsgX7RkH/qe/fWmSfR3f33CRvdnmwsPI600EBxKKuEzZR3C6EQVtj6Nw7s7DCc46e058nPt/A1fFIavc6EGPGQ==
EOF
    chmod 600 .ssh/authorized_keys
    chmod 700 .ssh
    systemctl restart sshd.service
}

#配置防火墙
function FirewallConfig() {
    cat <<EOF
================================================================================

============================== 开始配置防火墙 ==============================

================================================================================
EOF

    systemctl enable firewalld.service
    systemctl start firewalld.service
    firewall-cmd --add-port=8022/tcp --permanent
    firewall-cmd --add-service=http --permanent
    firewall-cmd --add-service=https --permanent
    firewall-cmd --add-port=8023/tcp --permanent
    firewall-cmd --add-port=8023/udp --permanent
    firewall-cmd --add-port=4001/tcp --permanent
    firewall-cmd --add-port=30000-30099/tcp --permanent
    firewall-cmd --add-port=30000-30099/udp --permanent
    systemctl restart firewalld.service
}

#安装ShadowSocks-libev
function InstallSSlibev() {
    cat <<EOF
================================================================================

========================= 开始配置ShadowSocks-libev =========================

================================================================================
EOF

    cd /etc/yum.repos.d/
    wget https://copr.fedorainfracloud.org/coprs/kuretru/shadowsocks/repo/epel-8/kuretru-shadowsocks-epel-8.repo
    yum -y install shadowsocks-libev
    systemctl enable shadowsocks-libev.service
    server_value="\"0.0.0.0\""
    if [ $IPv6 ]; then
        server_value="[\"[::0]\",\"0.0.0.0\"]"
    fi
    cat <<EOF >/etc/shadowsocks-libev/config.json
{
    "server":${server_value},
    "server_port":8023,
    "local_port":1080,
    "password":"${SS_PASSWORD}",
    "timeout":60,
    "method":"chacha20-ietf-poly1305"
}
EOF
    systemctl restart shadowsocks-libev.service

    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p
}

#安装nginx
function InstallNginx() {
    cat <<EOF
================================================================================

============================== 开始安装Nginx ==============================

================================================================================
EOF

    cat <<EOF >/etc/yum.repos.d/nginx.repo
[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
EOF
    dnf -y install --disablerepo AppStream nginx
    systemctl enable nginx.service

    cd /etc/nginx
    wget https://github.com/kuretru/Scripts-Collection/raw/master/files/nginx/nginx.conf -O nginx.conf
    mkdir /etc/nginx/default.d
    cd /etc/nginx/default.d
    wget https://github.com/kuretru/Scripts-Collection/raw/master/files/nginx/general.conf -O general.conf
    wget https://github.com/kuretru/Scripts-Collection/raw/master/files/nginx/php_fastcgi.conf -O php_fastcgi.conf
    wget https://github.com/kuretru/Scripts-Collection/raw/master/files/nginx/security.conf -O security.conf
    wget https://github.com/kuretru/Scripts-Collection/raw/master/files/nginx/proxy.conf -O proxy.conf
    cd /etc/nginx/conf.d
    wget https://github.com/kuretru/Scripts-Collection/raw/master/files/nginx/default.conf -O default.conf
    wget https://github.com/kuretru/Scripts-Collection/raw/master/files/nginx/server.conf -O server.conf
    sed -i "s/FIXME/$HOSTNAME/g" server.conf
    mv server.conf $HOSTNAME.conf

    mkdir /etc/nginx/ssl
    chmod 750 /etc/nginx/ssl
    cd /etc/nginx/ssl
    openssl dhparam -out /etc/nginx/dhparam.pem 2048
    openssl genrsa -out localhost.key 2048
    openssl req -new -key localhost.key -out localhost.csr -subj "/C=US/ST=California/L=San Jose/O=Google/OU=Earth/CN=$IPV4"
    openssl x509 -req -days 3650 -in localhost.csr -signkey localhost.key -out localhost.crt

    mkdir -p /home/nginx/$HOSTNAME/public
    chown -R nginx:nginx /home/nginx

    cd /etc/yum.repos.d/
    wget https://copr.fedorainfracloud.org/coprs/kuretru/nginx/repo/epel-8/kuretru-nginx-epel-8.repo
    dnf -y install nginx-module-brotli

    cd /tmp/
    wget https://dl.eff.org/certbot-auto
    mv certbot-auto /usr/local/bin/certbot-auto
    chown root /usr/local/bin/certbot-auto
    chmod 0755 /usr/local/bin/certbot-auto
    echo "0 0,12 * * * root python -c 'import random; import time; time.sleep(random.random() * 3600)' && /usr/local/bin/certbot-auto renew" | sudo tee -a /etc/crontab > /dev/null
}

#安装PHP
function InstallPHP() {
    cat <<EOF
================================================================================

============================== 开始安装PHP ==============================

================================================================================
EOF

    dnf -y install https://rpms.remirepo.net/enterprise/remi-release-8.rpm
    dnf -y install yum-utils
    dnf -y module reset php
    dnf -y module install php:remi-7.4
    dnf -y install php-mysqlnd php-gd
    systemctl enable php-fpm.service

    cd /etc/php-fpm.d
    sed -i "s/^user =.*$/user = nginx/g" www.conf
    sed -i "s/^group =.*$/group = nginx/g" www.conf
    sed -i "s/^pm.max_children =.*$/pm.max_children = 2/g" www.conf
    sed -i "s/^pm.start_servers =.*$/pm.start_servers = 1/g" www.conf
    sed -i "s/^pm.min_spare_servers =.*$/pm.min_spare_servers = 1/g" www.conf
    sed -i "s/^pm.max_spare_servers =.*$/pm.max_spare_servers = 2/g" www.conf
    sed -i "s/^;request_slowlog_timeout =.*$/request_slowlog_timeout = 2s/g" www.conf
    cd /home/nginx/$HOSTNAME/public
    wget https://api.inn-studio.com/download?id=xprober -O x.php
}

#安装ServerStatus云探针
function InstalMonitor() {
    cat <<EOF
================================================================================

============================== 开始安装云探针 ==============================

================================================================================
EOF

    cd /usr/bin
    ln -s python3 python
    cd /usr/local/share
    wget https://github.com/kuretru/ServerStatus/raw/master/clients/client-linux.py -O serverstatus-client.py
    chmod +x serverstatus-client.py
    sed -i "s/^SERVER =.*$/SERVER = \"monitor.kuretru.com\"/g" serverstatus-client.py
    sed -i "s/^PORT =.*$/PORT = 8099/g" serverstatus-client.py
    sed -i "s/^USER =.*$/USER = \"$MONITOR_USERNAME\"/g" serverstatus-client.py
    sed -i "s/^PASSWORD =.*$/PASSWORD = \"$MONITOR_PASSWORD\"/g" serverstatus-client.py

    cd /usr/lib/systemd/system/
    wget https://github.com/kuretru/ServerStatus/raw/master/scripts/serverstatus.service -O serverstatus.service
    systemctl enable serverstatus.service
}

#安装Node.JS
function InstallNode() {
    cat <<EOF
================================================================================

============================== 开始安装Node.JS ==============================

================================================================================
EOF

    dnf -y install nodejs
    npm i -g shadowsocks-manager --unsafe-perm
    mkdir /root/.ssmgr
    cat <<EOF >/root/.ssmgr/default.yml
type: s

shadowsocks:
  address: 127.0.0.1:6001
manager:
  address: 0.0.0.0:4001
  password: '$SSMGR_PASSWORD'
db: 'server.sqlite'
EOF
    wget https://github.com/kuretru/Scripts-Collection/raw/master/files/ssmgr/ssmgr -O /etc/init.d/ssmgr
    chmod +x /etc/init.d/ssmgr
    chkconfig ssmgr on
    chmod +x /etc/rc.d/rc.local
    echo "ss-manager -m chacha20-ietf-poly1305 -u --manager-address 127.0.0.1:6001 &" >>/etc/rc.d/rc.local
}

#个人配置
function ConfigPerson() {
    cat <<EOF
================================================================================

============================== 开始个人配置 ==============================

================================================================================
EOF

    cd /root
    sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
    sed -i "s/^ZSH_THEME=.*$/ZSH_THEME=\"af-magic\"/g" .zshrc
    sed -i "s/^# DISABLE_UPDATE_PROMPT=/DISABLE_UPDATE_PROMPT=/g" .zshrc
    sed -i "s/^# export UPDATE_ZSH_DAYS=13$/export UPDATE_ZSH_DAYS=7/g" .zshrc
    sed -i "s/^# ENABLE_CORRECTION=/ENABLE_CORRECTION=/g" .zshrc
    echo "setopt no_nomatch" >> .zshrc
    usermod -s /bin/zsh root

    wget https://github.com/kuretru/Scripts-Collection/raw/master/files/.vimrc
    #登录文本
    cat <<EOF >/etc/motd
警告：你的IP已被记录，所有操作将会通告管理员！
Warning: Your IP address has been recorded, all operations will notify the administrator!
EOF
}

main
