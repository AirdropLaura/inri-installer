
# INRI Chain — Installer & Mining Hub  
Public RPC • Mining • Full Node • Auto Installer  
created by **bastiar**  
Website: https://yarrr-node.com  
Telegram: **https://t.me/AirdropLaura**

---

## 🔥 Quick Install (One Command)

Run this command on your VPS / Linux server:

```bash
bash <(curl -sL https://raw.githubusercontent.com/AirdropLaura/inri-installer/main/installer.sh)
```
This will launch the interactive installer menu:

1) Quick Install INRI Node
2) Uninstall Node
3) Check Logs
4) Restart Node
5) Stop Node
0) Exit


---

🚀 Installer Features

✅ 1. Quick Install (Fully Automated)

The installer will automatically:

Install geth v1.10.26

Download genesis.json

Initialize the INRI chain data directory

Configure mining:

4 miner threads

1 official INRI bootnode


Create & enable systemd service: inri-geth

Auto-start node on reboot


Only one input required:

Wallet Address (0x...) — used as miner.etherbase



---

✅ 2. Uninstall Node

This option will:

Stop and disable the inri-geth systemd service

Remove the systemd service file

Optionally delete:

~/inri/ data directory

genesis.json




---

✅ 3. Check Logs

Live node monitoring:
```
journalctl -fu inri-geth
```

---

✅ 4. Restart Node
```
systemctl restart inri-geth
```

---

✅ 5. Stop Node
```
systemctl stop inri-geth
```

---

🌐 INRI Chain Network Information

Parameter	Value

Chain ID	3777
Currency	INRI
RPC	https://rpc.inri.life
Explorer	https://explorer.inri.life
EVM Compatible	Yes
CORS Enabled	Yes


Bootnode

enode://5c7c744a9ac53fdb9e529743208ebd123f11c73d973aa2cf653f3ac1bdf460b6f2a9b2aec23b8f2b9d692d8c898fe0e93dac8d7533db8926924e770969f3a46a@134.199.203.8:30303


---

📂 Node Directory Structure

~/inri/
   ├── geth/
   ├── keystore/
   └── genesis.json


---

🧪 Tested & Verified On

Operating System	Status

Ubuntu 20.04	✔️
Ubuntu 22.04	✔️
Debian 11	✔️
KVM / Cloud VPS	✔️



---

🛠 Requirements

The installer automatically installs everything needed:

curl

systemd

geth v1.10.26 (downloaded directly)



---

✨ Credits

> Script created by bastiar
Website: https://yarrr-node.com
Telegram: @AirdropLaura



Feel free to contact me if you need support or feature enhancements.


---

⭐ Support the Project

If this project helps you, please consider giving the repository a ⭐ Star on GitHub!

.
