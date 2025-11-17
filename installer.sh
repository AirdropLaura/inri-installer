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
    USER_HOME=$(eval echo "~$LNXUSER")

    if ! id "$LNXUSER" &>/dev/null; then
      echo "User Linux tidak ditemukan!"
      exit 1
    fi

    DATADIR="$USER_HOME/inri"
    GENESIS_PATH="$USER_HOME/genesis.json"

    # Default threads miner
    DEFAULT_THREADS=4

    echo
    echo "User Linux   : $LNXUSER"
    echo "Data dir     : $DATADIR"
    echo

    # Input wallet
    read -rp "Masukkan wallet address (0x...): " WALLET
    if [[ ! "$WALLET" =~ ^0x[0-9a-fA-F]{40}$ ]]; then
      echo "Wallet address tidak valid."
      exit 1
    fi

    # Input jumlah threads (boleh Enter untuk default)
    read -rp "Masukkan jumlah threads miner (default ${DEFAULT_THREADS}): " THREADS_INPUT

    if [[ -z "$THREADS_INPUT" ]]; then
        THREADS="$DEFAULT_THREADS"
        echo "Threads miner menggunakan default: $THREADS"
    else
        if ! [[ "$THREADS_INPUT" =~ ^[0-9]+$ ]]; then
            echo "Input threads harus berupa angka."
            exit 1
        fi
        if (( THREADS_INPUT <= 0 )); then
            echo "Threads harus lebih besar dari 0."
            exit 1
        fi
        THREADS="$THREADS_INPUT"
        echo "Threads miner diset ke: $THREADS"
    fi

    echo
    echo "Konfigurasi akhir:"
    echo "  Wallet  : $WALLET"
    echo "  Threads : $THREADS"
    echo

    echo "[1/5] Update dependensi..."
    apt-get update -y
    apt-get install -y curl software-properties-common

    ########################################
    # INSTALL GETH VERSI LAMA (PUNYA miner.threads)
    ########################################
    # Versi Geth yang masih ada MINER OPTIONS + miner.threads
    GETH_VERSION="1.10.15-8be800ff"
    GETH_TAR="geth-linux-amd64-${GETH_VERSION}.tar.gz"
    GETH_URL="https://gethstore.blob.core.windows.net/builds/${GETH_TAR}"

    echo "[2/5] Install geth v${GETH_VERSION}..."
    if command -v geth &>/dev/null; then
        apt-get remove -y geth || true
        rm -f /usr/local/bin/geth || true
    fi

    cd /usr/local/bin

    # Download binary Geth
    curl -fSLo "${GETH_TAR}" "${GETH_URL}"

    # Ekstrak
    tar -xvf "${GETH_TAR}"
    rm -f "${GETH_TAR}"

    # Cari folder hasil ekstrak dan copy binary geth
    GETH_DIR=$(find . -maxdepth 1 -type d -name "geth-linux-amd64-${GETH_VERSION}*" | head -n 1)
    if [[ -z "$GETH_DIR" ]]; then
        echo "Folder Geth tidak ditemukan setelah ekstrak!"
        exit 1
    fi

    cp "${GETH_DIR}/geth" /usr/local/bin/geth
    chmod +x /usr/local/bin/geth
    rm -rf "${GETH_DIR}"

    cd - >/dev/null
    ########################################
    # AKHIR BAGIAN INSTALL GETH
    ########################################

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
 --networkid 3777 --port 30303 \\
 --syncmode full --cache 1024 \\
 --http --http.addr 0.0.0.0 --http.port 8545 \\
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
    echo "Node Anda telah berjalan sebagai service: inri-geth"
}

uninstall_inri() {
    echo "Menghentikan service..."
    systemctl stop inri-geth.service || true
    systemctl disable inri-geth.service || true
    rm -f /etc/systemd/system/inri-geth.service
    systemctl daemon-reload

    echo "Hapus folder node? (y/N)"
    read -r REMOVE_DATA

    if [[ "${REMOVE_DATA,,}" == "y" ]]; then
        rm -rf ~/inri ~/genesis.json
        echo "Data node dihapus."
    fi

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
### MENU
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
