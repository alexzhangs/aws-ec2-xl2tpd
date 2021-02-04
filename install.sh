#!/bin/bash

# exit on any error
set -eo pipefail

function usage () {
    printf "Usage: ${0##*/} [-k IPSEC_PSK] [-p PRIMARY_DNS] [-s SECONDARY_DNS]\n"
    printf "OPTIONS\n"
    printf "\t[-k IPSEC_PSK]\n\n"
    printf "\tIPsec Pre-Shared Key, default is 'SharedSecret'.\n\n"
    printf "\t[-p PRIMARY_DNS]\n\n"
    printf "\tPrimary DNS, default is '8.8.8.8'.\n\n"
    printf "\t[-s SECONDARY_DNS]\n\n"
    printf "\tSecondary DNS, default is '8.8.4.4'.\n\n"
    exit 255
}

while getopts k:p:s:h opt; do
    case $opt in
        k)
            IPSEC_PSK=$OPTARG
            ;;
        p)
            PRIMARY_DNS=$OPTARG
            ;;
        s)
            SECONDARY_DNS=$OPTARG
            ;;
        *|h)
            usage
            ;;
    esac
done

[[ -z $IPSEC_PSK ]] && IPSEC_PSK="SharedSecret"
[[ -z $PRIMARY_DNS ]] && PRIMARY_DNS="8.8.8.8"
[[ -z $SECONDARY_DNS ]] && SECONDARY_DNS="8.8.4.4"

L2TP_VIRTUAL_IP=192.168.42.1
L2TP_DHCP_CIDR=192.168.42.0/24
L2TP_DHCP_BEGIN=192.168.42.10
L2TP_DHCP_END=192.168.42.250

# retrieve the IP addresses
SERVER_PRIVATE_IP=`curl http://169.254.169.254/latest/meta-data/local-ipv4`
SERVER_PUBLIC_IP=`curl http://169.254.169.254/latest/meta-data/public-ipv4`

function if-yum-repo-exsit () {
    # Usage: if-yum-repo-exist <repo>; echo $?
    [[ "$(yum repolist "${1:?}" | awk 'END {print $NF}')" > 0 ]]
}

function amazon-linux-extra-safe () {
    repo=${1:?}
    if type amazon-linux-extras >/dev/null 2>&1; then
        if ! if-yum-repo-exist "$repo"; then
            # Amazon Linux 2 AMI needs this
            echo "installing repo: $repo ..."
            amazon-linux-extras install -y "$repo"
        else
            echo "$repo: not found the repo, abort." >&2
            exit 255
        fi
    else
        echo 'amazon-linux-extra: not found the command, continue' >&2
    fi
}

# epel
amazon-linux-extra-safe epel

# openswan
echo 'installing openswan ...'
yum install -y --enablerepo=epel openswan

# xl2tpd
echo 'installing xl2tpd ...'
yum install -y --enablerepo=epel xl2tpd

# ipsec.conf
echo 'installing /etc/ipsec.conf ...'
/bin/cp -a ${0%/*}/conf/ipsec.conf /etc/ipsec.conf
sed -i "s/<SERVER_PRIVATE_IP>/$SERVER_PRIVATE_IP/" /etc/ipsec.conf
sed -i "s/<SERVER_PUBLIC_IP>/$SERVER_PUBLIC_IP/" /etc/ipsec.conf

# ipsec.secrets
echo 'installing /etc/ipsec.secrets ...'
/bin/cp -a ${0%/*}/conf/ipsec.secrets /etc/ipsec.secrets
sed -i "s/<SERVER_PUBLIC_IP>/$SERVER_PUBLIC_IP/" /etc/ipsec.secrets
sed -i "s/<IPSEC_PSK>/$IPSEC_PSK/" /etc/ipsec.secrets
chmod 600 /etc/ipsec.secrets

# xl2tpd.conf
echo 'installing /etc/xl2tpd/xl2tpd.conf ...'
/bin/cp -a ${0%/*}/conf/xl2tpd.conf /etc/xl2tpd/xl2tpd.conf
sed -i "s/<L2TP_VIRTUAL_IP>/$L2TP_VIRTUAL_IP/" /etc/xl2tpd/xl2tpd.conf
sed -i "s/<L2TP_DHCP_BEGIN>/$L2TP_DHCP_BEGIN/" /etc/xl2tpd/xl2tpd.conf
sed -i "s/<L2TP_DHCP_END>/$L2TP_DHCP_END/" /etc/xl2tpd/xl2tpd.conf

# options.xl2tpd
echo 'installing /etc/ppp/options.xl2tpd ...'
/bin/cp -a ${0%/*}/conf/options.xl2tpd /etc/ppp/options.xl2tpd
sed -i "s/<PRIMARY_DNS>/$PRIMARY_DNS/" /etc/ppp/options.xl2tpd
sed -i "s/<SECONDARY_DNS>/$SECONDARY_DNS/" /etc/ppp/options.xl2tpd

# char-secrets
echo 'installing /etc/ppp/char-secrets ...'
/bin/cp -a ${0%/*}/conf/chap-secrets /etc/ppp/char-secrets
chmod 600 /etc/ppp/char-secrets

function sysctl-write-and-save () {
    # Usage: sysctl-write-and-save <key>=<value>
    local key=${1%%=*}
    local value=${1#*=}

    sed -i "/^$key = /d" /etc/sysctl.conf
    sysctl -w "$key=$value" | tee -a /etc/sysctl.conf
}

# echo 'updating sysctl settings ...'
sysctl-write-and-save 'net.ipv4.ip_forward=1'
sysctl-write-and-save 'net.ipv4.conf.all.accept_redirects=0'
sysctl-write-and-save 'net.ipv4.conf.all.send_redirects=0'
sysctl-write-and-save 'net.ipv4.conf.default.accept_redirects=0'
sysctl-write-and-save 'net.ipv4.conf.default.send_redirects=0'
sysctl-write-and-save 'net.ipv4.conf.eth0.accept_redirects=0'
sysctl-write-and-save 'net.ipv4.conf.eth0.send_redirects=0'

# iptables-services
if ! service iptables status >/dev/null 2>&1; then
    echo 'installing iptables-services ...'
    yum install -y iptables-services
fi

# iptables
IPTABLES_OPTIONS="-t nat -s $L2TP_DHCP_CIDR -o eth0 -j MASQUERADE"
if ! iptables -C POSTROUTING $IPTABLES_OPTIONS 2>/dev/null; then
    echo 'updating iptables rules ...'
    iptables -A POSTROUTING $IPTABLES_OPTIONS
    service iptables save
fi

echo 'verifying ipsec ...'
ipsec verify || :

echo 'restarting ipsec service ...'
service ipsec restart

echo 'restarting xl2tpd service ...'
service xl2tpd restart

echo 'updating chkconfig ...'
chkconfig ipsec on
chkconfig xl2tpd on

exit
