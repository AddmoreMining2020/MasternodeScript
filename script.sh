#!/bin/bash

# Color constants
SUCCESS="\e[92m"
ERROR="\e[91m"
RESET="\e[39m"

# Check if run as root
if [ "${EUID}" -ne 0 ]; then
    printf "${ERROR}Script should be run as root!${RESET}\n"
    exit
fi

# Get Masternode Name
printf "${SUCCESS}Enter your Masternode name:${RESET}\n"
read NAME

# Get Masternode Key
printf "${SUCCESS}Enter your Masternode private key:${RESET}\n"
read KEY
until [ ${#KEY} -ge 51 ] && [ ! ${#KEY} -ge 52 ]; do
    printf "${ERROR}Double check your input and try again:${RESET}\n"
    read KEY
done

# Get Masternode TXID
printf "${SUCCESS}Enter your Masternode TXID:${RESET}\n"
read TX
until [ ${#TX} -ge 64 ] && [ ! ${#TX} -ge 65 ]; do
    printf "${ERROR}Double check your input and try again:${RESET}\n"
    read TX
done

# Get Masternode TXID index
printf "${SUCCESS}Please enter your Masternode TXID index:${RESET}\n"
read TXI
until [[ "$TXI" =~ ^[0-9]+$ ]]; do
    printf "${ERROR}Double check your input and try again:${RESET}\n"
        read TXI
done

# Install packages
printf "${SUCCESS}Installing packages and updates${RESET}\n"

sudo apt-get update
sudo add-apt-repository ppa:bitcoin/bitcoin -y
sudo apt-get update
sudo apt-get install ufw -y
sudo apt-get install pwgen -y
sudo apt-get install dnsutils -y
sudo apt-get install zip unzip -y
sudo apt-get install libzmq3-dev -y
sudo apt-get install libboost-all-dev -y
sudo apt-get install libminiupnpc-dev -y
sudo apt-get install build-essential libssl-dev libminiupnpc-dev libevent-dev -y
sudo apt-get install libdb4.8-dev libdb4.8++-dev -y

# Set variables
PORT="4878"
PASSWORD=$(pwgen -1 20 -n)
SERVERIP=$(dig +short myip.opendns.com @resolver1.opendns.com)

# Set up locales
printf "${SUCCESS}Setting up locales${RESET}\n"

export LANG="en_US.utf8"
export LANGUAGE="en_US.utf8"
export LC_ALL="en_US.utf8"

# Check for old processes & residue files
if pgrep -x "addmored" > /dev/null
then
    printf "${ERROR}Killing old processes${RESET}\n"
    kill -9 $(pgrep addmored)
fi
if [ -d "Addmore" ]; then
    rm -r Addmore
    printf "${ERROR}Removed old coredir${RESET}\n"
fi
if [ -d ".addmore" ]; then
    rm -r .addmore
    printf "${ERROR}Removed old datadir${RESET}\n"
fi

# Make dir & get executables
mkdir ~/Addmore
cd ~/Addmore
wget "https://github.com/AddmoreMining2020/Addmore/releases/download/1.0.0/addmore-ubuntu-x64-v1.0.0.zip"
unzip addmore-ubuntu-x64-v1.0.0.zip
rm -rf addmore-ubuntu-x64-v1.0.0.zip
rm -rf addmore-qt
chmod ugo+x addmored
chmod ugo+x addmore-cli
chmod ugo+x addmore-tx

# Set up config files
printf "${SUCCESS}Setting up ${NAME}${RESET}\n"

mkdir ~/.addmore
cat <<EOF > ~/.addmore/addmore.conf
rpcuser=Masternode
rpcpassword=${PASSWORD}
rpcallowip=127.0.0.1
#----------------------------
listen=1
server=1
daemon=1
maxconnections=128
#----------------------------
masternode=1
masternodeprivkey=${KEY}
externalip=${SERVERIP}
EOF

# Start the masternode up
printf "${SUCCESS}Starting up ${NAME}${RESET}\n"

sudo ufw allow 4878
cd ~/Addmore
./addmored

printf "${SUCCESS}==================================================================${RESET}\n"
printf "${SUCCESS}Paste the following line into masternode.conf of your desktop wallet:${RESET}\n\n"
printf "${ERROR}${NAME} ${SERVERIP}:${PORT} ${KEY} ${TX} ${TXI}${RESET}\n\n"
printf "${SUCCESS}Installed with VPS IP ${ERROR}${SERVERIP}${SUCCESS} on port ${ERROR}${PORT}${RESET}\n"
printf "${SUCCESS}Installed with Masternode Key ${ERROR}${KEY}${RESET}\n"
printf "${SUCCESS}Installed with Masternode TXID ${ERROR}${TX}${SUCCESS} index ${ERROR}${TXI}${RESET}\n"
printf "${SUCCESS}Installed with RPCUser=${ERROR}Masternode${RESET}\n"
printf "${SUCCESS}Installed with RPCPassword=${ERROR}${PASSWORD}${RESET}\n"
printf "${SUCCESS}==================================================================${RESET}\n"
