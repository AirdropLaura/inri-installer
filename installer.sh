#!/bin/bash

# ========================================= #
#         INRI CHAIN FULL INSTALLER         #
#          With Genesis Initialization       #
#      Created by Bastiar (yarrr-node.com)  #
#     Telegram Channel : Airdrop Laura       #
# ========================================= #

BLUE="\e[34m"; GREEN="\e[32m"; YELLOW="\e[33m"; RED="\e[31m"; NC="\e[0m"

GENESIS_URL="https://raw.githubusercontent.com/AirdropLaura/inri-installer/main/genesis.json"
DATADIR="$HOME/inri"

BOOTNODES="enode://5c7c744a9ac53fdb9e529743208ebd123f11c73d973aa2cf653f3ac1bdf460b6f2a9b2aec23b8f2b9d692d8c898fe0e93dac8d7533db8926924e770969f3a46a@134.199.203.8:30303,enode://f196abde38edd1db5d4208a6823fd9d5ce5823a6730c32739b9f351558f254e8d6d32b6d7a8ca43304cbcfe5c172f4a9a25defacd36eea6f5752f3b4bc01cdf@170.64.222.34:30303"

banner() {
echo -e "${BLUE}"
echo "=============================================="
echo "                INRI INSTALLER A.1            "
echo "=============================================="
echo -e "${GREEN}Auto Detect • Geth • Genesis Init • Mining${NC}"
echo -e "${YELLOW}Created by Bastiar - https://yarrr-node.com${NC}"
echo -e "${YELLOW}Telegram Channel : Airdrop Laura${NC}"
echo ""
}

deps() {
    echo -e "${GREEN}[+] Installing Dependencies...${NC}"
    sudo apt update -y
    sudo apt install -y curl wget git nano jq tar ufw
}

install_geth() {
    echo -e "${GREEN}[+] Installing Geth...${NC}"
    wget -q https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-latest.tar.gz
    tar -xvf geth-linux-amd64-latest.tar.gz >/dev/null
    FOLDER=$(ls | grep geth-linux)
    sudo mv "$FOLDER/geth" /usr/bin/geth
    rm -rf "$FOLDER" geth-linux*.tar.gz
    echo -e "${GREEN}[✓] Geth Installed${NC}"
}

download_genesis() {
    echo -e "${GREEN}[+] Downloading genesis.json...${NC}"
    mkdir -p $DATADIR
    curl -s -o $HOME/genesis.json "$GENESIS_URL"
    echo -e "${GREEN}[✓] Genesis downloaded${NC}"
}

init_genesis() {
    echo -e "${GREEN}[+] Initializing Blockchain...${NC}"
    geth --datadir "$DATADIR" init "$HOME/genesis.json"
    echo -e "${GREEN}[✓] Blockchain initialized${NC}"
}

create_service() {
echo -e "${GREEN}[+] Creating node service...${NC}"

sudo tee /etc/systemd/system/inri-node.service >/dev/null <<EOF
[Unit]
Description=INRI Chain Node
After=network.target

[Service]
User=root
Type=simple

ExecStart=/usr/bin/geth --datadir $DATADIR \
 --networkid 3777 \
 --syncmode full --cache 1024 \
 --http --http.addr 0.0.0.0 --http.port 8545 \
 --http.api eth,net,web3,miner,txpool,admin --http.corsdomain "*" --http.vhosts "*" \
 --ws --ws.addr 0.0.0.0 --ws.port 8546 --ws.api eth,net,web3 \
 --port 30303 \
 --bootnodes "$BOOTNODES"

Restart=always
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable inri-node
systemctl start inri-node

echo -e "${GREEN}[✓] Node service created & started${NC}"
}

start_mining() {
    CPU=$(nproc)
    THREADS=$((CPU/2))
    [ $THREADS -lt 1 ] && THREADS=1

    echo -e "${YELLOW}Enter your wallet address (0x...):${NC}"
    read WALLET

    nohup geth --datadir "$DATADIR" \
      --networkid 3777 \
      --mine --miner.threads $THREADS --miner.etherbase "$WALLET" \
      >> $DATADIR/miner.log 2>&1 &

    echo -e "${GREEN}[✓] Mining Started!"
    echo -e "${YELLOW}Logs: $DATADIR/miner.log${NC}"
}

logs_node() {
    journalctl -fu inri-node
}

remove_all() {
    echo -e "${RED}[!] Removing INRI Node & Data...${NC}"
    systemctl stop inri-node
    systemctl disable inri-node
    rm -f /etc/systemd/system/inri-node.service
    rm -rf $DATADIR
    rm -f $HOME/genesis.json
    echo -e "${GREEN}[✓] Removed completely${NC}"
}

menu() {
banner
echo -e "${BLUE}=============== MENU ===============${NC}"
echo "1) Install Dependencies"
echo "2) Install Geth"
echo "3) Download Genesis"
echo "4) Init Blockchain"
echo "5) Create Node Service + Start Node"
echo "6) Start Mining"
echo "7) View Logs"
echo "8) Remove Node"
echo "0) Exit"
echo -e "${BLUE}===================================${NC}"
read -p "Choose: " CH

case $CH in
1) deps ;;
2) install_geth ;;
3) download_genesis ;;
4) init_genesis ;;
5) create_service ;;
6) start_mining ;;
7) logs_node ;;
8) remove_all ;;
0) exit ;;
*) echo "Invalid option";;
esac

menu
}

menu
