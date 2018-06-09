#!/bin/bash

TARBALLURL="https://github.com/bulwark-crypto/Bulwark/releases/download/1.2.4/bulwark-1.2.4.0-linux64.tar.gz"
TARBALLNAME="bulwark-1.2.4.0-linux64.tar.gz"
BWKVERSION="1.2.4.0"

CHARS="/-\|"

clear
echo "This script will update your masternode to version $BWKVERSION"
read -p "Press Ctrl-C to abort or any other key to continue. " -n1 -s
clear

if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root."
  exit 1
fi

USER=`ps u $(pgrep bulwarkd) | grep bulwarkd | cut -d " " -f 1`
USERHOME=`eval echo "~$USER"`

echo "Shutting down masternode..."
if [ -e /etc/systemd/system/bulwarkd.service ]; then
  systemctl stop bulwarkd
else
  su -c "bulwark-cli stop" $USER
fi

echo "Installing Bulwark $BWKVERSION..."
mkdir ./bulwark-temp && cd ./bulwark-temp
wget $TARBALLURL
tar -xzvf $TARBALLNAME && mv bin bulwark-$BWKVERSION
yes | cp -rf ./bulwark-$BWKVERSION/bulwarkd /usr/local/bin
yes | cp -rf ./bulwark-$BWKVERSION/bulwark-cli /usr/local/bin
cd ..
rm -rf ./bulwark-temp

if [ -e /usr/bin/bulwarkd ];then rm -rf /usr/bin/bulwarkd; fi
if [ -e /usr/bin/bulwark-cli ];then rm -rf /usr/bin/bulwark-cli; fi
if [ -e /usr/bin/bulwark-tx ];then rm -rf /usr/bin/bulwark-tx; fi

# Remove addnodes from bulwark.conf
sed -i '/^addnode/d' $USERHOME/.bulwark/bulwark.conf

# Add Fail2Ban memory hack if needed
if ! grep -q "ulimit -s 256" /etc/default/fail2ban; then
  echo "ulimit -s 256" >> /etc/default/fail2ban
  systemctl restart fail2ban
fi

echo "Restarting Bulwark daemon..."
if [ -e /etc/systemd/system/bulwarkd.service ]; then
  systemctl disable bulwarkd
  rm /etc/systemd/system/bulwarkd.service
fi

cat > /etc/systemd/system/bulwarkd.service << EOL
[Unit]
Description=Bulwarks's distributed currency daemon
After=network.target
[Service]
Type=forking
User=${USER}
WorkingDirectory=${USERHOME}
ExecStart=/usr/local/bin/bulwarkd -conf=${USERHOME}/.bulwark/bulwark.conf -datadir=${USERHOME}/.bulwark
ExecStop=/usr/local/bin/bulwark-cli -conf=${USERHOME}/.bulwark/bulwark.conf -datadir=${USERHOME}/.bulwark stop
Restart=on-failure
RestartSec=1m
StartLimitIntervalSec=5m
StartLimitInterval=5m
StartLimitBurst=3
[Install]
WantedBy=multi-user.target
EOL
sudo systemctl enable bulwarkd
sudo systemctl start bulwarkd

clear

echo "Your masternode is syncing. Please wait for this process to finish."

until su -c "bulwark-cli mnsync status 2>/dev/null | grep '\"IsBlockchainSynced\" : true' > /dev/null" $USER; do
  for (( i=0; i<${#CHARS}; i++ )); do
    sleep 2
    echo -en "${CHARS:$i:1}" "\r"
  done
done

clear

cat << EOL

Now, you need to start your masternode. Please go to your desktop wallet and
enter the following line into your debug console:

startmasternode alias false <mymnalias>

where <mymnalias> is the name of your masternode alias (without brackets)

EOL

read -p "Press Enter to continue after you've done that. " -n1 -s

clear

su -c "bulwark-cli masternode status" $USER

cat << EOL

Masternode update completed.

EOL
