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

bulwarkd -daemon
