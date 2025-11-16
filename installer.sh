#!/bin/bash

# ========================================= #
#      INRI CHAIN SMART AUTO INSTALLER      #
#        Auto-Adjust CPU Optimization       #
#     Created by Bastiar (yarrr-node.com)   #
#     Telegram Channel : Airdrop Laura      #
#           Smart Adaptive Edition          #
# ========================================= #

BLUE="\e[34m"
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
NC="\e[0m"

GENESIS_URL="https://rpc.inri.life/genesis.json"
DATADIR="$HOME/inri"
GETH_VERSION="1.10.26"
GETH_URL="https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.10.26-e5eb32ac.tar.gz"
BOOTNODES="enode://5c7c744a9ac53fdb9e529743208ebd123f11c73d973aa2cf653f3ac1bdf460b6f2a9b2aec23b8f2b9d692d8c898fe0e93dac8d7533db8926924e770969f3a46a@134.199.203.8:30303"

# ========================================= #
#         BASIC DEPENDENCY CHECK            #
# ========================================= #
ensure_bc() {
    if ! command -v bc >/dev/null 2>&1; then
        echo -e "${YELLOW}[~] Installing bc (required for auto tuning)...${NC}"
        sudo apt update -y >/dev/null 2>&1
        sudo apt install -y bc >/dev/null 2>&1
    fi
}

# ========================================= #
#      SMART CPU AUTO-DETECTION             #
# ========================================= #
calculate_optimal_settings() {
    ensure_bc

    local CPU_CORES
    CPU_CORES=$(nproc)
    local TOTAL_RAM
    TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')

    # Logic berdasarkan jumlah core
    if [ "$CPU_CORES" -le 2 ]; then
        # VPS Kecil (1-2 cores)
        MINER_THREADS=1
        CACHE_SIZE=512
        MAX_PEERS=15
        RECOMMIT_TIME="5s"
        MODE="Conservative (Stable)"

    elif [ "$CPU_CORES" -le 4 ]; then
        # VPS Sedang (3-4 cores) - 50-60% usage
        MINER_THREADS=$(echo "($CPU_CORES * 0.6)/1" | bc)
        [ "$MINER_THREADS" -lt 2 ] && MINER_THREADS=2
        CACHE_SIZE=2048
        MAX_PEERS=30
        RECOMMIT_TIME="3s"
        MODE="Balanced (Optimal)"

    elif [ "$CPU_CORES" -le 8 ]; then
        # VPS Medium (5-8 cores) - 75% usage
        MINER_THREADS=$(echo "($CPU_CORES * 0.75)/1" | bc)
        CACHE_SIZE=3072
        MAX_PEERS=40
        RECOMMIT_TIME="2s"
        MODE="Performance (High)"

    elif [ "$CPU_CORES" -le 16 ]; then
        # VPS Besar (9-16 cores) - 85% usage
        MINER_THREADS=$(echo "($CPU_CORES * 0.85)/1" | bc)
        CACHE_SIZE=4096
        MAX_PEERS=50
        RECOMMIT_TIME="1s"
        MODE="Aggressive (Very High)"

    else
        # VPS Jumbo (17+ cores) - FULL POWER
        MINER_THREADS="$CPU_CORES"
        CACHE_SIZE=8192
        MAX_PEERS=100
        RECOMMIT_TIME="500ms"
        MODE="Maximum (Beast Mode)"
    fi

    # Adjust cache based on RAM
    if [ "$TOTAL_RAM" -lt 4096 ]; then
        CACHE_SIZE=512
    elif [ "$TOTAL_RAM" -lt 8192 ]; then
        [ "$CACHE_SIZE" -gt 2048 ] && CACHE_SIZE=2048
    fi

    # Ensure minimum values
    [ "$MINER_THREADS" -lt 1 ] && MINER_THREADS=1
    [ "$CACHE_SIZE" -lt 512 ] && CACHE_SIZE=512
    [ "$MAX_PEERS" -lt 10 ] && MAX_PEERS=10

    # Hitung estimasi CPU (clamp ke 100%)
    local EXPECTED_CPU
    EXPECTED_CPU=$(echo "($MINER_THREADS * 100) / $CPU_CORES" | bc)
    if [ "$EXPECTED_CPU" -gt 100 ]; then
        EXPECTED_CPU=100
    fi
    EXPECTED_CPU_PERCENT="$EXPECTED_CPU"
}

banner() {
    clear
    echo -e "${BLUE}"
    echo "=============================================="
    echo "      INRI SMART INSTALLER v3.0 (Auto)        "
    echo "=============================================="
    echo -e "${GREEN}Auto-Adjusts to YOUR VPS Specifications!${NC}"
    echo -e "${YELLOW}Created by Bastiar - https://yarrr-node.com${NC}"
    echo -e "${YELLOW}Telegram Channel : Airdrop Laura${NC}"
    echo ""
}

show_detected_specs() {
    calculate_optimal_settings

    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   DETECTED VPS SPECIFICATIONS${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}CPU Cores:${NC} $(nproc) cores"
    echo -e "${GREEN}Total RAM:${NC} $(free -h | awk '/^Mem:/{print $2}')"
    echo -e "${GREEN}Free RAM:${NC}  $(free -h | awk '/^Mem:/{print $4}')"
    echo ""
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}   OPTIMIZED MINING SETTINGS${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${GREEN}Mode:${NC}            $MODE"
    echo -e "${GREEN}Mining Threads:${NC}  $MINER_THREADS threads"
    echo -e "${GREEN}Cache Size:${NC}      ${CACHE_SIZE}MB"
    echo -e "${GREEN}Max Peers:${NC}       $MAX_PEERS"
    echo -e "${GREEN}Recommit Time:${NC}   $RECOMMIT_TIME"
    echo ""
    echo -e "${YELLOW}Expected CPU Usage:${NC} ~${EXPECTED_CPU_PERCENT}%"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

quick_setup() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}    QUICK SETUP - Installing...${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""

    show_detected_specs

    echo -e "${YELLOW}Continue with these settings? (y/n):${NC}"
    read -r CONFIRM
    if [ "$CONFIRM" != "y" ]; then
        echo -e "${RED}Installation cancelled.${NC}"
        sleep 2
        return
    fi

    # 1. Install dependencies
    echo -e "${GREEN}[1/7] Installing Dependencies...${NC}"
    sudo apt update -y >/dev/null 2>&1
    sudo apt install -y curl wget git nano jq tar ufw bc >/dev/null 2>&1
    echo -e "${GREEN}[✓] Dependencies Installed${NC}"

    # 2. Install geth
    echo -e "${GREEN}[2/7] Installing Geth...${NC}"
    sudo systemctl stop inri-miner 2>/dev/null

    cd /tmp || exit 1
    wget -q "$GETH_URL"
    tar -xzf "geth-linux-amd64-${GETH_VERSION}-e5eb32ac.tar.gz"
    sudo cp "geth-linux-amd64-${GETH_VERSION}-e5eb32ac/geth" /usr/bin/
    sudo chmod +x /usr/bin/geth
    rm -rf "geth-linux-amd64-${GETH_VERSION}-e5eb32ac"*

    echo -e "${GREEN}[✓] Geth Installed${NC}"

    # 3. Download genesis
    echo -e "${GREEN}[3/7] Downloading Genesis...${NC}"
    mkdir -p "$DATADIR"
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
    read -r WALLET

    if [[ ! $WALLET =~ ^0x[a-fA-F0-9]{40}$ ]]; then
        echo -e "${RED}[!] Invalid wallet address!${NC}"
        sleep 2
        return
    fi

    # 7. Create miner service with SMART settings
    echo -e "${GREEN}[7/7] Creating Smart Miner Service...${NC}"

    PUBLIC_IP=$(curl -s ifconfig.me)

sudo tee /etc/systemd/system/inri-miner.service >/dev/null <<EOF
[Unit]
Description=INRI Chain Miner (Smart Auto-Optimized)
After=network.target

[Service]
User=root
Type=simple
Nice=-10

ExecStart=/usr/bin/geth --datadir "$DATADIR" \\
 --networkid 3777 \\
 --syncmode full \\
 --gcmode archive \\
 --cache $CACHE_SIZE \\
 --maxpeers $MAX_PEERS \\
 --http --http.addr 127.0.0.1 --http.port 8545 \\
 --http.api eth,net,web3,miner,txpool,admin \\
 --ws --ws.addr 127.0.0.1 --ws.port 8546 \\
 --ws.api eth,net,web3 \\
 --port 30303 \\
 --bootnodes "$BOOTNODES" \\
 --mine --miner.threads $MINER_THREADS --miner.etherbase "$WALLET" \\
 --miner.gaslimit 30000000 \\
 --miner.gastarget 30000000 \\
 --miner.recommit $RECOMMIT_TIME \\
 --nat extip:$PUBLIC_IP \\
 --verbosity 3 \\
 --ipcpath "$DATADIR/geth.ipc"

Restart=always
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable inri-miner >/dev/null 2>&1
    sudo systemctl start inri-miner

    echo -e "${GREEN}[✓] Smart Miner Started${NC}"
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   INSTALLATION COMPLETE${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}Mode:${NC}            $MODE"
    echo -e "${GREEN}Wallet:${NC}          $WALLET"
    echo -e "${GREEN}Mining Threads:${NC}  $MINER_THREADS / $(nproc) cores"
    echo -e "${GREEN}Cache:${NC}           ${CACHE_SIZE}MB"
    echo -e "${GREEN}Public IP:${NC}       $PUBLIC_IP"
    echo ""
    echo -e "${YELLOW}Check CPU usage in 2 minutes:${NC}"
    echo -e "${YELLOW}top -p \$(pgrep geth)${NC}"
    echo ""
    echo -e "${YELLOW}View logs:${NC}"
    echo -e "${YELLOW}journalctl -fu inri-miner${NC}"
    echo -e "${BLUE}========================================${NC}"

    read -p "Press Enter to continue..." -r
}

reoptimize_existing() {
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}   RE-OPTIMIZE EXISTING MINER${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo ""

    if [ ! -f "/etc/systemd/system/inri-miner.service" ]; then
        echo -e "${RED}[!] Miner service not found. Install first.${NC}"
        sleep 2
        return
    fi

    WALLET=$(grep "miner.etherbase" /etc/systemd/system/inri-miner.service | grep -oP '0x[a-fA-F0-9]{40}')

    if [ -z "$WALLET" ]; then
        echo -e "${YELLOW}Enter your wallet address (0x...):${NC}"
        read -r WALLET
        if [[ ! $WALLET =~ ^0x[a-fA-F0-9]{40}$ ]]; then
            echo -e "${RED}[!] Invalid wallet address!${NC}"
            sleep 2
            return
        fi
    fi

    show_detected_specs

    echo -e "${YELLOW}Apply these optimized settings? (y/n):${NC}"
    read -r CONFIRM
    if [ "$CONFIRM" != "y" ]; then
        echo -e "${RED}Cancelled.${NC}"
        sleep 2
        return
    fi

    echo -e "${YELLOW}[~] Stopping miner...${NC}"
    sudo systemctl stop inri-miner
    sleep 3
    sudo killall -9 geth 2>/dev/null
    sleep 2

    PUBLIC_IP=$(curl -s ifconfig.me)

    echo -e "${YELLOW}[~] Updating configuration...${NC}"

sudo tee /etc/systemd/system/inri-miner.service >/dev/null <<EOF
[Unit]
Description=INRI Chain Miner (Smart Auto-Optimized)
After=network.target

[Service]
User=root
Type=simple
Nice=-10

ExecStart=/usr/bin/geth --datadir "$DATADIR" \\
 --networkid 3777 \\
 --syncmode full \\
 --gcmode archive \\
 --cache $CACHE_SIZE \\
 --maxpeers $MAX_PEERS \\
 --http --http.addr 127.0.0.1 --http.port 8545 \\
 --http.api eth,net,web3,miner,txpool,admin \\
 --ws --ws.addr 127.0.0.1 --ws.port 8546 \\
 --ws.api eth,net,web3 \\
 --port 30303 \\
 --bootnodes "$BOOTNODES" \\
 --mine --miner.threads $MINER_THREADS --miner.etherbase "$WALLET" \\
 --miner.gaslimit 30000000 \\
 --miner.gastarget 30000000 \\
 --miner.recommit $RECOMMIT_TIME \\
 --nat extip:$PUBLIC_IP \\
 --verbosity 3 \\
 --ipcpath "$DATADIR/geth.ipc"

Restart=always
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl start inri-miner

    echo -e "${GREEN}[✓] Miner Re-optimized and Restarted${NC}"
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}New Settings Applied:${NC}"
    echo -e "${GREEN}Mode:${NC}      $MODE"
    echo -e "${GREEN}Threads:${NC}   $MINER_THREADS"
    echo -e "${GREEN}Cache:${NC}     ${CACHE_SIZE}MB"
    echo -e "${GREEN}Max Peers:${NC} $MAX_PEERS"
    echo -e "${BLUE}========================================${NC}"

    read -p "Press Enter to continue..." -r
}

logs_miner() {
    journalctl -fu inri-miner
}

restart_miner() {
    echo -e "${YELLOW}[~] Restarting miner...${NC}"
    sudo systemctl restart inri-miner
    sleep 2
}

stop_miner() {
    echo -e "${YELLOW}[~] Stopping miner...${NC}"
    sudo systemctl stop inri-miner
    sudo systemctl disable inri-miner >/dev/null 2>&1
    sleep 2
}

remove_all() {
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}WARNING: This will remove all mining data.${NC}"
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}Type 'DELETE' (uppercase) to continue:${NC}"
    read -r CONFIRM

    if [ "$CONFIRM" != "DELETE" ]; then
        echo -e "${GREEN}Cancelled.${NC}"
        sleep 2
        return
    fi

    echo -e "${YELLOW}[~] Stopping service...${NC}"
    sudo systemctl stop inri-miner
    sudo systemctl disable inri-miner

    echo -e "${YELLOW}[~] Removing files...${NC}"
    sudo rm -f /etc/systemd/system/inri-miner.service
    rm -rf "$DATADIR"
    rm -rf "${DATADIR}.backup."*
    rm -f "$HOME/genesis.json"
    sudo systemctl daemon-reload

    echo -e "${GREEN}[✓] Removed completely${NC}"
    sleep 2
}

status_check() {
    calculate_optimal_settings

    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   CURRENT MINER STATUS${NC}"
    echo -e "${BLUE}========================================${NC}"

    if systemctl is-active --quiet inri-miner; then
        echo -e "${GREEN}Service:${NC} Running ✓"
    else
        echo -e "${RED}Service:${NC} Stopped ✗"
    fi

    if [ -S "$DATADIR/geth.ipc" ]; then
        MINING=$(geth attach "$DATADIR/geth.ipc" --exec 'eth.mining' 2>/dev/null)
        BLOCK=$(geth attach "$DATADIR/geth.ipc" --exec 'eth.blockNumber' 2>/dev/null)
        PEERS=$(geth attach "$DATADIR/geth.ipc" --exec 'net.peerCount' 2>/dev/null)
        WALLET=$(geth attach "$DATADIR/geth.ipc" --exec 'eth.coinbase' 2>/dev/null)
        BALANCE=$(geth attach "$DATADIR/geth.ipc" --exec "eth.getBalance('$WALLET')" 2>/dev/null)

        echo -e "${GREEN}Mining:${NC} $MINING"
        echo -e "${GREEN}Block:${NC}  $BLOCK"
        echo -e "${GREEN}Peers:${NC}  $PEERS"
        echo -e "${GREEN}Wallet:${NC} $WALLET"

        if [ -n "$BALANCE" ] && [ "$BALANCE" != "0" ]; then
            BALANCE_ETH=$(echo "scale=6; $BALANCE / 1000000000000000000" | bc)
            echo -e "${GREEN}Balance:${NC} $BALANCE_ETH INRI"
        else
            echo -e "${YELLOW}Balance:${NC} 0 INRI"
        fi

        CPU_USAGE=$(ps aux | grep geth | grep -v grep | awk '{print $3}')
        echo -e "${GREEN}CPU Usage:${NC} ${CPU_USAGE}%"
    else
        echo -e "${YELLOW}IPC not available - service starting or not ready...${NC}"
    fi

    echo ""
    echo -e "${YELLOW}Recommended Settings for This VPS:${NC}"
    echo -e "${GREEN}Mode:${NC}     $MODE"
    echo -e "${GREEN}Threads:${NC}  $MINER_THREADS"
    echo -e "${GREEN}Cache:${NC}    ${CACHE_SIZE}MB"
    echo -e "${GREEN}Max Peers:${NC} $MAX_PEERS"
    echo -e "${BLUE}========================================${NC}"

    read -p "Press Enter to continue..." -r
}

menu() {
    while true; do
        banner
        echo -e "${BLUE}=============== MENU ===============${NC}"
        echo "1) Quick Setup (Fresh Install)"
        echo "2) Re-Optimize Existing Miner"
        echo "3) Check Status & Specs"
        echo "4) View Live Logs"
        echo "5) Restart Miner"
        echo "6) Stop Miner"
        echo "7) Remove All"
        echo "0) Exit"
        echo -e "${BLUE}====================================${NC}"
        read -p "Choose: " CH

        case $CH in
            1) quick_setup ;;
            2) reoptimize_existing ;;
            3) status_check ;;
            4) logs_miner ;;
            5) restart_miner ;;
            6) stop_miner ;;
            7) remove_all ;;
            0)
                echo -e "${GREEN}Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                sleep 1
                ;;
        esac
    done
}

# Start the menu
menu
