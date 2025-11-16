#!/usr/bin/env bash
# INRI Chain — Public RPC & Mining Hub
# Auto Installer & Miner Setup (Quick Install)
# created by bastiar
# about: https://yarrr-node.com
# Telegram: @AirdropLaura

set -e

echo "=============================================="
echo "      INRI Chain Miner Auto Installer"
echo "          QUICK INSTALL (Menu 1)"
echo "             created by bastiar"
echo "        https://yarrr-node.com"
echo "        Telegram: @AirdropLaura"
echo "=============================================="
echo

# Harus root (bisa via sudo)
if [[ "$EUID" -ne 0 ]]; then
  echo "Harus dijalankan sebagai root. Coba:"
  echo "  sudo bash $0"
  exit 1
fi

# User yang akan menjalankan geth (otomatis)
LNXUSER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$LNXUSER")

if ! id "$LNXUSER" &>/dev/null; then
  echo "User $LNXUSER tidak ditemukan."
  exit 1
fi

DATADIR="$USER_HOME/inri"
GENESIS_PATH="$USER_HOME/genesis.json"
THREADS=4

echo "User Linux    : $LNXUSER"
echo "Home          : $USER_HOME"
echo "Data dir      : $DATADIR"
echo "Miner threads : $THREADS"
echo

# ======= SATU-SATUNYA INPUT: WALLET ADDRESS =======
read -rp "Masukkan wallet address (0x...) untuk miner (etherbase): " WALLET

if [[ ! "$WALLET" =~ ^0x[0-9a-fA-F]{40}$ ]]; then
  echo "Wallet address tidak valid. Harus format 0x + 40 karakter hex."
  exit 1
fi
# ==================================================

echo
echo "[1/5] Update system & install dependensi..."
apt-get update -y
apt-get install -y curl software-properties-common

echo
echo "[2/5] Install geth v1.10.26..."

# Hapus geth versi paket kalau ada
if command -v geth &>/dev/null; then
  echo "Menghapus geth versi sebelumnya dari paket (kalau ada)..."
  apt-get remove -y geth || true
fi

cd /usr/local/bin

echo "Mengunduh geth-linux-amd64-1.10.26..."
curl -fSLo geth.tar.gz https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.10.26.tar.gz

tar -xvf geth.tar.gz
rm geth.tar.gz

# Folder unpack biasanya bernama geth-linux-amd64-1.10.26-*
GETH_DIR=$(find . -maxdepth 1 -type d -name "geth-linux-amd64-1.10.26*" | head -n 1)

if [[ -z "$GETH_DIR" ]]; then
  echo "Gagal menemukan folder geth setelah extract!"
  exit 1
fi

echo "Menyalin binary geth..."
cp "$GETH_DIR/geth" /usr/local/bin/geth
chmod +x /usr/local/bin/geth

echo "Membersihkan folder extract..."
rm -rf "$GETH_DIR"

echo "Geth v1.10.26 berhasil diinstall!"
geth version || true

# Balik ke dir sebelumnya (optional)
cd - >/dev/null 2>&1 || true

echo
echo "[3/5] Download genesis INRI & init chain..."
sudo -u "$LNXUSER" mkdir -p "$DATADIR"

# Kamu bisa ganti URL ini ke GitHub kamu kalau mau:
# contoh: https://raw.githubusercontent.com/USERNAME/inri/main/genesis.json
sudo -u "$LNXUSER" bash -c "curl -fSLo '$GENESIS_PATH' https://rpc.inri.life/genesis.json"

# Init hanya jika belum ada database
if [[ ! -d "$DATADIR/geth" ]]; then
  sudo -u "$LNXUSER" bash -c "geth --datadir '$DATADIR' init '$GENESIS_PATH'"
else
  echo "Datadir sudah berisi data geth, skip init."
fi

echo
echo "[4/5] Membuat & menjalankan service systemd: inri-geth.service"

SERVICE_FILE="/etc/systemd/system/inri-geth.service"

cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=INRI Chain Geth Node (created by bastiar)
After=network.target

[Service]
User=$LNXUSER
Type=simple
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

echo
echo "[5/5] (Opsional) Mengatur firewall (ufw)..."
if command -v ufw &>/dev/null; then
  read -rp "Buka port 30303 (tcp/udp), 8545 (tcp), 8546 (tcp) di ufw? [y/N]: " UFWCONF
  UFWCONF=\${UFWCONF,,}
  if [[ "\$UFWCONF" == "y" || "\$UFWCONF" == "yes" ]]; then
    ufw allow 30303/tcp
    ufw allow 30303/udp
    ufw allow 8545/tcp
    ufw allow 8546/tcp
    echo "Port dibuka di ufw."
  else
    echo "Lewati konfigurasi ufw."
  fi
else
  echo "ufw tidak terinstall, skip firewall config."
fi

echo
echo "=============================================="
echo "  QUICK INSTALL SELESAI (Menu 1)"
echo
echo "  Service systemd : inri-geth"
echo "  Cek status      : sudo systemctl status inri-geth"
echo "  Restart         : sudo systemctl restart inri-geth"
echo
echo "  Attach console geth:"
echo "    sudo -u $LNXUSER geth attach \"$DATADIR/geth.ipc\""
echo
echo "  Di dalam console geth:"
echo "    miner.stop()"
echo "    miner.start($THREADS)"
echo "    eth.hashrate"
echo "    eth.blockNumber"
echo "    admin.peers.length"
echo
echo "  created by bastiar"
echo "  https://yarrr-node.com | Telegram: @AirdropLaura"
echo "=============================================="
