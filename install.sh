#!/bin/sh

usage () {
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

L2TP_PORT=1701
L2TP_VIRTUAL_IP=192.168.42.1
L2TP_DHCP_CIDR=192.168.42.0/24
L2TP_DHCP_START=192.168.42.10
L2TP_DHCP_END=192.168.42.250

# Those two variables will be found automatically
SERVER_PRIVATE_IP=`curl http://169.254.169.254/latest/meta-data/local-ipv4` || exit $?
SERVER_PUBLIC_IP=`curl http://169.254.169.254/latest/meta-data/public-ipv4` || exit $?

sysctl_permanent () {
    local key=${1:?}
    local value=${2:$?}
    if grep -q "^$key = $value" /etc/sysctl.conf; then
        sysctl -w $key=$value
        return $?
    fi

    sed -i "/^$key = /d" /etc/sysctl.conf || return $?
    sysctl -w $key=$value >> /etc/sysctl.conf || return $?
}


yum install -y --enablerepo=epel openswan xl2tpd || exit $?

# ipsec.conf
/bin/cp -a ${0%/*}/conf/ipsec.conf /etc/ipsec.conf || exit $?
sed -i "s/<SERVER_PRIVATE_IP>/$SERVER_PRIVATE_IP/" /etc/ipsec.conf || exit $?
sed -i "s/<SERVER_PUBLIC_IP>/$SERVER_PUBLIC_IP/" /etc/ipsec.conf || exit $?
sed -i "s/<L2TP_PORT>/$L2TP_PORT/" /etc/ipsec.conf || exit $?

# ipsec.secrets
/bin/cp -a ${0%/*}/conf/ipsec.secrets /etc/ipsec.secrets || exit $?
sed -i "s/<SERVER_PUBLIC_IP>/$SERVER_PUBLIC_IP/" /etc/ipsec.secrets || exit $?
sed -i "s/<IPSEC_PSK>/$IPSEC_PSK/" /etc/ipsec.secrets || exit $?

# xl2tpd.conf
/bin/cp -a ${0%/*}/conf/xl2tpd.conf /etc/xl2tpd/xl2tpd.conf || exit $?
sed -i "s/<L2TP_VIRTUAL_IP>/$L2TP_VIRTUAL_IP/" /etc/xl2tpd/xl2tpd.conf || exit $?
sed -i "s/<L2TP_DHCP_START>/$L2TP_DHCP_START/" /etc/xl2tpd/xl2tpd.conf || exit $?
sed -i "s/<L2TP_DHCP_END>/$L2TP_DHCP_END/" /etc/xl2tpd/xl2tpd.conf || exit $?
sed -i "s/<L2TP_PORT>/$L2TP_PORT/" /etc/xl2tpd/xl2tpd.conf || exit $?

# options.xl2tpd
/bin/cp -a ${0%/*}/conf/options.xl2tpd /etc/ppp/options.xl2tpd || exit $?
sed -i "s/<PRIMARY_DNS>/$PRIMARY_DNS/" /etc/ppp/options.xl2tpd || exit $?
sed -i "s/<SECONDARY_DNS>/$SECONDARY_DNS/" /etc/ppp/options.xl2tpd || exit $?

# char-secrets
/bin/cp -a ${0%/*}/conf/chap-secrets /etc/ppp/char-secrets || exit $?

# sysctl
sysctl_permanent 'net.ipv4.ip_forward' 1 || exit $?

# iptables
service iptables status | grep "$L2TP_DHCP_CIDR" | grep -q 'MASQUERADE'
if [[ $? -ne 0 ]]; then
    iptables -t nat -A POSTROUTING -s "$L2TP_DHCP_CIDR" -o eth0 -j MASQUERADE || exit $?
    service iptables save || exit $?
fi

# services
service ipsec restart || exit $?
service xl2tpd restart || exit $?
chkconfig ipsec on || exit $?
chkconfig xl2tpd on || exit $?

exit
