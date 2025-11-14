#!/bin/bash

RPC_URL="https://rpc.inri.life"
CHAIN_ID=3777
SYMBOL="INRI"
SERVICE_NAME="inri-node"
NODE_DIR="/root/inri-node"

clear
echo "=============================================="
echo "        INRI CHAIN AUTO INSTALLER"
echo "=============================================="
echo "  created by yarrr-node.com"
echo "  Telegram Channel : Airdrop Laura"
echo "=============================================="
echo ""

# ---------- GENESIS (PLACEHOLDER, GANTI JIKA ADA RESMI) ----------
GENESIS_CONTENT='
{
  "config": {
    "chainId": 3777,
    "homesteadBlock": 0,
    "eip150Block": 0,
    "eip155Block": 0,
    "eip158Block": 0,
    "byzantiumBlock": 0,
    "constantinopleBlock": 0,
    "petersburgBlock": 0,
    "istanbulBlock": 0,
    "muirGlacierBlock": 0,
    "berlinBlock": 0,
    "londonBlock": 0
  },
  "difficulty": "0x20000",
  "gasLimit": "0x2fefd8",
  "alloc": {}
}
'

# ---------- INSTALL FULL NODE ----------
install_node() {
    echo "[+] Updating system..."
    apt update -y && apt upgrade -y

    echo "[+] Installing dependencies..."
    apt install -y software-properties-common curl wget git

    echo "[+] Installing Geth..."
    add-apt-repository -y ppa:ethereum/ethereum
    apt install -y ethereum

    echo "[+] Preparing node directory..."
    mkdir -p $NODE_DIR
    echo "$GENESIS_CONTENT" > $NODE_DIR/genesis.json

    echo "[+] Initializing genesis..."
    geth --datadir $NODE_DIR init $NODE_DIR/genesis.json

    echo "[+] Creating systemd service..."
    cat <<EOF >/etc/systemd/system/$SERVICE_NAME.service
[Unit]
Description=INRI Chain Node
After=network.target

[Service]
User=root
ExecStart=/usr/bin/geth --datadir $NODE_DIR --networkid $CHAIN_ID --http --http.addr "0.0.0.0" --http.vhosts "*" --port 30303 --http.api "eth,net,web3"
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    echo "[+] Enabling auto-start..."
    systemctl daemon-reload
    systemctl enable $SERVICE_NAME

    echo ""
    echo "===================================================="
    echo " FULL NODE INSTALLED!"
    echo " Your node is ready. Start it with menu option (3)."
    echo "===================================================="
}

# ---------- CONNECT RPC ----------
connect_rpc() {
    echo ""
    echo "================ RPC INFORMATION ================"
    echo " Network Name : INRI CHAIN"
    echo " RPC URL      : $RPC_URL"
    echo " Chain ID     : $CHAIN_ID"
    echo " Symbol       : $SYMBOL"
    echo "================================================="
    echo ""
    echo "Tambahkan RPC ini ke Metamask secara manual."
}

# ---------- RUN NODE ----------
start_node() {
    systemctl start $SERVICE_NAME
    echo "[✓] Node started!"
}

# ---------- STOP NODE ----------
stop_node() {
    systemctl stop $SERVICE_NAME
    echo "[✓] Node stopped!"
}

# ---------- MENU ----------
while true; do
echo ""
echo "============== MENU =============="
echo "1) Install Full Node"
echo "2) Connect Wallet (RPC Info)"
echo "3) Start Node"
echo "4) Stop Node"
echo "5) Exit"
echo "=================================="
read -p "Pilih menu: " choice

case $choice in
    1) install_node ;;
    2) connect_rpc ;;
    3) start_node ;;
    4) stop_node ;;
    5) exit 0 ;;
    *) echo "Pilihan salah!" ;;
esac
done
