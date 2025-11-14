#!/bin/bash
# INRI CHAIN INSTALLER (final)
# created by bastiar
# find me on https://yarrr-node
# Telegram Channel: Airdrop Laura
# Mode: Node = systemd auto-start | Miner = screen (manual)
set -e

# -------- CONFIG ----------
RPC_URL="https://rpc.inri.life"
CHAIN_ID=3777
SYMBOL="INRI"
NODE_DIR="$HOME/inri"
SERVICE_NAME="inri-node"
MINER_SCREEN="inri-miner"
GETH_BIN="$(which geth 2>/dev/null || echo /usr/bin/geth)"
BOOTNODES="enode://5c7c744a9ac53fdb9e529743208ebd123f11c73d973aa2cf653f3ac1bdf460b6f2a9b2aec23b8f2b9d692d8c898fe0e93dac8d7533db8926924e770969f3a46a@134.199.203.8:30303,enode://f196abde38edd1db5d4208a6823fd9d5ce5823a6730c32739b9f351558f254e8d6d32b6d7a8ca43304cbcfe5c172f4a9a25defacd36eea6f5752f3b4bc01cdf@170.64.222.34:30303"

# Colors
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

clear
echo -e "${YELLOW}==============================================${RESET}"
echo -e "${GREEN}        INRI CHAIN AUTO INSTALLER${RESET}"
echo -e "${YELLOW}==============================================${RESET}"
echo -e "  created by: ${GREEN}bastiar${RESET}"
echo -e "  find me on: ${GREEN}https://yarrr-node.com${RESET}"
echo -e "  Telegram   : ${GREEN}Airdrop Laura${RESET}"
echo -e "${YELLOW}==============================================${RESET}"
echo

# -------- Helpers ----------
require_root() {
  if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run this script as root (or sudo).${RESET}"
    exit 1
  fi
}

prompt_continue() {
  read -p "Press Enter to continue..."
}

check_geth() {
  if command -v geth >/dev/null 2>&1; then
    GETH_BIN="$(command -v geth)"
    return 0
  else
    return 1
  fi
}

# -------- Actions ----------
install_dependencies() {
  require_root
  echo -e "${GREEN}[+] Updating system and installing dependencies...${RESET}"
  apt update -y && apt upgrade -y
  apt install -y software-properties-common curl wget git screen jq build-essential
  echo -e "${GREEN}[+] Dependencies installed.${RESET}"
  prompt_continue
}

install_geth() {
  require_root
  echo -e "${GREEN}[+] Installing Geth (ethereum)...${RESET}"
  add-apt-repository -y ppa:ethereum/ethereum
  apt update -y
  apt install -y ethereum
  check_geth && echo -e "${GREEN}[+] Geth installed: $(geth version | head -n1)${RESET}" || echo -e "${RED}[!] Geth install failed or not found.${RESET}"
  prompt_continue
}

download_and_init_genesis() {
  require_root
  mkdir -p "$NODE_DIR"
  echo -e "${GREEN}[+] Downloading genesis.json from remote RPC...${RESET}"
  if curl -fsSL -o "$NODE_DIR/genesis.json" "${RPC_URL}/genesis.json"; then
    echo -e "${GREEN}[+] genesis.json downloaded to $NODE_DIR/genesis.json${RESET}"
  else
    echo -e "${RED}[!] Failed to download genesis.json from ${RPC_URL}/genesis.json${RESET}"
    echo -e "${YELLOW}You can place a genesis.json at $NODE_DIR/genesis.json manually.${RESET}"
    prompt_continue
    return
  fi

  echo -e "${GREEN}[+] Initializing geth datadir...${RESET}"
  $GETH_BIN --datadir "$NODE_DIR" init "$NODE_DIR/genesis.json"
  echo -e "${GREEN}[+] Init done.${RESET}"
  prompt_continue
}

create_systemd_service() {
  require_root
  echo -e "${GREEN}[+] Creating systemd service for the node (${SERVICE_NAME})...${RESET}"
  cat >/etc/systemd/system/${SERVICE_NAME}.service <<EOF
[Unit]
Description=INRI Chain Node
After=network.target

[Service]
Type=simple
User=root
ExecStart=${GETH_BIN} --datadir ${NODE_DIR} --networkid ${CHAIN_ID} --http --http.addr 0.0.0.0 --http.port 8545 --http.api eth,net,web3,miner,txpool,admin --http.corsdomain "*" --http.vhosts "*" --ws --ws.addr 0.0.0.0 --ws.port 8546 --ws.api eth,net,web3 --port 30303 --bootnodes "${BOOTNODES}"
Restart=always
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable ${SERVICE_NAME}
  echo -e "${GREEN}[+] systemd service created and enabled.${RESET}"
  prompt_continue
}

start_node() {
  require_root
  echo -e "${GREEN}[+] Starting node service...${RESET}"
  systemctl start ${SERVICE_NAME}
  sleep 2
  systemctl status ${SERVICE_NAME} --no-pager
  echo
  echo -e "${YELLOW}You can follow logs with:${RESET} journalctl -u ${SERVICE_NAME} -f"
  prompt_continue
}

stop_node() {
  require_root
  echo -e "${GREEN}[+] Stopping node service...${RESET}"
  systemctl stop ${SERVICE_NAME}
  echo -e "${GREEN}[+] Node stopped.${RESET}"
  prompt_continue
}

start_miner_screen() {
  # Miner runs in screen (manual-style) per choice B
  echo -e "${GREEN}[+] Starting miner in screen session '${MINER_SCREEN}'...${RESET}"
  read -p "Enter your miner wallet address (0x...): " MINER_WALLET
  if [[ -z "$MINER_WALLET" ]]; then
    echo -e "${RED}[!] Wallet address required.${RESET}"; return
  fi
  # ensure node dir exists
  mkdir -p "$NODE_DIR"
  # Build command
  MINER_CMD="${GETH_BIN} --datadir ${NODE_DIR} --networkid ${CHAIN_ID} --port 30303 --syncmode full --cache 1024 --http --http.addr 0.0.0.0 --http.port 8545 --http.api eth,net,web3,miner,txpool,admin --http.corsdomain \"*\" --http.vhosts \"*\" --ws --ws.addr 0.0.0.0 --ws.port 8546 --ws.api eth,net,web3 --bootnodes \"${BOOTNODES}\" --mine --miner.threads 4 --miner.etherbase ${MINER_WALLET}"
  # run in detached screen
  screen -S ${MINER_SCREEN} -dm bash -c "${MINER_CMD} >/var/log/inri-miner.log 2>&1"
  echo -e "${GREEN}[+] Miner started in screen: screen -r ${MINER_SCREEN}${RESET}"
  echo -e "${YELLOW}Logs: tail -n 200 /var/log/inri-miner.log${RESET}"
  prompt_continue
}

stop_miner_screen() {
  echo -e "${GREEN}[+] Stopping miner screen session (if exists)...${RESET}"
  if screen -list | grep -q "${MINER_SCREEN}"; then
    screen -S ${MINER_SCREEN} -X quit
    echo -e "${GREEN}[+] Miner screen session stopped.${RESET}"
  else
    echo -e "${YELLOW}[!] Miner screen session not found.${RESET}"
  fi
  # also attempt to kill any stray geth mine processes (careful)
  pkill -f --oldest --full "${GETH_BIN}.*--mine" || true
  prompt_continue
}

check_node_sync() {
  echo -e "${GREEN}[+] Checking node sync status (rpc)...${RESET}"
  # try query via local rpc
  if curl -sS --max-time 3 http://127.0.0.1:8545 >/dev/null 2>&1; then
    echo -e "${YELLOW}Local RPC reachable. Querying...${RESET}"
    curl -s -X POST http://127.0.0.1:8545 -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' | jq .
    echo
    echo -e "BlockNumber via RPC:"
    curl -s -X POST http://127.0.0.1:8545 -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' | jq -r '.result'
  else
    echo -e "${RED}Local RPC http://127.0.0.1:8545 not reachable. Is node running?${RESET}"
  fi
  prompt_continue
}

show_logs() {
  echo -e "${GREEN}Node logs (journalctl) - press Ctrl+C to quit${RESET}"
  journalctl -u ${SERVICE_NAME} -f
}

show_miner_logfile() {
  tail -n 200 /var/log/inri-miner.log || echo -e "${YELLOW}No miner log file found yet.${RESET}"
  prompt_continue
}

remove_node() {
  require_root
  echo -e "${RED}This will stop node, disable service and remove node data. Continue? (type YES)${RESET}"
  read -p "> " CONF
  if [[ "$CONF" == "YES" ]]; then
    systemctl stop ${SERVICE_NAME} || true
    systemctl disable ${SERVICE_NAME} || true
    rm -f /etc/systemd/system/${SERVICE_NAME}.service || true
    systemctl daemon-reload
    rm -rf "${NODE_DIR}"
    rm -f /var/log/inri-miner.log || true
    echo -e "${GREEN}Node removed.${RESET}"
  else
    echo -e "${YELLOW}Aborted.${RESET}"
  fi
  prompt_continue
}

# -------- Menu (simple) ----------
while true; do
  clear
  echo -e "${YELLOW}========================================${RESET}"
  echo -e "${GREEN}      INRI Chain Installer - bastiar${RESET}"
  echo -e "${YELLOW}     find me: https://yarrr-node${RESET}"
  echo -e "${YELLOW}     Telegram: Airdrop Laura${RESET}"
  echo -e "${YELLOW}========================================${RESET}"
  echo
  echo "1) Install Dependencies"
  echo "2) Install Geth"
  echo "3) Download & Init Genesis"
  echo "4) Start Node (systemd)"
  echo "5) Stop Node"
  echo "6) Start Mining (screen)"
  echo "7) Stop Mining"
  echo "8) Check Node Sync Status"
  echo "9) Show Node Logs (journalctl)"
  echo "10) Show Miner Log (tail)"
  echo "11) Remove Node (wipe)"
  echo "0) Exit"
  echo
  read -p "Choose [0-11]: " opt
  case "$opt" in
    1) install_dependencies ;;
    2) install_geth ;;
    3) download_and_init_genesis && create_systemd_service ;;
    4) start_node ;;
    5) stop_node ;;
    6) start_miner_screen ;;
    7) stop_miner_screen ;;
    8) check_node_sync ;;
    9) show_logs ;;
    10) show_miner_logfile ;;
    11) remove_node ;;
    0) echo "Bye." ; exit 0 ;;
    *) echo "Invalid option" ; sleep 1 ;;
  esac
done
