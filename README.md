# aws-ec2-xl2tpd

Install xl2tpd and openswan on AWS EC2 instance.

## Last tested version and envrionment

1. Passed with below - 2021-02

    ```sh
    # cat /etc/system-release
    Amazon Linux release 2 (Karoo)

    # cat /proc/version
    Linux version 4.14.214-160.339.amzn2.x86_64 (mockbuild@ip-10-0-1-230)
    (gcc version 7.3.1 20180712 (Red Hat 7.3.1-12) (GCC)) #1 SMP Sun Jan
    10 05:53:05 UTC 2021

    # openssl version
    OpenSSL 1.0.2k-fips  26 Jan 2017

    # ipsec --version
    Linux Libreswan U3.25/K(no kernel code presently loaded)
    on 4.14.214-160.339.amzn2.x86_64

    # xl2tpd --version
    xl2tpd version:  xl2tpd-1.3.15

    # pppd --version
    pppd version 2.4.5

    # iptables --version
    iptables v1.8.4 (legacy)
    ```

## Installation

Run below commands on the remote server:

```sh
# get code
git clone https://github.com/alexzhangs/aws-ec2-xl2tpd

# run this under root
bash aws-ec2-xl2tpd/install.sh

# see help:
bash aws-ec2-xl2tpd/install.sh -h
Usage: install.sh [-k IPSEC_PSK] [-p PRIMARY_DNS] [-s SECONDARY_DNS]
OPTIONS
	[-k IPSEC_PSK]

	IPsec Pre-Shared Key, default is 'SharedSecret'.

	[-p PRIMARY_DNS]

	Primary DNS, default is '8.8.8.8'.

	[-s SECONDARY_DNS]

	Secondary DNS, default is '8.8.4.4'.

```

Following inbound rules are necessary for the security group of the
EC2 instance:

| Type | Protocol | Port range | Source |
|---|---|---|---|
| Custom UDP | UDP | 4500 | 0.0.0.0/0 |
| Custom UDP | UDP | 500 | 0.0.0.0/0 |

NOTE: Don't list the UDP port `1701` in the inboud rules, It should be
never opened to the outside.

## Known Issues

1. Failed connecting to the xl2tpd server on Amazon linux AMI.

    The IPSec connection is always being deleted from client side
    after the SCCRQ was sent 20 seconds later.

    ```
    Wed Jan  6 01:22:58 2021 : IPSec connection started
    Wed Jan  6 01:22:59 2021 : IPSec phase 1 client started
    Wed Jan  6 01:22:59 2021 : IPSec phase 1 server replied
    Wed Jan  6 01:23:00 2021 : IPSec phase 2 started
    Wed Jan  6 01:23:00 2021 : IPSec phase 2 established
    Wed Jan  6 01:23:00 2021 : IPSec connection established
    Wed Jan  6 01:23:00 2021 : L2TP sent SCCRQ
    Wed Jan  6 01:23:20 2021 : L2TP cannot connect to the server
    ```

    Following error detected in the xl2tpd service starting log:

    ```
    L2TP kernel support not detected (try modprobing l2tp_ppp and pppol2tp)
    ```

    The Above error was newly found with the new deployed Amazon Linux
    AMI in 2021-01. It was fine with the old version of Amazon Linux AMI.

    The environment detail:

    ```sh
    # cat /etc/system-release
    Amazon Linux AMI release 2018.03

    # cat /proc/version
    Linux version 4.4.8-20.46.amzn1.x86_64 (mockbuild@gobi-build-60009)
    (gcc version 4.8.3 20140911 (Red Hat 4.8.3-9) (GCC) ) #1 SMP Wed Apr
    27 19:28:52 UTC 2016

    # openssl version
    OpenSSL 1.0.2k-fips  26 Jan 2017

    # ipsec --version
    Linux Openswan U2.6.37/K4.4.8-20.46.amzn1.x86_64 (netkey)

    # xl2tpd --version
    xl2tpd version:  xl2tpd-1.3.8
    ```

## Reference

* [xl2tpd](https://github.com/xelerance/xl2tpd) at Github
* [L2tp ipsec configuration using openswan and xl2tpd](https://github.com/xelerance/Openswan/wiki/L2tp-ipsec-configuration-using-openswan-and-xl2tpd)
* delete-me: https://serverfault.com/questions/451381/which-ports-for-ipsec-lt2p
* delete-me: [ipsec.conf Reference](https://wiki.strongswan.org/projects/strongswan/wiki/IpsecConf)
  * [ipsec.conf: config setup Reference](https://wiki.strongswan.org/projects/strongswan/wiki/ConfigSetupSection)
  * [ipsec.conf: conn <name> Reference](https://wiki.strongswan.org/projects/strongswan/wiki/ConnSection)
* [Example of a successful IPSec negotiation](https://www.linogate.de/en/support/categories/ipsec/log.html)

## Troubleshooting

1. Check the server logs

    ```sh
    ## check the system logs
    # tail -f /var/log/messages

    ## check l2tpd specific logs
    # tail -f /var/log/secure
    ```
1. Check the client logs (macOS)

    Check the logs in application `Console`: `Log Reports -> ppp.log`.

    Or in the command line:

    ```
    $ tail -f /var/log/ppp.log
    ```

1. Enable the debugging for server logs

    Uncomment below lines in `/etc/xl2tpd.conf` or add them if not found.

    ```ini
    [global]
    debug avp = yes
    debug network = yes
    debug state = yes
    debug tunnel = yes

    [lns default]
    ppp debug = yes
    ```

    Restart services:

    ```sh
    # service ipsec restart && service xl2tpd restart
    ```

1. The example logs of `service ipsec start`:

    ```
    ==> /var/log/secure <==
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: FIPS Product: NO
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: FIPS Kernel: NO
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: FIPS Mode: NO
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: NSS DB directory: sql:/etc/ipsec.d
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: Initializing NSS
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: Opening NSS database "sql:/etc/ipsec.d" read-only
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: NSS initialized
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: NSS crypto library initialized
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: FIPS HMAC integrity support [enabled]
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: FIPS mode disabled for pluto daemon
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: FIPS HMAC integrity verification self-test passed
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: libcap-ng support [enabled]
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: Linux audit support [enabled]
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: Linux audit activated
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: Starting Pluto (Libreswan Version 3.25 XFRM(netkey) KLIPS FORK PTHREAD_SETSCHEDPRIO GCC_EXCEPTIONS NSS (AVA copy) (IPsec profile) DNSSEC SYSTEMD_WATCHDOG FIPS_CHECK LABELED_IPSEC SECCOMP LIBCAP_NG LINUX_AUDIT XAUTH_PAM NETWORKMANAGER CURL(non-NSS) LDAP(non-NSS)) pid:4323
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: core dump dir: /run/pluto
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: secrets file: /etc/ipsec.secrets
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: leak-detective enabled
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: NSS crypto [enabled]
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: XAUTH PAM support [enabled]
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: NAT-Traversal support  [enabled]
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: Initializing libevent in pthreads mode: headers: 2.0.21-stable (2001500); library: 2.0.21-stable (2001500)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: Encryption algorithms:
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  AES_CCM_16          IKEv1:     ESP     IKEv2:     ESP     FIPS  {256,192,*128}  (aes_ccm aes_ccm_c)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  AES_CCM_12          IKEv1:     ESP     IKEv2:     ESP     FIPS  {256,192,*128}  (aes_ccm_b)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  AES_CCM_8           IKEv1:     ESP     IKEv2:     ESP     FIPS  {256,192,*128}  (aes_ccm_a)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  3DES_CBC            IKEv1: IKE ESP     IKEv2: IKE ESP     FIPS  [*192]  (3des)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  CAMELLIA_CTR        IKEv1:     ESP     IKEv2:     ESP           {256,192,*128}
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  CAMELLIA_CBC        IKEv1: IKE ESP     IKEv2: IKE ESP           {256,192,*128}  (camellia)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  AES_GCM_16          IKEv1:     ESP     IKEv2: IKE ESP     FIPS  {256,192,*128}  (aes_gcm aes_gcm_c)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  AES_GCM_12          IKEv1:     ESP     IKEv2: IKE ESP     FIPS  {256,192,*128}  (aes_gcm_b)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  AES_GCM_8           IKEv1:     ESP     IKEv2: IKE ESP     FIPS  {256,192,*128}  (aes_gcm_a)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  AES_CTR             IKEv1: IKE ESP     IKEv2: IKE ESP     FIPS  {256,192,*128}  (aesctr)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  AES_CBC             IKEv1: IKE ESP     IKEv2: IKE ESP     FIPS  {256,192,*128}  (aes)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  SERPENT_CBC         IKEv1: IKE ESP     IKEv2: IKE ESP           {256,192,*128}  (serpent)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  TWOFISH_CBC         IKEv1: IKE ESP     IKEv2: IKE ESP           {256,192,*128}  (twofish)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  TWOFISH_SSH         IKEv1: IKE         IKEv2: IKE ESP           {256,192,*128}  (twofish_cbc_ssh)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  CAST_CBC            IKEv1:     ESP     IKEv2:     ESP           {*128}  (cast)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  NULL_AUTH_AES_GMAC  IKEv1:     ESP     IKEv2:     ESP           {256,192,*128}  (aes_gmac)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  NULL                IKEv1:     ESP     IKEv2:     ESP           []
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: Hash algorithms:
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  MD5                 IKEv1: IKE         IKEv2:
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  SHA1                IKEv1: IKE         IKEv2:             FIPS  (sha)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  SHA2_256            IKEv1: IKE         IKEv2:             FIPS  (sha2 sha256)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  SHA2_384            IKEv1: IKE         IKEv2:             FIPS  (sha384)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  SHA2_512            IKEv1: IKE         IKEv2:             FIPS  (sha512)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: PRF algorithms:
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  HMAC_MD5            IKEv1: IKE         IKEv2: IKE               (md5)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  HMAC_SHA1           IKEv1: IKE         IKEv2: IKE         FIPS  (sha sha1)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  HMAC_SHA2_256       IKEv1: IKE         IKEv2: IKE         FIPS  (sha2 sha256 sha2_256)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  HMAC_SHA2_384       IKEv1: IKE         IKEv2: IKE         FIPS  (sha384 sha2_384)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  HMAC_SHA2_512       IKEv1: IKE         IKEv2: IKE         FIPS  (sha512 sha2_512)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  AES_XCBC            IKEv1:             IKEv2: IKE         FIPS  (aes128_xcbc)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: Integrity algorithms:
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  HMAC_MD5_96         IKEv1: IKE ESP AH  IKEv2: IKE ESP AH        (md5 hmac_md5)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  HMAC_SHA1_96        IKEv1: IKE ESP AH  IKEv2: IKE ESP AH  FIPS  (sha sha1 sha1_96 hmac_sha1)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  HMAC_SHA2_512_256   IKEv1: IKE ESP AH  IKEv2: IKE ESP AH  FIPS  (sha512 sha2_512 hmac_sha2_512)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  HMAC_SHA2_384_192   IKEv1: IKE ESP AH  IKEv2: IKE ESP AH  FIPS  (sha384 sha2_384 hmac_sha2_384)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  HMAC_SHA2_256_128   IKEv1: IKE ESP AH  IKEv2: IKE ESP AH  FIPS  (sha2 sha256 sha2_256 hmac_sha2_256)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  AES_XCBC_96         IKEv1:     ESP AH  IKEv2: IKE ESP AH  FIPS  (aes_xcbc aes128_xcbc aes128_xcbc_96)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  AES_CMAC_96         IKEv1:     ESP AH  IKEv2:     ESP AH  FIPS  (aes_cmac)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  NONE                IKEv1:     ESP     IKEv2:     ESP     FIPS  (null)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: DH algorithms:
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  NONE                IKEv1:             IKEv2: IKE ESP AH        (null dh0)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  MODP1024            IKEv1: IKE ESP AH  IKEv2: IKE ESP AH        (dh2)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  MODP1536            IKEv1: IKE ESP AH  IKEv2: IKE ESP AH        (dh5)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  MODP2048            IKEv1: IKE ESP AH  IKEv2: IKE ESP AH  FIPS  (dh14)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  MODP3072            IKEv1: IKE ESP AH  IKEv2: IKE ESP AH  FIPS  (dh15)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  MODP4096            IKEv1: IKE ESP AH  IKEv2: IKE ESP AH  FIPS  (dh16)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  MODP6144            IKEv1: IKE ESP AH  IKEv2: IKE ESP AH  FIPS  (dh17)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  MODP8192            IKEv1: IKE ESP AH  IKEv2: IKE ESP AH  FIPS  (dh18)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  DH19                IKEv1: IKE         IKEv2: IKE ESP AH  FIPS  (ecp_256)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  DH20                IKEv1: IKE         IKEv2: IKE ESP AH  FIPS  (ecp_384)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  DH21                IKEv1: IKE         IKEv2: IKE ESP AH  FIPS  (ecp_521)
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  DH22                IKEv1: IKE ESP AH  IKEv2: IKE ESP AH
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  DH23                IKEv1: IKE ESP AH  IKEv2: IKE ESP AH  FIPS
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]:  DH24                IKEv1: IKE ESP AH  IKEv2: IKE ESP AH  FIPS
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: starting up 2 crypto helpers
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: started thread for crypto helper 0
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: started thread for crypto helper 1
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: Using Linux XFRM/NETKEY IPsec interface code on 4.14.214-160.339.amzn2.x86_64
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: | selinux support is NOT enabled.
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: systemd watchdog for ipsec service configured with timeout of 200000000 usecs
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: watchdog: sending probes every 100 secs

    ==> /var/log/messages <==
    Feb  4 07:33:01 ip-10-30-0-133 systemd: Started Internet Key Exchange (IKE) Protocol Daemon for IPsec.

    ==> /var/log/secure <==
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: added connection description "vpnpsk"
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: listening for IKE messages
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: adding interface eth0/eth0 10.30.0.133:500
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: adding interface eth0/eth0 10.30.0.133:4500
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: adding interface lo/lo 127.0.0.1:500
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: adding interface lo/lo 127.0.0.1:4500
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: adding interface lo/lo ::1:500
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: | setup callback for interface lo:500 fd 19
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: | setup callback for interface lo:4500 fd 18
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: | setup callback for interface lo:500 fd 17
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: | setup callback for interface eth0:4500 fd 16
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: | setup callback for interface eth0:500 fd 15
    Feb  4 07:33:01 ip-10-30-0-133 pluto[4323]: loading secrets from "/etc/ipsec.secrets"
    ```

1. The example logs of `service xl2tpd start`:

    ```
    Feb  4 07:35:08 ip-10-30-0-133 systemd: Starting Level 2 Tunnel Protocol Daemon (L2TP)...
    Feb  4 07:35:08 ip-10-30-0-133 systemd: Started Level 2 Tunnel Protocol Daemon (L2TP).
    Feb  4 07:35:08 ip-10-30-0-133 xl2tpd: xl2tpd[4488]: Not looking for kernel SAref support.
    Feb  4 07:35:08 ip-10-30-0-133 xl2tpd: xl2tpd[4488]: Using l2tp kernel support.
    Feb  4 07:35:08 ip-10-30-0-133 xl2tpd: xl2tpd[4488]: xl2tpd version xl2tpd-1.3.15 started on ip-10-30-0-133.ap-northeast-1.compute.internal PID:4488
    Feb  4 07:35:08 ip-10-30-0-133 xl2tpd: xl2tpd[4488]: Written by Mark Spencer, Copyright (C) 1998, Adtran, Inc.
    Feb  4 07:35:08 ip-10-30-0-133 xl2tpd: xl2tpd[4488]: Forked by Scott Balmos and David Stipp, (C) 2001
    Feb  4 07:35:08 ip-10-30-0-133 xl2tpd: xl2tpd[4488]: Inherited by Jeff McAdams, (C) 2002
    Feb  4 07:35:08 ip-10-30-0-133 xl2tpd: xl2tpd[4488]: Forked again by Xelerance (www.xelerance.com) (C) 2006-2016
    Feb  4 07:35:08 ip-10-30-0-133 xl2tpd: xl2tpd[4488]: Listening on IP address 0.0.0.0, port 1701
    ```

1. The example logs for a successful client connection:

    The client's public IP address is masked as `xxxx.xxx.xxx.xxx`.
    The server's public IP address is masked as `yyy.yyy.yyy.yyy`.

    ```
    ==> /var/log/secure <==
    Feb  4 07:36:07 ip-10-30-0-133 pluto[4323]: "vpnpsk"[1] xxx.xxx.xxx.xxx #1: responding to Main Mode from unknown peer xxx.xxx.xxx.xxx on port 21484
    Feb  4 07:36:07 ip-10-30-0-133 pluto[4323]: "vpnpsk"[1] xxx.xxx.xxx.xxx #1: STATE_MAIN_R1: sent MR1, expecting MI2
    Feb  4 07:36:10 ip-10-30-0-133 pluto[4323]: "vpnpsk"[1] xxx.xxx.xxx.xxx #1: retransmitting in response to duplicate packet; already STATE_MAIN_R1
    Feb  4 07:36:10 ip-10-30-0-133 pluto[4323]: "vpnpsk"[1] xxx.xxx.xxx.xxx #1: STATE_MAIN_R2: sent MR2, expecting MI3
    Feb  4 07:36:10 ip-10-30-0-133 pluto[4323]: "vpnpsk"[1] xxx.xxx.xxx.xxx #1: ignoring informational payload IPSEC_INITIAL_CONTACT, msgid=00000000, length=28
    Feb  4 07:36:10 ip-10-30-0-133 pluto[4323]: | ISAKMP Notification Payload
    Feb  4 07:36:10 ip-10-30-0-133 pluto[4323]: |   00 00 00 1c  00 00 00 01  01 10 60 02
    Feb  4 07:36:10 ip-10-30-0-133 pluto[4323]: "vpnpsk"[1] xxx.xxx.xxx.xxx #1: Peer ID is ID_IPV4_ADDR: '192.168.31.201'
    Feb  4 07:36:10 ip-10-30-0-133 pluto[4323]: "vpnpsk"[1] xxx.xxx.xxx.xxx #1: STATE_MAIN_R3: sent MR3, ISAKMP SA established {auth=PRESHARED_KEY cipher=aes_256 integ=sha2_256 group=MODP2048}
    Feb  4 07:36:11 ip-10-30-0-133 pluto[4323]: "vpnpsk"[1] xxx.xxx.xxx.xxx #1: the peer proposed: yyy.yyy.yyy.yyy/32:17/1701 -> 192.168.31.201/32:17/0
    Feb  4 07:36:11 ip-10-30-0-133 pluto[4323]: "vpnpsk"[1] xxx.xxx.xxx.xxx #1: NAT-Traversal: received 2 NAT-OA. Using first, ignoring others
    Feb  4 07:36:11 ip-10-30-0-133 pluto[4323]: "vpnpsk"[1] xxx.xxx.xxx.xxx #2: responding to Quick Mode proposal {msgid:6e7bacfa}
    Feb  4 07:36:11 ip-10-30-0-133 pluto[4323]: "vpnpsk"[1] xxx.xxx.xxx.xxx #2:     us: 10.30.0.133/32===10.30.0.133<10.30.0.133>:17/1701
    Feb  4 07:36:11 ip-10-30-0-133 pluto[4323]: "vpnpsk"[1] xxx.xxx.xxx.xxx #2:   them: xxx.xxx.xxx.xxx:17/49787
    Feb  4 07:36:11 ip-10-30-0-133 pluto[4323]: "vpnpsk"[1] xxx.xxx.xxx.xxx #2: STATE_QUICK_R1: sent QR1, inbound IPsec SA installed, expecting QI2 transport mode {ESP/NAT=>0x0fa9b4b9 <0xb249dced xfrm=AES_CBC_256-HMAC_SHA2_256_128 NATOA=192.168.31.201 NATD=xxx.xxx.xxx.xxx:21487 DPD=active}
    Feb  4 07:36:11 ip-10-30-0-133 pluto[4323]: "vpnpsk"[1] xxx.xxx.xxx.xxx #2: STATE_QUICK_R2: IPsec SA established transport mode {ESP/NAT=>0x0fa9b4b9 <0xb249dced xfrm=AES_CBC_256-HMAC_SHA2_256_128 NATOA=192.168.31.201 NATD=xxx.xxx.xxx.xxx:21487 DPD=active}

    ==> /var/log/messages <==
    Feb  4 07:36:11 ip-10-30-0-133 xl2tpd: xl2tpd[4488]: check_control: Received out of order control packet on tunnel 16 (got 2, expected 1)
    Feb  4 07:36:11 ip-10-30-0-133 xl2tpd: xl2tpd[4488]: handle_control: bad control packet!
    Feb  4 07:36:11 ip-10-30-0-133 xl2tpd: xl2tpd[4488]: Connection established to xxx.xxx.xxx.xxx, 49787.  Local: 29098, Remote: 16 (ref=0/0).  LNS session is 'default'
    Feb  4 07:36:15 ip-10-30-0-133 xl2tpd: xl2tpd[4488]: Call established with xxx.xxx.xxx.xxx, PID: 4566, Local: 30697, Remote: 24558, Serial: 1
    Feb  4 07:36:15 ip-10-30-0-133 pppd[4566]: Plugin pppol2tp.so loaded.
    Feb  4 07:36:15 ip-10-30-0-133 pppd[4566]: pppd 2.4.5 started by root, uid 0
    Feb  4 07:36:15 ip-10-30-0-133 pppd[4566]: Using interface ppp0
    Feb  4 07:36:15 ip-10-30-0-133 pppd[4566]: Connect: ppp0 <-->
    Feb  4 07:36:28 ip-10-30-0-133 pppd[4566]: local  IP address 192.168.42.1
    Feb  4 07:36:28 ip-10-30-0-133 pppd[4566]: remote IP address 192.168.42.10
    ```

1. The example logs of the client side:

    The server's public IP address is masked as `yyy.yyy.yyy.yyy`.

    ```
    ==> /var/log/ppp.log <==
    Thu Feb  4 17:02:41 2021 : publish_entry SCDSet() failed: Success!
    Thu Feb  4 17:02:41 2021 : publish_entry SCDSet() failed: Success!
    Thu Feb  4 17:02:41 2021 : l2tp_get_router_address
    Thu Feb  4 17:02:41 2021 : l2tp_get_router_address 192.168.31.1 from dict 1
    Thu Feb  4 17:02:41 2021 : L2TP connecting to server 'yyy.yyy.yyy.yyy' (yyy.yyy.yyy.yyy)...
    Thu Feb  4 17:02:41 2021 : IPSec connection started
    Thu Feb  4 17:02:41 2021 : IPSec phase 1 client started
    Thu Feb  4 17:02:42 2021 : IPSec phase 1 server replied
    Thu Feb  4 17:02:46 2021 : IPSec phase 2 started
    Thu Feb  4 17:02:46 2021 : IPSec phase 2 established
    Thu Feb  4 17:02:46 2021 : IPSec connection established
    Thu Feb  4 17:02:46 2021 : L2TP sent SCCRQ
    Thu Feb  4 17:02:46 2021 : L2TP received SCCRP
    Thu Feb  4 17:02:46 2021 : L2TP sent SCCCN
    Thu Feb  4 17:02:46 2021 : L2TP sent ICRQ
    Thu Feb  4 17:02:46 2021 : L2TP received ICRP
    Thu Feb  4 17:02:46 2021 : L2TP sent ICCN
    Thu Feb  4 17:02:46 2021 : L2TP connection established.
    Thu Feb  4 17:02:46 2021 : L2TP set port-mapping for en0, interface: 4, protocol: 0, privatePort: 0
    Thu Feb  4 17:02:46 2021 : using link 0
    Thu Feb  4 17:02:46 2021 : Using interface ppp0
    Thu Feb  4 17:02:46 2021 : Connect: ppp0 <--> socket[34:18]
    Thu Feb  4 17:02:46 2021 : sent [LCP ConfReq id=0x1 <asyncmap 0x0> <magic 0x25a9887> <pcomp> <accomp>]
    Thu Feb  4 17:02:46 2021 : L2TP port-mapping for en0, interfaceIndex: 0, Protocol: None, Private Port: 0, Public Address: c0a80102, Public Port: 0, TTL: 0 (Double NAT)
    Thu Feb  4 17:02:46 2021 : L2TP port-mapping for en0 inconsistent. is Connected: 1, Previous interface: 4, Current interface 0
    Thu Feb  4 17:02:46 2021 : L2TP port-mapping for en0 initialized. is Connected: 1, Previous publicAddress: (0), Current publicAddress c0a80102
    Thu Feb  4 17:02:46 2021 : L2TP port-mapping for en0 fully initialized. Flagging up
    Thu Feb  4 17:02:46 2021 : rcvd [LCP ConfReq id=0x1 <asyncmap 0x0> <auth chap MD5> <magic 0x433cb823>]
    Thu Feb  4 17:02:46 2021 : lcp_reqci: returning CONFACK.
    Thu Feb  4 17:02:46 2021 : sent [LCP ConfAck id=0x1 <asyncmap 0x0> <auth chap MD5> <magic 0x433cb823>]
    Thu Feb  4 17:02:46 2021 : L2TP failed to set port-mapping for en0, errorCode: -65564
    Thu Feb  4 17:02:46 2021 : L2TP port-mapping for en0 became invalid. is Connected: 1, Protocol: None, Private Port: 0, Previous publicAddress: (c0a80102), Previous publicPort: (0)
    Thu Feb  4 17:02:46 2021 : L2TP public port-mapping for en0 changed... starting faster probe.
    Thu Feb  4 17:02:46 2021 : ppp_variable_echo_start
    Thu Feb  4 17:02:49 2021 : sent [LCP ConfReq id=0x1 <asyncmap 0x0> <magic 0x25a9887> <pcomp> <accomp>]
    Thu Feb  4 17:02:49 2021 : rcvd [LCP ConfReq id=0x1 <asyncmap 0x0> <auth chap MD5> <magic 0x433cb823>]
    Thu Feb  4 17:02:49 2021 : lcp_reqci: returning CONFACK.
    Thu Feb  4 17:02:49 2021 : sent [LCP ConfAck id=0x1 <asyncmap 0x0> <auth chap MD5> <magic 0x433cb823>]
    Thu Feb  4 17:02:49 2021 : rcvd [LCP ConfAck id=0x1 <asyncmap 0x0> <magic 0x25a9887> <pcomp> <accomp>]
    Thu Feb  4 17:02:49 2021 : sent [LCP EchoReq id=0x0 magic=0x25a9887]
    Thu Feb  4 17:02:49 2021 : rcvd [LCP EchoReq id=0x0 magic=0x433cb823]
    Thu Feb  4 17:02:49 2021 : sent [LCP EchoRep id=0x0 magic=0x25a9887]
    Thu Feb  4 17:02:49 2021 : rcvd [CHAP Challenge id=0x91 <d2056d17b247c22cc163ba667fc7560af2a4ae110e7679>, name = "l2tpd"]
    Thu Feb  4 17:02:49 2021 : sent [CHAP Response id=0x91 <5c6c34702a53a3be8541509faa106148>, name = "vpnuser"]
    Thu Feb  4 17:02:49 2021 : rcvd [LCP EchoRep id=0x0 magic=0x433cb823]
    Thu Feb  4 17:02:49 2021 : received echo-reply, ppp_variable_echo_stop!
    Thu Feb  4 17:02:49 2021 : rcvd [CHAP Success id=0x91 "Access granted"]
    Thu Feb  4 17:02:49 2021 : CHAP authentication succeeded: Access granted
    Thu Feb  4 17:02:49 2021 : sent [IPCP ConfReq id=0x1 <addr 0.0.0.0> <ms-dns1 0.0.0.0> <ms-dns3 0.0.0.0>]
    Thu Feb  4 17:02:49 2021 : sent [IPV6CP ConfReq id=0x1 <addr fe80::8e85:90ff:fe3f:afb9>]
    Thu Feb  4 17:02:49 2021 : sent [ACSCP ConfReq id=0x1 <route vers 16777216> <domain vers 16777216>]
    Thu Feb  4 17:02:49 2021 : rcvd [IPCP ConfReq id=0x1 <addr 192.168.42.1>]
    Thu Feb  4 17:02:49 2021 : ipcp: returning Configure-ACK
    Thu Feb  4 17:02:49 2021 : sent [IPCP ConfAck id=0x1 <addr 192.168.42.1>]
    Thu Feb  4 17:02:49 2021 : rcvd [LCP ProtRej id=0x2 82 35 01 01 00 10 01 06 00 00 00 01 02 06 00 00 00 01]
    Thu Feb  4 17:02:49 2021 : rcvd [LCP ProtRej id=0x3 80 57 01 01 00 0e 01 0a 8e 85 90 ff fe 3f af b9]
    Thu Feb  4 17:02:49 2021 : rcvd [IPCP ConfNak id=0x1 <addr 192.168.42.10> <ms-dns1 8.8.8.8> <ms-dns3 8.8.4.4>]
    Thu Feb  4 17:02:49 2021 : sent [IPCP ConfReq id=0x2 <addr 192.168.42.10> <ms-dns1 8.8.8.8> <ms-dns3 8.8.4.4>]
    Thu Feb  4 17:02:49 2021 : rcvd [IPCP ConfAck id=0x2 <addr 192.168.42.10> <ms-dns1 8.8.8.8> <ms-dns3 8.8.4.4>]
    Thu Feb  4 17:02:49 2021 : ipcp: up
    Thu Feb  4 17:02:49 2021 : local  IP address 192.168.42.10
    Thu Feb  4 17:02:49 2021 : remote IP address 192.168.42.1
    Thu Feb  4 17:02:49 2021 : primary   DNS address 8.8.8.8
    Thu Feb  4 17:02:49 2021 : secondary DNS address 8.8.4.4
    Thu Feb  4 17:02:49 2021 : Received protocol dictionaries
    Thu Feb  4 17:02:49 2021 : sent [IP data <src addr 192.168.42.10> <dst addr 255.255.255.255> <BOOTP Request> <type INFORM> <client id 0x08000000010000> <parameters = 0x6 0x2c 0x2b 0x1 0xf9 0xf>]
    Thu Feb  4 17:02:49 2021 : Received acsp/dhcp dictionaries
    Thu Feb  4 17:02:49 2021 : Received acsp/dhcp dictionaries
    Thu Feb  4 17:02:49 2021 : l2tp_wait_input: Address added. previous interface setting (name: en0, address: 192.168.31.201), current interface setting (name: ppp0, family: PPP, address: 192.168.42.10, subnet: 255.255.255.0, destination: 192.168.42.1).
    Thu Feb  4 17:02:49 2021 : Committed PPP store on install command
    Thu Feb  4 17:02:49 2021 : Committed PPP store on install command
    Thu Feb  4 17:02:52 2021 : sent [IP data <src addr 192.168.42.10> <dst addr 255.255.255.255> <BOOTP Request> <type INFORM> <client id 0x08000000010000> <parameters = 0x6 0x2c 0x2b 0x1 0xf9 0xf>]
    Thu Feb  4 17:02:53 2021 : L2TP port-mapping for en0, interfaceIndex: 0, Protocol: None, Private Port: 0, Public Address: 0, Public Port: 0, TTL: 0.
    Thu Feb  4 17:02:53 2021 : L2TP port-mapping for en0 indicates public interface down. Public Address: 0, Protocol: None, Private Port: 0, Public Port: 0
    Thu Feb  4 17:02:53 2021 : starting wait-port-mapping timer for L2TP: 20 secs
    Thu Feb  4 17:02:55 2021 : sent [IP data <src addr 192.168.42.10> <dst addr 255.255.255.255> <BOOTP Request> <type INFORM> <client id 0x08000000010000> <parameters = 0x6 0x2c 0x2b 0x1 0xf9 0xf>]
    Thu Feb  4 17:02:55 2021 : Received acsp/dhcp dictionaries
    Thu Feb  4 17:02:55 2021 : Committed PPP store on install command
    Thu Feb  4 17:02:58 2021 : sent [IP data <src addr 192.168.42.10> <dst addr 255.255.255.255> <BOOTP Request> <type INFORM> <client id 0x08000000010000> <parameters = 0x6 0x2c 0x2b 0x1 0xf9 0xf>]
    Thu Feb  4 17:03:01 2021 : sent [IP data <src addr 192.168.42.10> <dst addr 255.255.255.255> <BOOTP Request> <type INFORM> <client id 0x08000000010000> <parameters = 0x6 0x2c 0x2b 0x1 0xf9 0xf>]
    Thu Feb  4 17:03:04 2021 : No DHCP server replied
    Thu Feb  4 17:03:13 2021 : ppp_variable_echo_start
    Thu Feb  4 17:03:14 2021 : received echo-reply, ppp_variable_echo_stop!
    ```

1. The example output of running process on the remote server with a successful connection:

    ```
    ps -ef | grep pppd
    root      5414  5285  0 07:42 ?        00:00:00 /usr/sbin/pppd plugin pppol2tp.so pppol2tp 7 pppol2tp_lns_mode pppol2tp_tunnel_id 3726 pppol2tp_session_id 15932 passive nodetach 192.168.42.1:192.168.42.10 refuse-pap auth require-chap name l2tpd file /etc/ppp/options.xl2tpd
    ```

1. The example output of the opened UDP ports:

    The client's public IP address is masked as `xxxx.xxx.xxx.xxx`.

    ```
    # netstat -uanp | egrep '(pluto|xl2tpd)'
    Active Internet connections (servers and established)
    Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
    udp        0      0 127.0.0.1:500           0.0.0.0:*                           28245/pluto
    udp        0      0 10.30.0.133:500         0.0.0.0:*                           28245/pluto
    udp        0      0 0.0.0.0:1701            0.0.0.0:*                           28310/xl2tpd
    udp        0      0 127.0.0.1:4500          0.0.0.0:*                           28245/pluto
    udp        0      0 10.30.0.133:4500        0.0.0.0:*                           28245/pluto
    udp6       0      0 ::1:500                 :::*                                28245/pluto

    ## after the l2tp client connected, following added:
    udp        0      0 192.168.42.1:4500       0.0.0.0:*                           28245/pluto
    udp        0      0 192.168.42.1:500        0.0.0.0:*                           28245/pluto
    udp        0      0 10.30.0.133:1701        xxx.xxx.xxx.xxx:60507    ESTABLISHED 5285/xl2tpd
    ```

1. The example output of the opened TCP ports:

    ```
    # netstat -uanp | egrep '(pluto|xl2tpd)'
    ## nothing
    ```
