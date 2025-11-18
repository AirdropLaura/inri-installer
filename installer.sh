#!/usr/bin/env bash
# INRI Chain — Public RPC & Mining Hub
# Auto Installer & Miner Setup (Menu System)
# created by bastiar
# about: https://yarrr-node.com
# Telegram: @AirdropLaura

set -e

### ============================
### FUNCTIONS
### ============================

# =======================
# FUNGSI CEK & PILIH PORT
# =======================

get_free_port() {
    local START_PORT=$1
    local END_PORT=$2
    for ((port=$START_PORT; port<=$END_PORT; port++)); do
        if ! lsof -i :"$port" >/dev/null 2>&1; then
            echo "$port"
            return
        fi
    done
    echo ""
}

install_inri() {
    echo "=============================================="
    echo "      INRI Chain Miner Auto Installer"
    echo "          QUICK INSTALL (Menu 1)"
    echo "             created by bastiar"
    echo "        https://yarrr-node.com"
    echo "        Telegram: @AirdropLaura"
    echo "=============================================="

    if [[ "$EUID" -ne 0 ]]; then
      echo "Harus dijalankan sebagai root. Gunakan:"
      echo "  sudo bash installer.sh"
      exit 1
    fi

    LNXUSER="${SUDO_USER:-$USER}"

# Cek apakah user valid, jika tidak (misal environment Jupyter/Docker), fallback ke root
if ! id "$LNXUSER" &>/dev/null; then
    echo "[WARN] User Linux '$LNXUSER' tidak ditemukan. Fallback ke root."
    LNXUSER="root"
fi

USER_HOME=$(eval echo "~$LNXUSER")

    DATADIR="$USER_HOME/inri"
    GENESIS_PATH="$USER_HOME/genesis.json"

    DEFAULT_THREADS=4

    echo
    echo "User Linux   : $LNXUSER"
    echo "Data dir     : $DATADIR"
    echo

    read -rp "Masukkan wallet address (0x...): " WALLET
    if [[ ! "$WALLET" =~ ^0x[0-9a-fA-F]{40}$ ]]; then
      echo "Wallet address tidak valid."
      exit 1
    fi

    read -rp "Masukkan jumlah threads miner (default ${DEFAULT_THREADS}): " THREADS_INPUT

    if [[ -z "$THREADS_INPUT" ]]; then
        THREADS="$DEFAULT_THREADS"
    else
        if ! [[ "$THREADS_INPUT" =~ ^[0-9]+$ ]]; then
            echo "Input threads harus berupa angka."
            exit 1
        fi
        THREADS="$THREADS_INPUT"
    fi

    echo
    echo "=============================================="
    echo "      AUTO DETECT P2P PORT (30303)"
    echo "=============================================="

    # Cek apakah port 30303 sedang digunakan
    if lsof -i :30303 >/dev/null 2>&1; then
        echo "[INFO] Port 30303 BENTROK, mencari port bebas..."

        FREE_PORT=$(get_free_port 30310 30400)

        if [[ -z "$FREE_PORT" ]]; then
            echo "[ERROR] Tidak ada port bebas antara 30310–30400"
            exit 1
        fi

        echo "[OK] Port bebas ditemukan: ${FREE_PORT}"
        P2P_PORT="$FREE_PORT"
    else
        echo "[OK] Port 30303 tidak dipakai. Menggunakan port default."
        P2P_PORT=30303
    fi

    echo "[INFO] P2P port yang digunakan: $P2P_PORT"
    echo

    echo "=============================================="
    echo "      AUTO DETECT RPC PORT (8545)"
    echo "=============================================="

    if lsof -i :8545 >/dev/null 2>&1; then
        echo "[INFO] Port 8545 BENTROK, mencari port bebas..."

        FREE_RPC=$(get_free_port 8600 8700)

        if [[ -z "$FREE_RPC" ]]; then
            echo "[ERROR] Tidak ada port RPC bebas antara 8600–8700"
            exit 1
        fi

        echo "[OK] RPC port bebas ditemukan: ${FREE_RPC}"
        RPC_PORT="$FREE_RPC"
    else
        echo "[OK] Port 8545 aman, menggunakan default."
        RPC_PORT=8545
    fi

    echo "[INFO] RPC port yang digunakan: $RPC_PORT"
    echo

    echo "[1/5] Update dependensi..."
    apt-get update -y
    apt-get install -y curl software-properties-common

    GETH_VERSION="1.10.15-8be800ff"
    GETH_TAR="geth-linux-amd64-${GETH_VERSION}.tar.gz"
    GETH_URL="https://gethstore.blob.core.windows.net/builds/${GETH_TAR}"

    echo "[2/5] Install geth v${GETH_VERSION}..."
    if command -v geth &>/dev/null; then
        apt-get remove -y geth || true
        rm -f /usr/local/bin/geth || true
    fi

    cd /usr/local/bin
    curl -fSLo "${GETH_TAR}" "${GETH_URL}"
    tar -xvf "${GETH_TAR}"
    rm -f "${GETH_TAR}"

    GETH_DIR=$(find . -maxdepth 1 -type d -name "geth-linux-amd64-${GETH_VERSION}*" | head -n 1)
    if [[ -z "$GETH_DIR" ]]; then
        echo "Folder Geth tidak ditemukan!"
        exit 1
    fi

    cp "${GETH_DIR}/geth" /usr/local/bin/geth
    chmod +x /usr/local/bin/geth
    rm -rf "${GETH_DIR}"
    cd - >/dev/null

    echo "[3/5] Download genesis.json..."
    sudo -u "$LNXUSER" mkdir -p "$DATADIR"
    sudo -u "$LNXUSER" bash -c "curl -fSLo '$GENESIS_PATH' https://rpc.inri.life/genesis.json"

    if [[ ! -d "$DATADIR/geth" ]]; then
        sudo -u "$LNXUSER" bash -c "geth --datadir '$DATADIR' init '$GENESIS_PATH'"
    fi

    echo "[4/5] Membuat service systemd..."

cat <<EOF > /etc/systemd/system/inri-geth.service
[Unit]
Description=INRI Chain Node (created by bastiar)
After=network.target

[Service]
User=$LNXUSER
Restart=on-failure
RestartSec=10
ExecStart=/usr/local/bin/geth \\
 --datadir "$DATADIR" \\
 --networkid 3777 --port $P2P_PORT \\
 --syncmode full --cache 1024 \\
 --http --http.addr 0.0.0.0 --http.port $RPC_PORT \\
 --http.api eth,net,web3,miner,txpool,admin \\
 --http.corsdomain "*" --http.vhosts "*" \\
 --ws --ws.addr 0.0.0.0 --ws.port 8546 --ws.api eth,net,web3 \\
 --bootnodes "enode://5c7c744a9ac53fdb9e529743208ebd123f11c73d973aa2cf653f3ac1bdf460b6f2a9b2aec23b8f2b9d692d8c898fe0e93dac8d7533db8926924e770969f3a46a@134.199.203.8:30303" \\
 --mine --miner.threads $THREADS --miner.etherbase $WALLET

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable inri-geth.service
    systemctl restart inri-geth.service

    echo "[5/5] Selesai!"
    echo "Node Anda berjalan:"
    echo " - P2P Port : $P2P_PORT"
    echo " - RPC Port : $RPC_PORT"
}

uninstall_inri() {
    systemctl stop inri-geth.service || true
    systemctl disable inri-geth.service || true
    rm -f /etc/systemd/system/inri-geth.service
    systemctl daemon-reload

    echo "Hapus folder node? (y/N)"
    read -r REMOVE_DATA
    [[ "${REMOVE_DATA,,}" == "y" ]] && rm -rf ~/inri ~/genesis.json
    echo "Uninstall selesai."
}

check_logs() {
    journalctl -fu inri-geth
}

restart_node() {
    systemctl restart inri-geth.service
    echo "Node direstart."
}

stop_node() {
    systemctl stop inri-geth.service
    echo "Node distop."
}

### ============================
### MENU UTAMA
### ============================

while true; do
clear
echo "=============================================="
echo "           INRI INSTALLER MENU"
echo "=============================================="
echo "1) Quick Install INRI Node"
echo "2) Uninstall Node"
echo "3) Check Logs"
echo "4) Restart Node"
echo "5) Stop Node"
echo "0) Exit"
echo "=============================================="
read -rp "Pilih menu: " MENU

case $MENU in
    1) install_inri ;;
    2) uninstall_inri ;;
    3) check_logs ;;
    4) restart_node ;;
    5) stop_node ;;
    0) exit 0 ;;
    *) echo "Pilihan tidak valid!" ;;
esac

read -rp "Tekan Enter untuk kembali ke menu..."
done
