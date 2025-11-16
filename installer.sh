#!/bin/bash

# ========================================= #
#         INRI CHAIN FULL INSTALLER         #
#          With Genesis Initialization       #
#      Created by Bastiar (yarrr-node.com)  #
#     Telegram Channel : Airdrop Laura       #
#        Optimized Full Power Edition        #
# ========================================= #

BLUE="\e[34m"; GREEN="\e[32m"; YELLOW="\e[33m"; RED="\e[31m"; NC="\e[0m"

GENESIS_URL="https://rpc.inri.life/genesis.json"
DATADIR="$HOME/inri"
GETH_VERSION="1.10.26"
GETH_URL="https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.10.26-e5eb32ac.tar.gz"

BOOTNODES="enode://5c7c744a9ac53fdb9e529743208ebd123f11c73d973aa2cf653f3ac1bdf460b6f2a9b2aec23b8f2b9d692d8c898fe0e93dac8d7533db8926924e770969f3a46a@134.199.203.8:30303"

banner() {
echo -e "${BLUE}"
echo "=============================================="
echo "           INRI INSTALLER v2.0 (Fixed)        "
echo "=============================================="
echo -e "${GREEN}Geth 1.10.26 • Full PoW Support • Optimized${NC}"
echo -e "${YELLOW}Created by Bastiar - https://yarrr-node.com${NC}"
echo -e "${YELLOW}Telegram Channel : Airdrop Laura${NC}"
echo ""
}

quick_setup() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}    QUICK SETUP - Installing...${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    # 1. Install dependencies
    echo -e "${GREEN}[1/7] Installing Dependencies...${NC}"
    sudo apt update -y >/dev/null 2>&1
    sudo apt install -y curl wget git nano jq tar ufw >/dev/null 2>&1
    echo -e "${GREEN}[✓] Dependencies Installed${NC}"

    # 2. Install geth
    echo -e "${GREEN}[2/7] Installing Geth...${NC}"
    sudo systemctl stop inri-miner 2>/dev/null

    cd /tmp
    wget -q "$GETH_URL"
    tar -xzf geth-linux-amd64-1.10.26-e5eb32ac.tar.gz
    sudo cp geth-linux-amd64-1.10.26-e5eb32ac/geth /usr/bin/
    sudo chmod +x /usr/bin/geth
    rm -rf geth-linux-amd64-1.10.26-e5eb32ac*

    echo -e "${GREEN}[✓] Geth Installed${NC}"

    # 3. Download genesis
    echo -e "${GREEN}[3/7] Downloading Genesis...${NC}"
    mkdir -p $DATADIR
    curl -fSLo "$HOME/genesis.json" "$GENESIS_URL"
    echo -e "${GREEN}[✓] Genesis Downloaded${NC}"

    # 4. Init blockchain
    echo -e "${GREEN}[4/7] Initializing Blockchain...${NC}"

    if [ -d "$DATADIR/geth" ]; then
        echo -e "${YELLOW}[~] Backing up old datadir...${NC}"
        mv "$DATADIR" "${DATADIR}.backup.$(date +%s)"
    fi

    geth --datadir "$DATADIR" init "$HOME/genesis.json" >/dev/null 2>&1
    echo -e "${GREEN}[✓] Blockchain Initialized${NC}"

    # 5. Firewall
    echo -e "${GREEN}[5/7] Configuring Firewall...${NC}"
    echo "y" | sudo ufw enable >/dev/null 2>&1
    sudo ufw allow 22/tcp >/dev/null 2>&1
    sudo ufw allow 30303/tcp >/dev/null 2>&1
    sudo ufw allow 30303/udp >/dev/null 2>&1
    echo -e "${GREEN}[✓] Firewall Configured${NC}"

    # 6. Wallet
    echo -e "${GREEN}[6/7] Miner Configuration...${NC}"
    echo -e "${YELLOW}Enter your wallet address (0x...):${NC}"
    read WALLET

    if [[ ! $WALLET =~ ^0x[a-fA-F0-9]{40}$ ]]; then
        echo -e "${RED}[!] Invalid wallet address!${NC}"
        return
    fi

    # 7. Create miner service
    echo -e "${GREEN}[7/7] Creating Miner Service...${NC}"

    CPU_CORES=$(nproc)
    MINER_THREADS=$CPU_CORES   # FULL POWER MODE
    PUBLIC_IP=$(curl -s ifconfig.me)

sudo tee /etc/systemd/system/inri-miner.service >/dev/null <<EOF
[Unit]
Description=INRI Chain Miner (Geth Optimized)
After=network.target

[Service]
User=root
Type=simple

ExecStart=/usr/bin/geth --datadir $DATADIR \
 --networkid 3777 \
 --syncmode full \
 --gcmode archive \
 --cache 4096 \
 --maxpeers 50 \
 --http --http.addr 127.0.0.1 --http.port 8545 \
 --http.api eth,net,web3,miner,txpool,admin \
 --ws --ws.addr 127.0.0.1 --ws.port 8546 \
 --ws.api eth,net,web3 \
 --port 30303 \
 --bootnodes "$BOOTNODES" \
 --mine --miner.threads $MINER_THREADS --miner.etherbase "$WALLET" \
 --miner.gaslimit 30000000 \
 --miner.gastarget 30000000 \
 --nat extip:$PUBLIC_IP \
 --verbosity 3 \
 --ipcpath $DATADIR/geth.ipc \
 --ipc

Restart=always
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable inri-miner >/dev/null 2>&1
    sudo systemctl start inri-miner

    echo -e "${GREEN}[✓] Miner Started${NC}"
    echo ""
    echo -e "${YELLOW}Wallet: $WALLET${NC}"
    echo -e "${YELLOW}Mining Threads: $MINER_THREADS${NC}"
    echo -e "${YELLOW}Public IP: $PUBLIC_IP${NC}"
    echo ""
    echo -e "${YELLOW}View logs: journalctl -fu inri-miner${NC}"
}

logs_miner() {
    journalctl -fu inri-miner
}

restart_miner() {
    echo -e "${YELLOW}[~] Restarting miner...${NC}"
    sudo systemctl restart inri-miner
}

stop_miner() {
    echo -e "${YELLOW}[~] Stopping miner...${NC}"
    sudo systemctl stop inri-miner
    sudo systemctl disable inri-miner >/dev/null 2>&1
}

remove_all() {
    echo -e "${RED}WARNING: This will remove all mining data.${NC}"
    echo -e "${RED}Type 'yes' to continue:${NC}"
    read CONFIRM
    
    if [ "$CONFIRM" != "yes" ]; then
        echo -e "${GREEN}Cancelled.${NC}"
        return
    fi

    sudo systemctl stop inri-miner
    sudo systemctl disable inri-miner
    sudo rm -f /etc/systemd/system/inri-miner.service
    rm -rf $DATADIR
    rm -f $HOME/genesis.json
    sudo systemctl daemon-reload

    echo -e "${GREEN}[✓] Removed completely${NC}"
}

menu() {
banner
echo -e "${BLUE}=============== MENU ===============${NC}"
echo "1) Quick Setup (Fresh Install)"
echo "2) View Live Logs"
echo "3) Restart Miner"
echo "4) Stop Miner"
echo "5) Remove All"
echo "0) Exit"
echo -e "${BLUE}====================================${NC}"
read -p "Choose: " CH

case $CH in
1) quick_setup ;;
2) logs_miner ;;
3) restart_miner ;;
4) stop_miner ;;
5) remove_all ;;
0) exit ;;
*) echo "Invalid option";;
esac

menu
}

menu
