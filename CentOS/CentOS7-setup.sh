#!/bin/bash
#================================================================================
# OS Required:  CentOS7
# Description:  服务器一键初始化脚本
# Author:       呉真 < kuretru@gmail.com >
# Github:       https://github.com/kuretru/Scripts-Collection
# Version:      1.2.191014
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

    yum clean all
    yum makecache fast
    yum -y update
}

#安装基本软件包
function InstallPackages() {
    cat <<EOF
================================================================================

============================== 开始安装基本软件包 ==============================

================================================================================
EOF

    yum -y install vim wget curl tree lsof epel-release bind-utils xz mtr \
        unzip crontabs git make gcc gcc-c++ firewalld chrony rsyslog zsh \
        sudo mailx
    yum clean all
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

    cd /etc/yum.repos.d
    wget https://copr.fedorainfracloud.org/coprs/kuretru/shadowsocks/repo/epel-7/kuretru-shadowsocks-epel-7.repo
    yum -y install shadowsocks-libev
    systemctl enable shadowsocks-libev.service
    server_value="\"0.0.0.0\""
    if [ $IPv6 ]; then
        server_value="[\"[::0]\",\"0.0.0.0\"]"
    fi
    cat <<-EOF >/etc/shadowsocks-libev/config.json
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
}

#安装nginx
function InstallNginx() {
    cat <<EOF
================================================================================

============================== 开始安装Nginx ==============================

================================================================================
EOF

    yum -y install yum-utils
    cat <<EOF >/etc/yum.repos.d/nginx.repo
[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
EOF
    yum-config-manager --enable nginx-mainline
    yum -y install nginx certbot python2-certbot-nginx
    systemctl enable nginx.service

    cd /etc/nginx
    mv nginx.conf nginx.conf.bk
    wget https://raw.githubusercontent.com/kuretru/Scripts-Collection/master/files/nginx/nginx.conf -O nginx.conf
    mkdir /etc/nginx/default.d
    cd /etc/nginx/default.d
    wget https://raw.githubusercontent.com/kuretru/Scripts-Collection/master/files/nginx/general.conf -O general.conf
    wget https://raw.githubusercontent.com/kuretru/Scripts-Collection/master/files/nginx/php_fastcgi.conf -O php_fastcgi.conf
    wget https://raw.githubusercontent.com/kuretru/Scripts-Collection/master/files/nginx/security.conf -O security.conf
    wget https://raw.githubusercontent.com/kuretru/Scripts-Collection/master/files/nginx/proxy.conf -O proxy.conf
    cd /etc/nginx/conf.d
    mv default.conf default.conf.bk
    wget https://raw.githubusercontent.com/kuretru/Scripts-Collection/master/files/nginx/default.conf -O _default.conf
    wget https://raw.githubusercontent.com/kuretru/Scripts-Collection/master/files/nginx/server.conf -O server.conf
    sed -i "s/FIXME/$IPV4/g" _default.conf
    sed -i "s/FIXME/$HOSTNAME/g" server.conf
    mv server.conf $HOSTNAME.conf

    wget http://kuretru.github.io/packages/kuretru.repo -O /etc/yum.repos.d/kuretru.repo
    yum -y install nginx-module-brotli

    mkdir /etc/nginx/ssl
    chmod 750 /etc/nginx/ssl
    cd /etc/nginx/ssl
    openssl dhparam -out /etc/nginx/dhparam.pem 2048
    openssl genrsa -out localhost.key 2048
    openssl req -new -key localhost.key -out localhost.csr -subj "/C=US/ST=California/L=San Jose/O=Google/OU=Earth/CN=$IPV4"
    openssl x509 -req -days 3650 -in localhost.csr -signkey localhost.key -out localhost.crt

    echo "0 0,12 * * * root python -c 'import random; import time; time.sleep(random.random() * 3600)' && certbot renew" | sudo tee -a /etc/crontab > /dev/null

    mkdir -p /home/nginx/$HOSTNAME/public
    chown -R nginx:nginx /home/nginx
}

#安装PHP
function InstallPHP() {
    cat <<EOF
================================================================================

============================== 开始安装PHP ==============================

================================================================================
EOF

    yum -y install https://centos7.iuscommunity.org/ius-release.rpm
    rpm --import /etc/pki/rpm-gpg/IUS-COMMUNITY-GPG-KEY
    yum -y install php73-fpm php73-cli php73-mysqlnd php73-gd php73-xml php73-json
    systemctl enable php-fpm.service

    cd /etc/php-fpm.d
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

    cd /usr/local/share
    wget https://raw.githubusercontent.com/kuretru/ServerStatus/master/clients/client-linux.py -O serverstatus-client.py
    chmod +x serverstatus-client.py
    sed -i "s/^SERVER =.*$/SERVER = \"monitor.kuretru.com\"/g" serverstatus-client.py
    sed -i "s/^PORT =.*$/PORT = 8099/g" serverstatus-client.py
    sed -i "s/^USER =.*$/USER = \"$MONITOR_USERNAME\"/g" serverstatus-client.py
    sed -i "s/^PASSWORD =.*$/PASSWORD = \"$MONITOR_PASSWORD\"/g" serverstatus-client.py

    cd /usr/lib/systemd/system/
    wget https://raw.githubusercontent.com/kuretru/ServerStatus/master/scripts/serverstatus.service -O serverstatus.service
    systemctl enable serverstatus.service
}

#安装Node.JS
function InstallNode() {
    cat <<EOF
================================================================================

============================== 开始安装Node.JS ==============================

================================================================================
EOF

    curl -sL https://rpm.nodesource.com/setup_12.x | bash -
    yum -y install nodejs
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
    wget https://raw.githubusercontent.com/kuretru/Scripts-Collection/master/files/ssmgr/ssmgr -O /etc/init.d/ssmgr
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
    wget https://raw.githubusercontent.com/kuretru/Scripts-Collection/master/files/.vimrc
    #登录文本
    cat <<EOF >/etc/motd
警告：你的IP已被记录，所有操作将会通告管理员！
Warning: Your IP address has been recorded, all operations will notify the administrator!
EOF
}

main
