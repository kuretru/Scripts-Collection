#!/bin/bash
#================================================================================
# OS Required:  Rocky Linux 9
# Description:  服务器一键初始化脚本
# Author:       呉真 < kuretru@gmail.com >
# Github:       https://github.com/kuretru/Scripts-Collection
# Version:      1.1.230709
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
        InstallDocker
        InstallSSlibev
        InstallNginx
        InstallPHP
        ConfigPerson

        cat <<EOF
================================================================================

========================= 初始化完成，请重启服务器 =================================

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

============================== 开始更新软件包 ====================================

================================================================================
EOF

    echo "fastestmirror=True" >> /etc/dnf/dnf.conf
    dnf clean all
    dnf makecache
    dnf -y update
}

#安装基本软件包
function InstallPackages() {
    cat <<EOF
================================================================================

============================== 开始安装基本软件包 =================================

================================================================================
EOF

    dnf -y install epel-release
    dnf -y update
    dnf -y install vim wget curl tree lsof mtr unzip git zsh tar tcpdump screen
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
}

#配置SSH
function SSHConfig() {
    cat <<EOF
================================================================================

============================== 开始配置SSH ==============================

================================================================================
EOF

    sed -i "s/^#Port .*$/Port 8022/g" /etc/ssh/sshd_config
    sed -i "s/^.*LoginGraceTime.*/LoginGraceTime 1m/g" /etc/ssh/sshd_config
    sed -i "s/^.*MaxAuthTries.*/MaxAuthTries 2/g" /etc/ssh/sshd_config
    sed -i "s/^.*#ClientAliveInterval.*/ClientAliveInterval 10/g" /etc/ssh/sshd_config
    sed -i "s/^.*#ClientAliveCountMax.*/ClientAliveCountMax 6/g" /etc/ssh/sshd_config
    sed -i "s/^.*PubkeyAuthentication.*/PubkeyAuthentication yes/g" /etc/ssh/sshd_config
    sed -i "s/^.*AuthorizedKeysFile/AuthorizedKeysFile/g" /etc/ssh/sshd_config
    sed -i "s/PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/sshd_config
    cd /root
    mkdir .ssh
    touch .ssh/authorized_keys
    cat <<EOF >.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEDJFQPKl7dcgycViRbgPiQKLMlqqWTTiN5Mx/c1BPA/Phnil+6I8GunfaT0q5hGWTjbcUHvzOa/GHMFTD2+q68RwHV0RDdLll+X8W77lfZryRr4lB+hDoTqZHaO8ZCuLaw2DhjA/Ddwg0h7rNf5VIdt6IAu8lx4VxNGvwMQdQN1e2/bJsGWHC97GFM1c1tSfd/f0H94JRNHpmGxyjKDfJ1EjBkIZmT5kMR9XZziBkP6i1/zklCFtJhU20i4Ysj86h4AULisUJqvWFc51XIGswZBtO7UBkM1x0LnW3/B4G/tbG5+a60+dbgq8ucGCIRjlFsJzQQmpp1SwSel/sR9VZabiHP1PRpEFzcv1Xlcgm94QwxiBJ+1G+SF2KSjYpfdtLeyZtq/5I+tKNapfRuCCcj7d5wbS+LuG8e1Uo93KzYJJUWiro2mFiVRLu9VsY3C8ChUBszWq7NVf50WUywyQe+b8Aqjux02Zr50YCz7Jp9+45bKM1HVuxdb1BdrQ6Z8Og2oymp0B9mneJy6W+1ckGdutaLSQ14Au5/4TAq4Oy0xhaaTpWBgXp3lGm6wUAgcWlumkTik/KoJM92Bq46kkjO9N1WU/BWGKUMMssYEShDi55jUxiEGpYN50U1xuB5uJUHJRNb84Xgd9FO+BxLjbsG7HD334V7w1Fwgjdf2A3CQ== kuretru@gmail.com
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

    cd /etc/firewalld/services
    wget https://github.com/kuretru/Scripts-Collection/raw/master/files/firewalld/iperf3.xml -O iperf3.xml
    wget https://github.com/kuretru/Scripts-Collection/raw/master/files/firewalld/shadowsocks.xml -O shadowsocks.xml
    wget https://github.com/kuretru/Scripts-Collection/raw/master/files/firewalld/wireguard.xml -O wireguard.xml
    wget https://github.com/kuretru/Scripts-Collection/raw/master/files/firewalld/zerotier.xml -O zerotier.xml

    systemctl enable firewalld.service
    systemctl start firewalld.service
    firewall-cmd --add-port=8022/tcp --permanent
    firewall-cmd --add-service=http --permanent
    firewall-cmd --add-service=https --permanent
    firewall-cmd --add-service=http3 --permanent
    firewall-cmd --add-service=shadowsocks --permanent
    systemctl restart firewalld.service
}

#安装Docker
function InstallDocker() {
    cat <<EOF
================================================================================

========================= 开始配置Docker =========================

================================================================================
EOF

    dnf install -y yum-utils
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    systemctl enable docker
    systemctl start docker
}

#安装ShadowSocks-libev
function InstallSSlibev() {
    cat <<EOF
================================================================================

========================= 开始配置ShadowSocks-libev =========================

================================================================================
EOF

    mkdir -p /home/docker/shadowsocks-libev_with_v2ray-plugin
    cd /home/docker/shadowsocks-libev_with_v2ray-plugin
    wget -O compose.yaml https://github.com/kuretru/docker/raw/main/shadowsocks-libev_with-v2ray-plugin/compose.yaml

    mkdir config && cd config/
    wget -O config.json https://github.com/kuretru/docker/raw/main/shadowsocks-libev_with-v2ray-plugin/config.json
    # Do your changes
    sed -i "s/\"password\":\".*\",/\"password\":\"${SS_PASSWORD}\",/g" config.json
    sed -i "s/host=.*\"/host=${IPv4}\"/g" config.json
    cd ../

    docker compose up -d


    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p


    mkdir -p /home/docker/shadowsocks-manager
    cd /home/docker/shadowsocks-manager
    wget -O compose.yaml https://github.com/kuretru/docker/raw/main/shadowsocks-manager/compose.yaml

    mkdir config && cd config/
    # Do your changes
    cat <<EOF >default.yml
type: s

shadowsocks:
  address: 127.0.0.1:6001
manager:
  address: 0.0.0.0:4001
  password: '$SSMGR_PASSWORD'
db: 'server.sqlite'
EOF
    cd ../

    docker compose up -d
}

#安装nginx
function InstallNginx() {
    cat <<EOF
================================================================================

============================== 开始安装Nginx ==============================

================================================================================
EOF

    cd /etc/yum.repos.d/
    wget https://copr.fedorainfracloud.org/coprs/kuretru/nginx/repo/epel-9/kuretru-nginx-epel-9.repo
    dnf -y install --disablerepo AppStream nginx nginx-module-brotli
    systemctl enable nginx.service

    cd /etc/nginx
    wget https://github.com/kuretru/Scripts-Collection/raw/master/files/nginx/nginx.conf -O nginx.conf
    mkdir /etc/nginx/modules-enabled
    cd /etc/nginx/modules-enabled
    wget https://github.com/kuretru/Scripts-Collection/raw/master/files/nginx/brotli.conf -O brotli.conf
    mkdir /etc/nginx/default.d
    cd /etc/nginx/default.d
    wget https://github.com/kuretru/Scripts-Collection/raw/master/files/nginx/general.conf -O general.conf
    wget https://github.com/kuretru/Scripts-Collection/raw/master/files/nginx/php_fastcgi.conf -O php_fastcgi.conf
    wget https://github.com/kuretru/Scripts-Collection/raw/master/files/nginx/proxy.conf -O proxy.conf
    wget https://github.com/kuretru/Scripts-Collection/raw/master/files/nginx/security.conf -O security.conf
    wget https://github.com/kuretru/Scripts-Collection/raw/master/files/nginx/ss.conf -O ss.conf
    cd /etc/nginx/conf.d
    wget https://github.com/kuretru/Scripts-Collection/raw/master/files/nginx/default.conf -O default.conf
    wget https://github.com/kuretru/Scripts-Collection/raw/master/files/nginx/server.conf -O server.conf
    sed -i "s/FIXME/$HOSTNAME/g" server.conf

    mkdir -p /etc/acme.sh/$HOSTNAME

    mkdir /etc/nginx/ssl
    chmod 750 /etc/nginx/ssl
    cd /etc/nginx/ssl
    openssl dhparam -out /etc/nginx/dhparam.pem 2048
    openssl genrsa -out localhost.key 2048
    openssl req -new -key localhost.key -out localhost.csr -subj "/C=US/ST=California/L=San Jose/O=Google/OU=Earth/CN=$IPV4"
    openssl x509 -req -days 3650 -in localhost.csr -signkey localhost.key -out localhost.crt

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

    dnf -y module reset php
    dnf module enable -y php:8.1
    dnf install -y php php-mysqlnd php-gd
    chown -R root:nginx /var/lib/php/*
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
    chown nginx:nginx x.php
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
    sed -i "s/^ZSH_THEME=.*$/ZSH_THEME=\"ys\"/g" .zshrc
    sed -i "s/^# zstyle ':omz:update' mode auto/zstyle ':omz:update' mode auto/g" .zshrc
    sed -i "s/^# zstyle ':omz:update' frequency 13/zstyle ':omz:update' frequency 7/g" .zshrc
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
