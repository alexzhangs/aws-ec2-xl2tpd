# aws-ec2-xl2tpd

Install xl2tpd and openswan on AWS EC2 instance.

## Installation

```
# get code
git clone https://github.com/alexzhangs/aws-ec2-xl2tpd

# install with root permission
sh aws-ec2-xl2tpd/install.sh
```

Following inbound rules are necessary for the security group of the
EC2 instance:

| Type | Protocol | Port range | Source |
|---|---|---|---|
| Custom UDP | UDP | 4500 | 0.0.0.0/0 |
| Custom UDP | UDP | 500 | 0.0.0.0/0 |

NOTE: DON'T list the UDP port `1701` in the inboud rules, It should be
never opened to the outside.

## Reference

* https://serverfault.com/questions/451381/which-ports-for-ipsec-lt2p
