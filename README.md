## System requirements

The VPS you plan to install your masternode on needs to have at least 1GB of RAM and 10GB of free disk space. We do not recommend using servers who do not meet those criteria, and your masternode will not be stable. We also recommend you do not use elastic cloud services like AWS or Google Cloud for your masternode - to use your node with such a service would require some networking knowledge and manual configuration.

## Funding your Masternode

* First, we will do the initial collateral TX and send exactly 5000 BWK to one of our addresses. To keep things sorted in case we setup more masternodes we will label the addresses we use.

  - Open your BWK wallet and switch to the "Receive" tab.

  - Click into the label field and create a label, I will use MN1

  - Now click on "Request payment"

  - The generated address will now be labelled as MN1 If you want to setup more masternodes just repeat the steps so you end up with several addresses for the total number of nodes you wish to setup. Example: For 10 nodes you will need 10 addresses, label them all.

  - Once all addresses are created send 5000 BWK each to them. Ensure that you send exactly 5000 BWK and do it in a single transaction. You can double check where the coins are coming from by checking it via coin control usually, that's not an issue.

As soon as all 5k transactions are done, we will wait for 15 confirmations. You can check this in your wallet or use the explorer. It should take around 30 minutes if all transaction have 15 confirmations

## Installation & Setting up your Server

Generate your Masternode Private Key

In your wallet, open Tools -> Debug console and run the following command to get your masternode key:

```bash
masternode genkey
```

Please note: If you plan to set up more than one masternode, you need to create a key with the above command for each one. These keys are not tied to any specific masternode, but each masternode you run requires a unique key.

Run this command to get your output information:

```bash
masternode outputs
```

Copy both the key and output information to a text file.

Close your wallet and open the Bulwark Appdata folder. Its location depends on your OS.

* **Windows:** Press Windows+R and write %appdata% - there, open the folder Bulwark.
* **macOS:** Press Command+Space to open Spotlight, write ~/Library/Application Support/Bulwark and press Enter.
* **Linux:** Open ~/.bulwark/

In your appdata folder, open masternode.conf with a text editor and add a new line in this format to the bottom of the file:

```bash
masternodename ipaddress:52543 genkey collateralTxID outputID
```

An example would be

```
mn1 127.0.0.2:52543 93HaYBVUCYjEMeeH1Y4sBGLALQZE1Yc1K64xiqgX37tGBDQL8Xg 2bcd3c84c84f87eaa86e4e56834c92927a07f9e18718810b92e0d0324456a67c 0
```

_masternodename_ is a name you choose, _ipaddress_ is the public IP of your VPS, masternodeprivatekey is the output from `masternode genkey`, and _collateralTxID_ & _outputID_ come from `masternode outputs`. Please note that _masternodename_ must not contain any spaces, and should not contain any special characters.

Restart and unlock your wallet.

SSH (Putty on Windows, Terminal.app on macOS) to your VPS, login as root (**Please note:** It's normal that you don't see your password after typing or pasting it) and run the following command:

```bash
bash <( curl https://raw.githubusercontent.com/bulwark-crypto/Bulwark-MN-Install/master/install.sh )
```

If you get the error "bash: curl: command not found", run this first: `apt-get -y install curl`

When the script asks, confirm your VPS IP Address and paste your masternode key (You can copy your key and paste into the VPS if connected with Putty by right clicking)

The installer will then present you with a few options.

**PLEASE NOTE**: Do not choose the advanced installation option unless you have experience with Linux and know what you are doing - if you do and something goes wrong, the Bulwark team CANNOT help you, and you will have to restart the installation.

Follow the instructions on screen.

After the basic installation is done, the wallet will sync. You will see the following message:

```
Your masternode is syncing. Please wait for this process to finish.
This can take up to a few hours. Do not close this window.
```

Once you see "Masternode setup completed." on screen, you are done.

## Refreshing Node

If your masternode is stuck on a block or behaving badly, you can refresh it.
Please note that this script must be run as root.

```
bash <( curl https://raw.githubusercontent.com/bulwark-crypto/Bulwark-MN-Install/master/refresh_node.sh )
```

No other attention is required.

## Updating Node

To update your node please run this command and follow the instructions.
Please note that this script must be run as root.

```
bash <( curl https://raw.githubusercontent.com/bulwark-crypto/Bulwark-MN-Install/master/update_node.sh )
```

## Non-interactive installation

You can use the installer in a non-interactive mode by using command line arguments - for example, if you want to automate the installation. This requires that you download the installer and run it locally. Here are the arguments you can pass to `install.sh`:

```
    -n --normal               : Run installer in normal mode
    -a --advanced             : Run installer in advanced mode
    -i --externalip <address> : Public IP address of VPS
    --bindip <address>        : Internal bind IP to use
    -k --privatekey <key>     : Private key to use
    -f --fail2ban             : Install Fail2Ban
    --no-fail2ban             : Don't install Fail2Ban
    -u --ufw                  : Install UFW
    --no-ufw                  : Don't install UFW
    -b --bootstrap            : Sync node using Bootstrap
    --no-bootstrap            : Don't use Bootstrap
    -h --help                 : Display this help text.
    --no-interaction          : Do not wait for wallet activation.
```

If you want to make the installation process fully non-interactive, you need to provide Bulwark with arguments for the mode to use, the external IP, private key, and wether to use fail2ban, UFW and the bootstrap, and then also add the `--no-interaction` parameter. Please not that this will not tell you to activate your masternode from your wallet after the node has finished syncing, so it will not run until you do.
