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

BOOTNODES="enode://5c7c744a9ac53fdb9e529743208ebd123f11c73d973aa2cf653f3ac1bdf460b6f2a9b2aec23b8f2b9d692d8c898fe0e93dac8d7533db8926924e770969f3a46a@134.199.203.8:30303"

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
    echo -e "${GREEN}[+] Installing Geth via APT...${NC}"
    sudo add-apt-repository -y ppa:ethereum/ethereum
    sudo apt update
    sudo apt install -y geth
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
 --http --http.addr 127.0.0.1 --http.port 8545 \
 --http.api eth,net,web3,miner,txpool,admin --http.corsdomain "localhost" --http.vhosts "localhost" \
 --ws --ws.addr 127.0.0.1 --ws.port 8546 --ws.api eth,net,web3 \
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
    echo -e "${YELLOW}Enter your wallet address (0x...):${NC}"
    read WALLET

    # Validasi format wallet address
    if [[ ! $WALLET =~ ^0x[a-fA-F0-9]{40}$ ]]; then
        echo -e "${RED}[!] Invalid wallet address format!${NC}"
        return
    fi

    # Stop node service dulu
    echo -e "${YELLOW}[~] Stopping node service...${NC}"
    systemctl stop inri-node

    # Buat mining service (FIXED - tanpa --miner.threads)
    sudo tee /etc/systemd/system/inri-miner.service >/dev/null <<EOF
[Unit]
Description=INRI Chain Miner
After=network.target

[Service]
User=root
Type=simple

ExecStart=/usr/bin/geth --datadir $DATADIR \
 --networkid 3777 \
 --syncmode full --cache 1024 \
 --http --http.addr 127.0.0.1 --http.port 8545 \
 --http.api eth,net,web3,miner,txpool,admin --http.corsdomain "localhost" --http.vhosts "localhost" \
 --ws --ws.addr 127.0.0.1 --ws.port 8546 --ws.api eth,net,web3 \
 --port 30303 \
 --bootnodes "$BOOTNODES" \
 --mine --miner.etherbase "$WALLET"

Restart=always
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl disable inri-node
    systemctl enable inri-miner
    systemctl start inri-miner

    echo -e "${GREEN}[✓] Mining Started!"
    echo -e "${YELLOW}Wallet: $WALLET${NC}"
    echo -e "${YELLOW}View logs: journalctl -fu inri-miner${NC}"
}

logs_node() {
    echo -e "${YELLOW}Which logs do you want to see?${NC}"
    echo "1) Node logs (inri-node)"
    echo "2) Miner logs (inri-miner)"
    read -p "Choose: " LOG_CH
    
    case $LOG_CH in
        1) journalctl -fu inri-node ;;
        2) journalctl -fu inri-miner ;;
        *) echo "Invalid option" ;;
    esac
}

stop_mining() {
    echo -e "${YELLOW}[~] Stopping miner and restarting node...${NC}"
    systemctl stop inri-miner
    systemctl disable inri-miner
    systemctl enable inri-node
    systemctl start inri-node
    echo -e "${GREEN}[✓] Mining stopped, node running${NC}"
}

remove_all() {
    echo -e "${RED}[!] Removing INRI Node & Data...${NC}"
    systemctl stop inri-node inri-miner 2>/dev/null
    systemctl disable inri-node inri-miner 2>/dev/null
    rm -f /etc/systemd/system/inri-node.service
    rm -f /etc/systemd/system/inri-miner.service
    rm -rf $DATADIR
    rm -f $HOME/genesis.json
    systemctl daemon-reload
    echo -e "${GREEN}[✓] Removed completely${NC}"
}

check_status() {
    echo -e "${BLUE}========= INRI Status =========${NC}"
    
    if systemctl is-active --quiet inri-node; then
        echo -e "${GREEN}Node: RUNNING${NC}"
    else
        echo -e "${RED}Node: STOPPED${NC}"
    fi
    
    if systemctl is-active --quiet inri-miner; then
        echo -e "${GREEN}Miner: RUNNING${NC}"
    else
        echo -e "${RED}Miner: STOPPED${NC}"
    fi
    
    echo ""
    geth attach $DATADIR/geth.ipc --exec "eth.syncing" 2>/dev/null || echo "Node not responding"
    echo ""
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
echo "8) Check Status"
echo "9) Stop Mining (Node only)"
echo "10) Remove Node"
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
8) check_status ;;
9) stop_mining ;;
10) remove_all ;;
0) exit ;;
*) echo "Invalid option";;
esac

menu
}

menu
