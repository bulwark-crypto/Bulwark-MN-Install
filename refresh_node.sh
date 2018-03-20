#!/bin/bash
clear

bulwark-cli stop

sleep 10

rm -rf ~/.bulwark/blocks
rm -rf ~/.bulwark/database
rm -rf ~/.bulwark/chainstate
rm -rf ~/.bulwark/peers.dat

cp ~/.bulwark/bulwark.conf ~/.bulwark/bulwark.conf.backup
sed -i '/^addnode/d' ~/.bulwark/bulwark.conf
cat <<EOL >>  ~/.bulwark/bulwark.conf
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
EOL

bulwarkd -daemon
