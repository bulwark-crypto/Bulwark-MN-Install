#!/bin/bash
clear

# Set these to change the version of Bulwark to install
TARBALLURL="https://github.com/bulwark-crypto/Bulwark/releases/download/1.2.3/bulwark-1.2.3.0-linux64.tar.gz"
TARBALLNAME="bulwark-1.2.3.0-linux64.tar.gz"
BWKVERSION="1.2.3.0"

STRING1="Make sure you double check before hitting enter! Only one shot at these!"
STRING2="If you found this helpful, please donate to BWK Donation: "
STRING3="bCkL87UvfwqphwCdWgyShFYz54hgPVJAg3"
STRING4="Updating system and installing required packages."
STRING5="Switching to Aptitude"
STRING6="Some optional installs"
STRING7="Starting your masternode"
STRING8="Now, you need to finally start your masternode in the following order:"
STRING9="Go to your windows wallet and from the Control wallet debug console please enter"
STRING10="startmasternode alias false <mymnalias>"
STRING11="where <mymnalias> is the name of your masternode alias (without brackets)"
STRING12="once completed please return to VPS and press the space bar"
STRING13=""
STRING14="Please Wait a minimum of 5 minutes before proceeding, the node wallet must be synced"

echo $STRING1

read -e -p "Server IP Address : " ip
read -e -p "Masternode Private Key (e.g. 7edfjLCUzGczZi3JQw8GHp434R9kNY33eFyMGeKRymkB56G4324h # THE KEY YOU GENERATED EARLIER) : " key
read -e -p "Install Fail2ban? [Y/n] : " install_fail2ban
read -e -p "Install UFW and configure ports? [Y/n] : " UFW

clear
echo $STRING2
echo $STRING13
echo $STRING3
echo $STRING13
echo $STRING4
sleep 10

# update package and upgrade Ubuntu
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y autoremove
sudo apt-get -y install wget nano htop
sudo apt-get -y install build-essential && sudo apt-get -y install libtool autotools-dev autoconf automake && sudo apt-get -y install libssl-dev && sudo apt-get -y install libboost-all-dev && sudo apt install software-properties-common && sudo add-apt-repository ppa:bitcoin/bitcoin && sudo apt update && sudo apt-get -y install libdb4.8-dev && sudo apt-get -y install libdb4.8++-dev && sudo apt-get -y install libminiupnpc-dev && sudo apt-get -y install libqt4-dev libprotobuf-dev protobuf-compiler && sudo apt-get -y install libqrencode-dev && sudo apt-get -y install git && sudo apt-get -y install pkg-config
sudo apt-get -y install libzmq3-dev
clear
echo $STRING5
sudo apt-get -y install aptitude

#Generating Random Passwords
password=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
password2=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

echo $STRING6
if [[ ("$install_fail2ban" == "y" || "$install_fail2ban" == "Y" || "$install_fail2ban" == "") ]]; then
  cd ~
  sudo aptitude -y install fail2ban
  sudo service fail2ban restart
fi
if [[ ("$UFW" == "y" || "$UFW" == "Y" || "$UFW" == "") ]]; then
  sudo apt-get -y install ufw
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw allow ssh
  sudo ufw allow 52543/tcp
  sudo ufw enable -y
fi

#Install Bulwark Daemon
wget $TARBALLURL
sudo tar -xzvf $TARBALLNAME && mv bin bulwark-$BWKVERSION
sudo rm $TARBALLNAME
sudo cp ./bulwark-$BWKVERSION/bulwarkd /usr/bin
sudo cp ./bulwark-$BWKVERSION/bulwark-cli /usr/bin
sudo cp ./bulwark-$BWKVERSION/bulwark-tx /usr/bin
bulwarkd -daemon
clear

#Setting up coin
clear
echo $STRING2
echo $STRING13
echo $STRING3
echo $STRING13
echo $STRING4
sleep 10

#Create bulwark.conf
echo '
rpcuser='$password'
rpcpassword='$password2'
rpcallowip=127.0.0.1
listen=1
server=1
daemon=1
logtimestamps=1
maxconnections=256
externalip='$ip'
bind='$ip':52543
masternodeaddr='$ip'
masternodeprivkey='$key'
masternode=1
addnode=bwk1.masterhash.us:52543
addnode=bwk2.masterhash.us:52543
addnode=bwk3.masterhash.us:52543
addnode=bwk4.masterhash.us:52543
addnode=bwk5.masterhash.us:52543
addnode=bwk6.masterhash.us:52543
addnode=bwk7.masterhash.us:52543
addnode=bwk8.masterhash.us:52543
addnode=bwk9.masterhash.us:52543
addnode=bwk10.masterhash.us:52543
' | sudo -E tee ~/.bulwark/bulwark.conf >/dev/null 2>&1
sudo chmod 0600 ~/.bulwark/bulwark.conf

#Starting coin
(
  crontab -l 2>/dev/null
  echo '@reboot sleep 30 && bulwarkd -daemon -shrinkdebugfile'
) | crontab
(
  crontab -l 2>/dev/null
  echo '@reboot sleep 60 && bulwark-cli startmasternode local false'
) | crontab
bulwarkd -daemon

clear
echo $STRING2
echo $STRING13
echo $STRING3
echo $STRING13
echo $STRING4
sleep 10
echo $STRING7
echo $STRING13
echo $STRING8
echo $STRING13
echo $STRING9
echo $STRING13
echo $STRING10
echo $STRING13
echo $STRING11
echo $STRING13
echo $STRING12
echo $STRING14
sleep 5m

read -p "Press any key to continue... " -n1 -s
bulwark-cli startmasternode local false
bulwark-cli masternode status
