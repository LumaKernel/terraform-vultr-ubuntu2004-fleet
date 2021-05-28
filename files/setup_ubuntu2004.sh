#!/bin/bash

function ipv4mask_to_num {
  local ipv4mask=$1
  local arr=(${ipv4mask//./ })
  local num=0
  for n in ${arr[@]}; do
    local bin=$(echo "obase=2;$n" | bc)
    local cnt1=$(echo -n $bin | sed -e 's/0//g' | wc -c)
    (( num += cnt1 ))
  done
  echo -n $num
}

{
useradd --home-dir /home/work --shell /bin/bash --create-home work
usermod -aG sudo work
sed -i -e 's/^PermitRootLogin\s.*$/PermitRootLogin no/g' /etc/ssh/sshd_config
sed -i -e 's/^\s*#\?\s*PasswordAuthentication\s.*$/PasswordAuthentication no/g' /etc/ssh/sshd_config
sudo -u work mkdir -p /home/work/.ssh
cp /root/.ssh/authorized_keys /home/work/.ssh/authorized_keys
chown -R work:work /home/work
echo "work    ALL=NOPASSWD: ALL" >> /etc/sudoers
service ssh reload

# https://www.vultr.com/docs/how-to-configure-a-private-network-on-ubuntu
# https://www.vultr.com/metadata/#using_the_api
MAC_ADDR="$(ip addr | grep '^[[:digit:]]\+: ens7:' -A 1 | tail -n 1 | awk '{ print $2 }')"
PRIVATE_IP="$(curl http://169.254.169.254/v1/interfaces/1/ipv4/address)"
PRIVATE_IP_MASK="$(curl http://169.254.169.254/v1/interfaces/1/ipv4/netmask)"
PRIVATE_IP_MASK_NUM="$(ipv4mask_to_num "$PRIVATE_IP_MASK")"
cat <<EOF >> "/home/work/.bashrc"
export MAC_ADDR="$MAC_ADDR"
export PRIVATE_IP="$PRIVATE_IP"
export PRIVATE_IP_MASK="$PRIVATE_IP_MASK"
export PRIVATE_IP_MASK_NUM="$PRIVATE_IP_MASK_NUM"
EOF
cat <<EOF >> /etc/netplan/10-ens7.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens7:
      match:
        macaddress: ${MAC_ADDR}
      mtu: 1450
      dhcp4: no
      addresses: [${PRIVATE_IP}/${PRIVATE_IP_MASK_NUM}]
EOF
netplan apply
}

sudo -u work /bin/bash <<'END_OF_WORK'
{
source "$HOME/.bashrc"

## initialize
sudo apt-get update

## additional works...
}
END_OF_WORK
