#!/bin/bash

# Make sure curl is installed
apt-get -qq update
apt -qqy install curl
clear

TARBALLURL=$(curl -s https://api.github.com/repos/bulwark-crypto/bulwark/releases/latest | grep browser_download_url | grep -e "bulwark-node.*linux64" | cut -d '"' -f 4)
TARBALLNAME=$(curl -s https://api.github.com/repos/bulwark-crypto/bulwark/releases/latest | grep browser_download_url | grep -e "bulwark-node.*linux64" | cut -d '"' -f 4 | cut -d "/" -f 9)
BWKVERSION=$(curl -s https://api.github.com/repos/bulwark-crypto/bulwark/releases/latest | grep browser_download_url | grep -e "bulwark-node.*linux64" | cut -d '"' -f 4 | cut -d "/" -f 8)

LOCALVERSION=$(bulwark-cli --version)
REMOTEVERSION=$(curl -s https://api.github.com/repos/bulwark-crypto/bulwark/releases/latest | jq -r ".tag_name")

if [[ "$LOCALVERSION" = "$REMOTEVERSION" ]]; then
  echo "No update necessary."
  exit
fi

clear
echo "This script will update your masternode to version $BWKVERSION"
read -rp "Press Ctrl-C to abort or any other key to continue. " -n1 -s
clear

if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root."
  exit 1
fi

USER=$(ps -o user= -p "$(pgrep bulwarkd)")
USERHOME=$(eval echo "~$USER")

echo "Downloading new version..."
wget "$TARBALLURL"

echo "Shutting down masternode..."
if [ -e /etc/systemd/system/bulwarkd.service ]; then
  systemctl stop bulwarkd
else
  su -c "bulwark-cli stop" "$USER"
fi

echo "Installing Bulwark $BWKVERSION..."
rm /usr/local/bin/bulwarkd /usr/local/bin/bulwark-cli
tar -xzvf "$TARBALLNAME" -C /usr/local/bin
rm "$TARBALLNAME"

if [ -e /usr/bin/bulwarkd ];then rm -rf /usr/bin/bulwarkd; fi
if [ -e /usr/bin/bulwark-cli ];then rm -rf /usr/bin/bulwark-cli; fi
if [ -e /usr/bin/bulwark-tx ];then rm -rf /usr/bin/bulwark-tx; fi

# Remove addnodes from bulwark.conf
sed -i '/^addnode/d' "$USERHOME/.bulwark/bulwark.conf"

# Add Fail2Ban memory hack if needed
if ! grep -q "ulimit -s 256" /etc/default/fail2ban; then
  echo "ulimit -s 256" | sudo tee -a /etc/default/fail2ban
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
After=network-online.target
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

sleep 10

clear

if ! systemctl status bulwarkd | grep -q "active (running)"; then
  echo "ERROR: Failed to start bulwarkd. Please contact support."
  exit
fi

echo "Installing Bulwark Autoupdater..."
rm -f /usr/local/bin/bulwarkupdate
curl -o /usr/local/bin/bulwarkupdate https://raw.githubusercontent.com/bulwark-crypto/Bulwark-MN-Install/master/bulwarkupdate
chmod a+x /usr/local/bin/bulwarkupdate

if [ ! -f /etc/systemd/system/bulwarkupdate.service ]; then
cat > /etc/systemd/system/bulwarkupdate.service << EOL
[Unit]
Description=Bulwarks's Masternode Autoupdater
After=network-online.target
[Service]
Type=oneshot
User=root
WorkingDirectory=${USERHOME}
ExecStart=/usr/local/bin/bulwarkupdate
EOL
fi

if [ ! -f /etc/systemd/system/bulwarkupdate.timer ]; then
cat > /etc/systemd/system/bulwarkupdate.timer << EOL
[Unit]
Description=Bulwarks's Masternode Autoupdater Timer

[Timer]
OnBootSec=1d
OnUnitActiveSec=1d 

[Install]
WantedBy=timers.target
EOL
fi

systemctl enable bulwarkupdate.timer
systemctl start bulwarkupdate.timer

echo "Waiting for wallet to load..."
until su -c "bulwark-cli getinfo 2>/dev/null | grep -q \"version\"" "$USER"; do
  sleep 1;
done

clear

echo "Your masternode is syncing. Please wait for this process to finish."
echo "This can take up to a few hours. Do not close this window."
echo ""

until su -c "bulwark-cli mnsync status 2>/dev/null | grep '\"IsBlockchainSynced\": true' > /dev/null" "$USER"; do 
  echo -ne "Current block: $(su -c "bulwark-cli getblockcount" "$USER")\\r"
  sleep 1
done

clear

cat << EOL

Now, you need to start your masternode. If you haven't already, please add this
node to your masternode.conf now, restart and unlock your desktop wallet, go to
the Masternodes tab, select your new node and click "Start Alias."

EOL

read -rp "Press Enter to continue after you've done that. " -n1 -s

clear

su -c "bulwark-cli masternode status" "$USER"

cat << EOL

Masternode update completed.

EOL
