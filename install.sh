#!/bin/bash
clear

# Set these to change the version of Bulwark to install
TARBALLURL="https://github.com/bulwark-crypto/Bulwark/releases/download/1.2.3/bulwark-1.2.3.0-linux64.tar.gz"
TARBALLNAME="bulwark-1.2.3.0-linux64.tar.gz"
BOOTSTRAPURL="https://github.com/bulwark-crypto/Bulwark/releases/download/1.2.3/bootstrap.dat.zip"
BOOTSTRAPARCHIVE="bootstrap.dat.zip"
BWKVERSION="1.2.3.0"

# Check if we are root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root." 1>&2
   exit 1
fi

# Install tools for dig and systemctl
echo "Preparing installation..."
apt-get install dnsutils systemd -y > /dev/null 2>&1

# Check for systemd
systemctl --version >/dev/null 2>&1 || { echo "systemd is required. Are you using Ubuntu 16.04?"  >&2; exit 1; }

# CHARS is used for the loading animation further down.
CHARS="/-\|"
EXTERNALIP=`dig +short myip.opendns.com @resolver1.opendns.com`
clear

cat  << EOF
  ______  _     _ _      _  _  _       ______  _    _
 (____  \| |   | | |    | || || |  /\ (_____ \| |  / )
  ____)  ) |   | | |    | || || | /  \ _____) ) | / /
 |  __  (| |   | | |    | ||_|| |/ /\ (_____ (| |< <
 | |__)  ) |___| | |____| |___| | |__| |    | | | \ \
 |______/ \______|_______)______|______|    |_|_|  \_)

              MASTERNODE INSTALLER v2
EOF
sleep 2

cat << EOF
    ___T_
   | o o |
   |__-__|
   /| []|\
 ()/|___|\()
    |_|_|
    /_|_\  ----------------------------------------+
 |                                                |
 |You can choose between two installation options:|::
 |             default and advanced.              |::
 |                                                |::
 | The advanced installation will install and run |::
 |  the masternode under a non-root user. If you  |::
 |  don't know what that means, use the default   |::
 |              installation method.              |::
 |                                                |::
 | Otherwise, your masternode will not work, and  |::
 |the Bulwark Team CANNOT assist you in repairing |::
 |        it. You will have to start over.        |::
 |                                                |::
 |Don't use the advanced option unless you are an |::
 |            experienced Linux user.             |::
 |                                                |::
 |                                                |::
 +------------------------------------------------+::
   ::::::::::::::::::::::::::::::::::::::::::::::::::

EOF

sleep 5

read -e -p "Use the Advanced Installation? [N/y] : " ADVANCED

if [[ ("$ADVANCED" == "y" || "$ADVANCED" == "Y") ]]; then

USER=bulwark

adduser $USER --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password > /dev/null

echo "" && echo 'Added user "bulwark"' && echo ""
sleep 1

else

USER=root

fi

USERHOME=`eval echo "~$USER"`

read -e -p "Server IP Address: " -i $EXTERNALIP -e IP
read -e -p "Masternode Private Key (e.g. 7edfjLCUzGczZi3JQw8GHp434R9kNY33eFyMGeKRymkB56G4324h # THE KEY YOU GENERATED EARLIER) : " KEY
read -e -p "Install Fail2ban? [Y/n] : " FAIL2BAN
read -e -p "Install UFW and configure ports? [Y/n] : " UFW
read -e -p "Do you want to use our bootstrap file to speed the syncing process? [Y/n] : " BOOTSTRAP

clear

# Generate random passwords
RPCUSER=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)
RPCPASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

# update packages and upgrade Ubuntu
echo "Installing dependencies..."
apt-get -qq update
apt-get -qq upgrade
apt-get -qq autoremove
apt-get -qq install wget htop unzip
apt-get -qq install build-essential && apt-get -qq install libtool autotools-dev autoconf automake && apt-get -qq install libssl-dev && apt-get -qq install libboost-all-dev && apt-get -qq install software-properties-common && add-apt-repository -y ppa:bitcoin/bitcoin && apt update && apt-get -qq install libdb4.8-dev && apt-get -qq install libdb4.8++-dev && apt-get -qq install libminiupnpc-dev && apt-get -qq install libqt4-dev libprotobuf-dev protobuf-compiler && apt-get -qq install libqrencode-dev && apt-get -qq install git && apt-get -qq install pkg-config apt-get -qq install libzmq3-dev
apt-get -qq install aptitude

# Install Fail2Ban
if [[ ("$FAIL2BAN" == "y" || "$FAIL2BAN" == "Y" || "$FAIL2BAN" == "") ]]; then
  aptitude -y -q install fail2ban
  service fail2ban restart
fi

# Install UFW
if [[ ("$UFW" == "y" || "$UFW" == "Y" || "$UFW" == "") ]]; then
  apt-get -qq install ufw
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow ssh
  ufw allow 52543/tcp
  yes | ufw enable
fi

# Install Bulwark daemon
wget $TARBALLURL
tar -xzvf $TARBALLNAME && mv bin bulwark-$BWKVERSION
rm $TARBALLNAME
cp ./bulwark-$BWKVERSION/bulwarkd /usr/local/bin
cp ./bulwark-$BWKVERSION/bulwark-cli /usr/local/bin
cp ./bulwark-$BWKVERSION/bulwark-tx /usr/local/bin
rm -rf bulwark-$BWKVERSION

# Create .bulwark directory
mkdir $USERHOME/.bulwark

# Install bootstrap file
if [[ ("$BOOTSTRAP" == "y" || "$BOOTSTRAP" == "Y" || "$BOOTSTRAP" == "") ]]; then
  echo "Installing bootstrap file..."
  wget $BOOTSTRAPURL && unzip $BOOTSTRAPARCHIVE -d $USERHOME/.bulwark/ && rm $BOOTSTRAPARCHIVE
fi

# Create bulwark.conf
touch $USERHOME/.bulwark/bulwark.conf
cat > $USERHOME/.bulwark/bulwark.conf << EOL
rpcuser=${RPCUSER}
rpcpassword=${RPCPASSWORD}
rpcallowip=127.0.0.1
listen=1
server=1
daemon=1
logtimestamps=1
maxconnections=256
externalip=${IP}
bind=${IP}:52543
masternodeaddr=${IP}
masternodeprivkey=${KEY}
masternode=1
EOL
chmod 0600 $USERHOME/.bulwark/bulwark.conf
chown -R $USER:$USER $USERHOME/.bulwark

sleep 1

cat > /etc/systemd/system/bulwarkd.service << EOL
[Unit]
Description=bulwarkd
After=network.target
[Service]
Type=forking
User=${USER}
WorkingDirectory=${USERHOME}
ExecStart=/usr/local/bin/bulwarkd -conf=${USERHOME}/.bulwark/bulwark.conf -datadir=${USERHOME}/.bulwark
ExecStop=/usr/local/bin/bulwark-cli -conf=${USERHOME}/.bulwark/bulwark.conf -datadir=${USERHOME}/.bulwark stop
Restart=on-abort
[Install]
WantedBy=multi-user.target
EOL
sudo systemctl enable bulwarkd
sudo systemctl start bulwarkd

clear

cat << EOF

Now, you need to start your masternode. Please go to your desktop wallet and
enter the following line into your debug console:

startmasternode alias false <mymnalias>

where <mymnalias> is the name of your masternode alias (without brackets)

EOF

read -p "Press any key to continue after you've done that. " -n1 -s

clear

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

echo "" && echo "Masternode setup completed." && echo ""
