#!/bin/bash

# ========================================= #
#         INRI CHAIN FULL INSTALLER         #
#          With Genesis Initialization       #
#      Created by Bastiar (yarrr-node.com)  #
#     Telegram Channel : Airdrop Laura       #
#          Modified for Geth 1.10.26        #
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
    
    # 1. Install Dependencies
    echo -e "${GREEN}[1/7] Installing Dependencies...${NC}"
    sudo apt update -y >/dev/null 2>&1
    sudo apt install -y curl wget git nano jq tar ufw >/dev/null 2>&1
    echo -e "${GREEN}[✓] Dependencies Installed${NC}"
    
    # 2. Install Geth 1.10.26
    echo -e "${GREEN}[2/7] Installing Geth 1.10.26...${NC}"
    
    # Remove old Geth if exists
    sudo systemctl stop inri-miner 2>/dev/null
    sudo apt remove -y geth 2>/dev/null
    sudo apt autoremove -y >/dev/null 2>&1
    sudo add-apt-repository --remove ppa:ethereum/ethereum 2>/dev/null
    
    # Download Geth 1.10.26
    cd /tmp
    wget -q --show-progress "$GETH_URL"
    tar -xzf geth-linux-amd64-1.10.26-e5eb32ac.tar.gz
    sudo cp geth-linux-amd64-1.10.26-e5eb32ac/geth /usr/bin/
    sudo chmod +x /usr/bin/geth
    rm -rf geth-linux-amd64-1.10.26-e5eb32ac*
    
    INSTALLED_VERSION=$(geth version | grep "Version:" | awk '{print $2}')
    echo -e "${GREEN}[✓] Geth $INSTALLED_VERSION Installed${NC}"
    
    # 3. Download Genesis
    echo -e "${GREEN}[3/7] Downloading Genesis...${NC}"
    mkdir -p $DATADIR
    curl -fSLo "$HOME/genesis.json" "$GENESIS_URL" 2>/dev/null
    echo -e "${GREEN}[✓] Genesis Downloaded${NC}"
    
    # 4. Init Blockchain
    echo -e "${GREEN}[4/7] Initializing Blockchain...${NC}"
    
    # Backup old datadir if exists
    if [ -d "$DATADIR/geth" ]; then
        echo -e "${YELLOW}[~] Backing up old datadir...${NC}"
        mv "$DATADIR" "${DATADIR}.backup.$(date +%s)"
    fi
    
    geth --datadir "$DATADIR" init "$HOME/genesis.json" >/dev/null 2>&1
    echo -e "${GREEN}[✓] Blockchain Initialized${NC}"
    
    # 5. Setup Firewall
    echo -e "${GREEN}[5/7] Configuring Firewall...${NC}"
    
    if ! sudo ufw status | grep -q "Status: active"; then
        echo "y" | sudo ufw enable >/dev/null 2>&1
    fi
    
    sudo ufw allow 22/tcp >/dev/null 2>&1
    sudo ufw allow 30303/tcp >/dev/null 2>&1
    sudo ufw allow 30303/udp >/dev/null 2>&1
    sudo ufw reload >/dev/null 2>&1
    
    echo -e "${GREEN}[✓] Firewall Configured${NC}"
    
    # 6. Get Wallet Address
    echo -e "${GREEN}[6/7] Miner Configuration...${NC}"
    echo ""
    echo -e "${YELLOW}Enter your wallet address (0x...):${NC}"
    read WALLET
    
    # Validate wallet address
    if [[ ! $WALLET =~ ^0x[a-fA-F0-9]{40}$ ]]; then
        echo -e "${RED}[!] Invalid wallet address format!${NC}"
        echo -e "${RED}Setup failed. Please run again with valid address.${NC}"
        return 1
    fi
    
    # 7. Create Miner Service
    echo -e "${GREEN}[7/7] Creating Miner Service...${NC}"
    
    # Get CPU cores
    CPU_CORES=$(nproc)
    MINER_THREADS=$((CPU_CORES / 2))
    [ $MINER_THREADS -lt 1 ] && MINER_THREADS=1
    
    # Get public IP
    PUBLIC_IP=$(curl -s ifconfig.me)

    sudo tee /etc/systemd/system/inri-miner.service >/dev/null <<EOF
[Unit]
Description=INRI Chain Miner (Geth 1.10.26)
After=network.target

[Service]
User=root
Type=simple

ExecStart=/usr/bin/geth --datadir $DATADIR \\
 --networkid 3777 \\
 --syncmode full \\
 --gcmode archive \\
 --cache 2048 \\
 --maxpeers 50 \\
 --http --http.addr 127.0.0.1 --http.port 8545 \\
 --http.api eth,net,web3,miner,txpool,admin \\
 --http.corsdomain "localhost" --http.vhosts "localhost" \\
 --ws --ws.addr 127.0.0.1 --ws.port 8546 \\
 --ws.api eth,net,web3 \\
 --port 30303 \\
 --bootnodes "$BOOTNODES" \\
 --mine --miner.threads $MINER_THREADS --miner.etherbase "$WALLET" \\
 --nat extip:$PUBLIC_IP \\
 --verbosity 3

Restart=always
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable inri-miner >/dev/null 2>&1
    sudo systemctl start inri-miner

    echo -e "${GREEN}[✓] Miner Service Started${NC}"
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}    ✓ Setup Complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "${YELLOW}Wallet: $WALLET${NC}"
    echo -e "${YELLOW}Mining Threads: $MINER_THREADS${NC}"
    echo -e "${YELLOW}Public IP: $PUBLIC_IP${NC}"
    echo ""
    echo -e "${YELLOW}⏳ DAG generation will take 5-10 minutes${NC}"
    echo -e "${YELLOW}📊 View logs: journalctl -fu inri-miner${NC}"
    echo -e "${YELLOW}📈 Check status: Run this script again (menu 2)${NC}"
    echo ""
}

logs_miner() {
    journalctl -fu inri-miner
}

check_status() {
    echo -e "${BLUE}========= INRI Mining Status =========${NC}"
    echo ""
    
    # Service status
    if systemctl is-active --quiet inri-miner; then
        echo -e "${GREEN}Service: RUNNING ✓${NC}"
    else
        echo -e "${RED}Service: STOPPED ✗${NC}"
        echo ""
        echo -e "${YELLOW}Run Quick Setup first (menu 1)${NC}"
        return
    fi
    
    echo ""
    echo -e "${YELLOW}Fetching mining stats...${NC}"
    echo ""
    
    # Mining stats
    MINING=$(geth attach $DATADIR/geth.ipc --exec 'eth.mining' 2>/dev/null)
    HASHRATE=$(geth attach $DATADIR/geth.ipc --exec 'eth.hashrate' 2>/dev/null)
    PEERS=$(geth attach $DATADIR/geth.ipc --exec 'net.peerCount' 2>/dev/null)
    BLOCK=$(geth attach $DATADIR/geth.ipc --exec 'eth.blockNumber' 2>/dev/null)
    COINBASE=$(geth attach $DATADIR/geth.ipc --exec 'eth.coinbase' 2>/dev/null | tr -d '"')
    
    echo "Mining Active: $MINING"
    echo "Hashrate: $HASHRATE H/s"
    echo "Peers Connected: $PEERS"
    echo "Current Block: $BLOCK"
    echo "Miner Address: $COINBASE"
    echo ""
    
    if [ "$COINBASE" != "null" ] && [ ! -z "$COINBASE" ]; then
        BALANCE=$(geth attach $DATADIR/geth.ipc --exec "web3.fromWei(eth.getBalance('$COINBASE'), 'ether')" 2>/dev/null)
        echo "Balance: $BALANCE INRI"
    fi
    
    echo ""
    echo "Sync Status:"
    SYNCING=$(geth attach $DATADIR/geth.ipc --exec 'eth.syncing' 2>/dev/null)
    if [ "$SYNCING" == "false" ]; then
        echo -e "${GREEN}✓ Fully Synced${NC}"
    else
        echo "$SYNCING"
    fi
    
    echo ""
    echo -e "${BLUE}=======================================${NC}"
}

check_balance() {
    echo -e "${YELLOW}Enter wallet address (0x...):${NC}"
    read WALLET
    
    if [[ ! $WALLET =~ ^0x[a-fA-F0-9]{40}$ ]]; then
        echo -e "${RED}[!] Invalid wallet address!${NC}"
        return
    fi
    
    echo ""
    echo -e "${GREEN}Checking balance for:${NC}"
    echo "$WALLET"
    echo ""
    
    BALANCE=$(geth attach $DATADIR/geth.ipc --exec "web3.fromWei(eth.getBalance('$WALLET'), 'ether')" 2>/dev/null)
    echo -e "${GREEN}Balance: $BALANCE INRI${NC}"
    echo ""
}

restart_miner() {
    echo -e "${YELLOW}[~] Restarting miner...${NC}"
    sudo systemctl restart inri-miner
    sleep 2
    if systemctl is-active --quiet inri-miner; then
        echo -e "${GREEN}[✓] Miner restarted successfully${NC}"
    else
        echo -e "${RED}[✗] Failed to restart miner${NC}"
    fi
}

stop_miner() {
    echo -e "${YELLOW}[~] Stopping miner...${NC}"
    sudo systemctl stop inri-miner
    sudo systemctl disable inri-miner >/dev/null 2>&1
    echo -e "${GREEN}[✓] Miner stopped${NC}"
}

remove_all() {
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}    WARNING: Remove Everything${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo -e "${YELLOW}This will remove:${NC}"
    echo "  - Miner service"
    echo "  - Blockchain data (~/.inri/)"
    echo "  - Genesis file"
    echo ""
    echo -e "${RED}Are you sure? Type 'yes' to confirm:${NC}"
    read CONFIRM
    
    if [ "$CONFIRM" != "yes" ]; then
        echo -e "${GREEN}Cancelled${NC}"
        return
    fi
    
    echo ""
    echo -e "${YELLOW}Removing...${NC}"
    
    sudo systemctl stop inri-miner 2>/dev/null
    sudo systemctl disable inri-miner 2>/dev/null
    sudo rm -f /etc/systemd/system/inri-miner.service
    rm -rf $DATADIR
    rm -f $HOME/genesis.json
    sudo systemctl daemon-reload
    
    echo -e "${GREEN}[✓] Removed completely${NC}"
    echo ""
}

menu() {
banner
echo -e "${BLUE}=============== MENU ===============${NC}"
echo "1) Quick Setup (Fresh Install)"
echo "2) Check Mining Status"
echo "3) View Live Logs"
echo "4) Check Balance"
echo "5) Restart Miner"
echo "6) Stop Miner"
echo "7) Remove All"
echo "0) Exit"
echo -e "${BLUE}====================================${NC}"
read -p "Choose: " CH

case $CH in
1) quick_setup ;;
2) check_status ;;
3) logs_miner ;;
4) check_balance ;;
5) restart_miner ;;
6) stop_miner ;;
7) remove_all ;;
0) exit ;;
*) echo "Invalid option";;
esac

menu
}

menu
