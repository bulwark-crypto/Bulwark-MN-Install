#!/bin/bash

# Make installer interactive and select normal mode by default.
INTERACTIVE="y"
ADVANCED="n"
I2PREADY="n"

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -a|--advanced)
    ADVANCED="y"
    shift
    ;;
    -n|--normal)
    ADVANCED="n"
    FAIL2BAN="y"
    UFW="y"
    BOOTSTRAP="y"
    shift
    ;;
    -i|--externalip)
    EXTERNALIP="$2"
    ARGUMENTIP="y"
    shift
    shift
    ;;
    --bindip)
    BINDIP="$2"
    shift
    shift
    ;;
    -k|--privatekey)
    KEY="$2"
    shift
    shift
    ;;
    -f|--fail2ban)
    FAIL2BAN="y"
    shift
    ;;
    --no-fail2ban)
    FAIL2BAN="n"
    shift
    ;;
    -u|--ufw)
    UFW="y"
    shift
    ;;
    --no-ufw)
    UFW="n"
    shift
    ;;
    -b|--bootstrap)
    BOOTSTRAP="y"
    shift
    ;;
    --no-bootstrap)
    BOOTSTRAP="n"
    shift
    ;;
    --no-interaction)
    INTERACTIVE="n"
    shift
    ;;
    --tor)
    TOR="y"
    shift
    ;;
     --i2p)
    I2P="y"
    shift
    ;;
    -h|--help)
    cat << EOL

Bulwark Masternode installer arguments:

    -n --normal               : Run installer in normal mode
    -a --advanced             : Run installer in advanced mode
    -i --externalip <address> : Public IP address of VPS
    --bindip <address>        : Internal bind IP to use
    -k --privatekey <key>     : Private key to use
    -f --fail2ban             : Install Fail2Ban
    --no-fail2ban             : Do nott install Fail2Ban
    -u --ufw                  : Install UFW
    --no-ufw                  : Do not install UFW
    -b --bootstrap            : Sync node using Bootstrap
    --no-bootstrap            : Do not use Bootstrap
    -h --help                 : Display this help text.
    --no-interaction          : Do not wait for wallet activation.
    --tor                     : Install TOR and configure bulwarkd to use it
    --i2p                     : Install I2P (Requires 2GB of RAM)

EOL
    exit
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

clear

# Make sure curl is installed
apt-get update
apt-get install -qqy curl
clear

# These should automatically find the latest version of Bulwark

TARBALLURL=$(curl -s https://api.github.com/repos/bulwark-crypto/bulwark/releases/latest | grep browser_download_url | grep -e "bulwark-node.*linux64" | cut -d '"' -f 4)
TARBALLNAME=$(curl -s https://api.github.com/repos/bulwark-crypto/bulwark/releases/latest | grep browser_download_url | grep -e "bulwark-node.*linux64" | cut -d '"' -f 4 | cut -d "/" -f 9)
BOOTSTRAPURL=$(curl -s https://api.github.com/repos/bulwark-crypto/bulwark/releases/latest | grep bootstrap.dat.xz | grep browser_download_url | cut -d '"' -f 4)
BOOTSTRAPARCHIVE="bootstrap.dat.xz"
I2PBINURL="https://github.com/kewagi/kovri/releases/download/v0.1.0-alpha/kovri-0.1.0-alpha.tar.gz"
I2PBINARCHIVE="kovri-0.1.0-alpha.tar.gz"
I2PCONFURL="https://github.com/kewagi/kovri/releases/download/v0.1.0-alpha/kovri-conf.tar.gz"
I2PCONFARCHIVE="kovri-conf.tar.gz"

#!/bin/bash

# Check if we are root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root." 1>&2
   exit 1
fi

# Check if we have enough memory
if [[ $(free -m | awk '/^Mem:/{print $2}') -lt 850 ]]; then
  echo "This installation requires at least 1GB of RAM.";
  exit 1
fi

# TODO: Uncomment once we release I2P
# Check if I2P is an option
# if [[ $(free -m | awk '/^Mem:/{print $2}') -gt 1700 ]]; then
#   I2PREADY="y"
# fi

# Check if we have enough disk space
if [[ $(df -k --output=avail / | tail -n1) -lt 10485760 ]]; then
  echo "This installation requires at least 10GB of free disk space.";
  exit 1
fi

# Install tools for dig and systemctl
echo "Preparing installation..."
apt-get install git dnsutils systemd -y > /dev/null 2>&1

# Check for systemd
systemctl --version >/dev/null 2>&1 || { echo "systemd is required. Are you using Ubuntu 16.04?"  >&2; exit 1; }

# Get our current IP
IPV4=$(dig +short myip.opendns.com @resolver1.opendns.com)
IPV6=$(dig +short -6 myip.opendns.com aaaa @resolver1.ipv6-sandbox.opendns.com)
if [ -z "$EXTERNALIP" ]; then
  if [ ! -z "$IPV4" ]; then
    EXTERNALIP="$IPV4"
  else
    EXTERNALIP="$IPV6"
  fi
fi
clear

if [[ $INTERACTIVE = "y" ]]; then
echo "
    ___T_
   | o o |
   |__-__|
   /| []|\\\\
 ()/|___|\\()
    |_|_|
    /_|_\\  ------- MASTERNODE INSTALLER v4 -------+
 |                                                  |
 |   Welcome to the Bulwark Masternode Installer!   |::
 |                                                  |::
 +------------------------------------------------+::
   ::::::::::::::::::::::::::::::::::::::::::::::::::

"

sleep 3
fi

if [[ ("$ADVANCED" == "y" || "$ADVANCED" == "Y") ]]; then

USER=bulwark

adduser $USER --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password > /dev/null

INSTALLERUSED="#Used Advanced Install"

echo "" && echo 'Added user "bulwark"' && echo ""
sleep 1

else

USER=root

if [ -z "$FAIL2BAN" ]; then
  FAIL2BAN="y"
fi
if [ -z "$UFW" ]; then
  UFW="y"
fi
if [ -z "$BOOTSTRAP" ]; then
  BOOTSTRAP="y"
fi
INSTALLERUSED="#Used Basic Install"
fi

USERHOME=$(eval echo "~$USER")

if [ -z "$ARGUMENTIP" ]; then
  read -erp "Server IP Address: " -i "$EXTERNALIP" -e EXTERNALIP
fi

if [ -z "$BINDIP" ]; then
    BINDIP=$EXTERNALIP;
fi

if [ -z "$KEY" ]; then
  read -erp "Masternode Private Key (e.g. 7edfjLCUzGczZi3JQw8GHp434R9kNY33eFyMGeKRymkB56G4324h # THE KEY YOU GENERATED EARLIER) : " KEY
fi

if [ -z "$FAIL2BAN" ]; then
  read -erp "Install Fail2ban? [Y/n] : " FAIL2BAN
fi

if [ -z "$UFW" ]; then
  read -erp "Install UFW and configure ports? [Y/n] : " UFW
fi

if [ -z "$BOOTSTRAP" ]; then
  read -erp "Do you want to use our bootstrap file to speed the syncing process? [Y/n] : " BOOTSTRAP
fi

if [[ "$I2PREADY" == "y" && "$TOR" != "y" && "$TOR" != "Y" && "$I2P" != "y" && "$I2P" != "Y" ]]; then
  echo ""
  echo "Please select which networking system you want to use."
  PS3='Please enter your choice: '
  OPTIONS=("Clearnet" "TOR" "I2P")
  select OPTION in "${OPTIONS[@]}"
  do
    case $OPTION in
      "Clearnet")
        TOR="n"
        I2P="n"
        break
        ;;
      "TOR")
        echo "TOR selected."
        TOR="y"
        I2P="n"
        break
        ;;
      "I2P")
        echo "I2P selected."
        TOR="n"
        I2P="y"
        break
        ;;
      *)
        echo "Incorrect option, please type 1, 2 or 3."
        ;;
    esac
  done
elif [[ "$I2PREADY" == 'n' && -z "$TOR" && -z "$I2P" && ! -z "$IPV4" ]]; then
  read -erp "Would you like to use bulwarkd via TOR? [y/N] : " TOR
fi

clear

if [[ ($I2P = "y" || $I2P = "Y") && $I2PREADY != "y" ]];then 
  echo "Can't install with I2P, not enough RAM. Exiting."
  exit 1
fi

if [[ ("$TOR" == "y" || "$TOR" == "Y") && ("$I2P" == "y" || "$I2P" == "Y") ]]; then
  echo "Can't use both TOR and I2P. Exiting."
  exit 1
fi

# Generate random passwords
RPCUSER=$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)
RPCPASSWORD=$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

# update packages and upgrade Ubuntu
echo "Installing dependencies..."
apt-get -qq update
apt-get -qq upgrade
apt-get -qq autoremove
apt-get -qq install wget htop xz-utils
apt-get -qq install build-essential && apt-get -qq install libtool autotools-dev autoconf automake && apt-get -qq install libssl-dev && apt-get -qq install libboost-all-dev && apt-get -qq install software-properties-common && add-apt-repository -y ppa:bitcoin/bitcoin && apt update && apt-get -qq install libdb4.8-dev && apt-get -qq install libdb4.8++-dev && apt-get -qq install libminiupnpc-dev && apt-get -qq install libqt4-dev libprotobuf-dev protobuf-compiler && apt-get -qq install libqrencode-dev && apt-get -qq install git && apt-get -qq install pkg-config && apt-get -qq install libzmq3-dev
apt-get -qq install aptitude

# Install Fail2Ban
if [[ ("$FAIL2BAN" == "y" || "$FAIL2BAN" == "Y" || "$FAIL2BAN" == "") ]]; then
  aptitude -y -q install fail2ban
  # Reduce Fail2Ban memory usage - http://hacksnsnacks.com/snippets/reduce-fail2ban-memory-usage/
  echo "ulimit -s 256" | sudo tee -a /etc/default/fail2ban
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

# Install TOR
if [[ ("$TOR" == "y" || "$TOR" == "Y") ]]; then
  echo "Installing TOR..."
  apt-get -qq install tor
cat >> /etc/tor/torrc << EOL

### BULWARK CONFIGURATION ###
HiddenServiceDir /var/lib/tor/hidden_service/
ClientOnly 1
ControlPort 9051
NumEntryGuards 4
NumDirectoryGuards 3
GuardLifetime 2764800
GeoIPExcludeUnknown 1
EntryNodes 31.185.104.19/32,31.185.104.20/31,46.182.106.190/32,51.15.13.245/32,51.15.43.232/32,51.15.44.197/32,51.15.45.97/32,51.15.46.49/32,51.15.50.133/32,51.15.57.177/32,51.15.57.79/32,51.15.60.255/32,51.15.60.62/32,62.102.148.67/32,62.138.7.171/32,77.109.139.87/32,78.142.140.242/32,80.67.172.162/32,81.7.10.29/32,82.94.251.227/32,85.248.227.163/32,85.248.227.164/31,86.59.119.83/32,86.59.119.88/32,89.234.157.254/32,91.121.23.100/32,94.140.120.44/32,94.242.246.23/32,94.242.246.24/32,94.252.114.48/32,95.142.161.63/32,134.119.3.164/32,171.25.193.20/32,171.25.193.25/32,171.25.193.77/32,171.25.193.78/32,176.10.104.240/32,176.10.104.243/32,176.126.252.11/32,176.126.252.12/32,178.16.208.55/32,178.16.208.56/30,178.16.208.60/31,178.16.208.62/32,178.20.55.16/32,178.20.55.18/32,178.209.42.84/32,185.100.84.82/32,185.100.86.100/32,185.34.33.2/32,185.86.149.75/32,188.118.198.244/32,192.36.27.4/32,192.36.27.6/31,192.42.116.16/32,212.51.156.78/32
ExitNodes 31.185.104.19/32,31.185.104.20/31,46.182.106.190/32,51.15.43.232/32,51.15.44.197/32,51.15.45.97/32,51.15.46.49/32,51.15.50.133/32,51.15.57.177/32,51.15.57.79/32,51.15.60.255/32,51.15.60.62/32,62.102.148.67/32,77.109.139.87/32,80.67.172.162/32,85.248.227.163/32,85.248.227.164/31,89.234.157.254/32,94.242.246.23/32,94.242.246.24/32,95.142.161.63/32,171.25.193.20/32,171.25.193.25/32,171.25.193.77/32,171.25.193.78/32,176.10.104.240/32,176.10.104.243/32,176.126.252.11/32,176.126.252.12/32,178.20.55.16/32,178.20.55.18/32,178.209.42.84/32,185.100.84.82/32,185.100.86.100/32,185.34.33.2/32,192.36.27.4/32,192.36.27.6/31,192.42.116.16/32,212.16.104.33/32
HiddenServiceDir /var/lib/tor/hidden_service/
HiddenServicePort 52543 127.0.0.1:52543
HiddenServicePort 80 127.0.0.1:80
LongLivedPorts 80,52543
EOL
  /etc/init.d/tor stop
  sudo rm -R /var/lib/tor/hidden_service 2>/dev/null
  /etc/init.d/tor start
  echo "Starting TOR, please wait..."
  sleep 5 # Give tor enough time to connect before we continue
fi

# Install I2P
if [[ ("$I2P" == "y" || "$I2P" == "Y") ]]; then
  echo "Installing I2P..."
  apt-get -qq install libboost-all-dev libssl-dev doxygen graphviz # removed: git gcc clang cmake
  wget $I2PBINURL && tar xzf $I2PBINARCHIVE && rm $I2PBINARCHIVE
  mv kovri-bin/* /usr/local/bin && rm kovri-bin
  chown $USER:$USER /usr/local/bin/kovri* && chmod ug+x /usr/local/bin/kovri*
  mkdir "$USERHOME/.kovri"
  wget $I2PCONFURL && tar xzf $I2PCONFARCHIVE -C "$USERHOME/.kovri/" && rm $I2PCONFARCHIVE
  chown -R $USER:$USER "$USERHOME/.kovri"
  cat > /etc/systemd/system/kovri.service << EOL
[Unit]
Description=Kovri I2P
After=network.target
[Service]
Type=simple
User=${USER}
WorkingDirectory=${USERHOME}
ExecStart=/usr/local/bin/kovri
Restart=on-failure
RestartSec=1m
StartLimitIntervalSec=5m
StartLimitInterval=5m
StartLimitBurst=3
[Install]
WantedBy=multi-user.target
EOL
  systemctl enable kovri
  systemctl start kovri
  echo "Waiting for kovri to finish connecting, this can take a few minutes."
  until curl -x http://localhost:4446 http://check.kovri.i2p --fail &>/dev/null; do
    echo -ne "Connecting... \\ \\r"
    sleep 1
    echo -ne "Connecting... | \\r"
    sleep 1
    echo -ne "Connecting... / \\r"
    sleep 1
    echo -ne "Connecting... - \\r"
    sleep 1
  done
  I2PB32KEY=$(cat "$USERHOME/.kovri/client/keys/bulwarkd.dat.b32.txt")
fi

# Install Bulwark daemon
wget "$TARBALLURL"
tar -xzvf "$TARBALLNAME" -C /usr/local/bin
rm "$TARBALLNAME"

# Create .bulwark directory
mkdir "$USERHOME/.bulwark"

# Install bootstrap file
if [[ ("$BOOTSTRAP" == "y" || "$BOOTSTRAP" == "Y" || "$BOOTSTRAP" == "") ]]; then
  echo "Installing bootstrap file..."
  wget "$BOOTSTRAPURL" && xz -cd $BOOTSTRAPARCHIVE > "$USERHOME/.bulwark/bootstrap.dat" && rm $BOOTSTRAPARCHIVE
fi

# Create bulwark.conf
touch "$USERHOME/.bulwark/bulwark.conf"

# Set TORHOSTNAME if it exists.
if [[ -f /var/lib/tor/hidden_service/hostname ]]; then
  TORHOSTNAME=$(cat /var/lib/tor/hidden_service/hostname)
fi

if [[ ("$TOR" == "y" || "$TOR" == "Y") ]]; then

cat > "$USERHOME/.bulwark/bulwark.conf" << EOL
${INSTALLERUSED}
bind=127.0.0.1
daemon=1
dnsseed=0
externalip=${TORHOSTNAME}
listen=1
logtimestamps=1
masternode=1
masternodeprivkey=${KEY}
maxconnections=256
onion=127.0.0.1:9050
onlynet=tor
rpcallowip=127.0.0.1
rpcpassword=${RPCPASSWORD}
rpcuser=${RPCUSER}
server=1
EOL

elif [[ ("$I2P" == "y" || "$I2P" == "Y") ]]; then
cat > "$USERHOME/.bulwark/bulwark.conf" << EOL
${INSTALLERUSED}
addnode=5koveienpnrrwz2jzzlw5xoxnzxdrqtn7jdkszzs73mvw4757dfq.b32.i2p
addnode=5tu24nzzp7fdu4saoxff7xso2o7c25npddohfupapf6m3ffeieha.b32.i2p
addnode=czra3immvcuuex3uxew2mh6einh7isxvpi6vinamcltlthj3xcuq.b32.i2p
addnode=o3pker3dqmrlacv6zwj42uhy2fc3dst5f3rddvp4qu3z3sbcq2ra.b32.i2p
bind=127.0.0.1
daemon=1
dnsseed=0
listen=1
logtimestamps=1
masternode=1
masternodeprivkey=${KEY}
maxconnections=256
port=34525
proxy=127.0.0.1:4447
rpcallowip=127.0.0.1
rpcpassword=${RPCPASSWORD}
rpcport=34521
rpcuser=${RPCUSER}
server=1
EOL
else

cat > "$USERHOME/.bulwark/bulwark.conf" << EOL
${INSTALLERUSED}
bind=[${BINDIP}]:52543
daemon=1
externalip=[${EXTERNALIP}]
listen=1
logtimestamps=1
masternode=1
masternodeaddr=[${EXTERNALIP}]
masternodeprivkey=${KEY}
maxconnections=256
rpcallowip=127.0.0.1
rpcpassword=${RPCPASSWORD}
rpcuser=${RPCUSER}
server=1
EOL
fi
chmod 0600 "$USERHOME/.bulwark/bulwark.conf"
chown -R $USER:$USER "$USERHOME/.bulwark"

sleep 1

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
systemctl enable bulwarkd
echo "Starting bulwarkd..."
systemctl start bulwarkd

sleep 10

if ! systemctl status bulwarkd | grep -q "active (running)"; then
  echo "ERROR: Failed to start bulwarkd. Please contact support."
  exit
fi

echo "Waiting for wallet to load..."
until su -c "bulwark-cli getinfo 2>/dev/null | grep -q \"version\"" $USER; do
  sleep 1;
done

clear

echo "Your masternode is syncing. Please wait for this process to finish."
echo "This can take up to a few hours. Do not close this window."
if [[ ("$TOR" == "y" || "$TOR" == "Y") ]]; then 
  echo "The TOR address of your masternode is: $TORHOSTNAME"
fi

if [[ ("$I2P" == "y" || "$I2P" == "Y") ]]; then
  echo "The I2P address of your masternode is: $I2PB32KEY"
fi

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


if [[ $INTERACTIVE = "y" ]]; then
  read -rp "Press Enter to continue after you've done that. " -n1 -s
fi

clear

sleep 1
su -c "/usr/local/bin/bulwark-cli startmasternode local false" $USER
sleep 1
clear
su -c "/usr/local/bin/bulwark-cli masternode status" $USER
sleep 5

echo "" && echo "Masternode setup completed." 
if [[ ("$TOR" == "y" || "$TOR" == "Y") ]]; then 
  echo "The TOR address of your masternode is: $TORHOSTNAME"
fi

if [[ ("$I2P" == "y" || "$I2P" == "Y") ]]; then
  echo "The I2P address of your masternode is: $I2PB32KEY"
fi

echo ""
