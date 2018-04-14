#!/bin/bash

clear
echo "This script will refresh your masternode."
read -p "Press Ctrl-C to abort or any other key to continue. " -n1 -s
clear

if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root."
  exit 1
fi

USER=`ps u $(pgrep bulwarkd) | grep bulwarkd | cut -d " " -f 1`
USERHOME=`eval echo "~$USER"`

if [ -e /etc/systemd/system/bulwarkd.service ]; then
  systemctl stop bulwarkd
else
  su -c "bulwark-cli stop" $BWKUSER
fi

echo "Refreshing node, please wait."

sleep 5

rm -rf $USERHOME/.bulwark/blocks
rm -rf $USERHOME/.bulwark/database
rm -rf $USERHOME/.bulwark/chainstate
rm -rf $USERHOME/.bulwark/peers.dat

cp $USERHOME/.bulwark/bulwark.conf $USERHOME/.bulwark/bulwark.conf.backup
sed -i '/^addnode/d' $USERHOME/.bulwark/bulwark.conf

if [ -e /etc/systemd/system/bulwarkd.service ]; then
  sudo systemctl start bulwarkd
else
  su -c "bulwarkd -daemon" $USER
fi

echo "Your masternode is syncing. Please wait for this process to finish."
echo "This can take up to a few hours. Do not close this window." && echo ""

until su -c "bulwark-cli startmasternode local false 2>/dev/null | grep 'successfully started' > /dev/null" $USER; do
  for (( i=0; i<${#CHARS}; i++ )); do
    sleep 2
    echo -en "${CHARS:$i:1}" "\r"
  done
done

sleep 1
su -c "/usr/local/bin/bulwark-cli startmasternode local false" $USER
sleep 1
clear
su -c "/usr/local/bin/bulwark-cli masternode status" $USER
sleep 5

echo "" && echo "Masternode refresh completed." && echo ""
