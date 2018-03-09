## Funding your Masternode

* First, we will do the initial collateral TX and send exactly 5000 BWK to one of our addresses. To keep things sorted in case we setup more masternodes we will label the addresses we use.

  - Open your BWK wallet and switch to the "Receive" tab.

  - Click into the label field and create a label, I will use MN1

  - Now click on "Request payment"

  - The generated address will now be labelled as MN1 If you want to setup more masternodes just repeat the steps so you end up with several addresses for the total number of nodes you wish to setup. Example: For 10 nodes you will need 10 addresses, label them all.

  - Once all addresses are created send 5000 BWK each to them. Ensure that you send exactly 5000 BWK and do it in a single transaction. You can double check where the coins are coming from by checking it via coin control usually, that's not an issue.

* As soon as all 5k transactions are done, we will wait for 15 confirmations. You can check this in your wallet or use the explorer. It should take around 30 minutes if all transaction have 15 confirmations

## Installation & Setting up your Server

Generate your Masternode Private Key

In your wallet, open Tools -> Debug console and run the following command:

```bash
masternode genkey
```

Write this down or copy it somewhere safe.

View your Output (Also in the Debug console):

```bash
masternode outputs
```

Write this down or copy it somewhere safe.


SSH (Putty on Windows, Terminal.app on macOS) to your VPS, login to root, and install git if it isn't installed already.

```bash
apt-get -y install git
```

Then clone the Github repository.

```bash
git clone https://github.com/bulwark-crypto/Bulwark-MN-Install
```
Navigate to the install folder:

```bash
cd Bulwark-MN-Install
```

Install & configure your desired master node with options.

```bash
bash install.sh
```

When the script asks, input your VPS IP Address and Private Key (You can copy your private key and paste into the VPS if connected with Putty by right clicking)

If you're asked at any point `Do you want to continue? [Y/n]` press Enter.

If you get the following message, press Enter:

```
No longer supports precise, due to its ancient gcc and Boost versions.
More info: https://launchpad.net/~bitcoin/+archive/ubuntu/bitcoin
Press [ENTER] to continue or ctrl-c to cancel adding it
```

Once done, the VPS will ask you to go start your masternode in the local wallet

In appdata/roaming/Bulwark, open up masternode.conf

Insert as a new line the following:

```bash
masternodename ipaddress:52543 masternodeprivatekey collateralTxID outputID
```

An example would be

```
mn1 127.0.0.2:52543 93HaYBVUCYjEMeeH1Y4sBGLALQZE1Yc1K64xiqgX37tGBDQL8Xg 2bcd3c84c84f87eaa86e4e56834c92927a07f9e18718810b92e0d0324456a67c 0
```

_masternodename_ is a name you choose, _ipaddress_ is the public IP of your VPS, masternodeprivatekey is the output from `masternode genkey`, and _collateralTxID_ & _outputID_ come from `masternode outputs`. Please note that _masternodename_ must not contain any spaces, and should not contain any special characters.

Open up the local wallet, unlock with your encryption password, and open up the Debug Console

```bash
startmasternode alias false <masternodename>
```
If done correctly, it will indicate that the masternode has been started correctly.

Go back to your VPS and hit the spacebar. It will say that it needs to sync. You're all done!

Now you just need to wait for the VPS to sync up the blockchain and await your first masternode payment.

## Refreshing Node

To refresh your node please run this from root ~

```
rm -rf Bulwark-MN-Install && git clone https://github.com/bulwark-crypto/Bulwark-MN-Install && cd Bulwark-MN-Install && bash refresh_node.sh
```

No other attention is required.

## Updating Node

To update your node please run this from root ~ and follow the instructions:

```
cd Bulwark-MN-Install && git pull && bash update_node.sh
```

When uptdating your node, it's possible that you'll see the following error message:

> *** Please tell me who you are.

In that case, please run the following line and try again:

```
git config --global user.email "EMAIL" && git config --global user.name "NAME"
```

Make sure to replace EMAIL and NAME with your mail address and name.
