# INRI Chain Installer v2.0 (Simplified)

**Created by Bastiar – [yarrr-node.com](https://yarrr-node.com)**  
Telegram Channel: **https://t.me/AirdropLaura**

---

## 📌 Description

INRI Installer v2.0 is an all-in-one bash script for:

- Installing **Geth 1.10.26** with **Full PoW support**
- Initializing the **INRI Chain** blockchain
- Automatically configuring the miner with your wallet address
- Setting up firewall & network
- Easily starting/stopping/restarting the miner
- Viewing live logs
- Removing all data and services with a single command

This version is **simplified**; the "Check Mining Status" and "Check Balance" menus have been removed to avoid `too many arguments` errors.

---

## ⚡ Features

- Quick Setup (Fresh Install)
- Automatic Miner Service
- Live logs monitoring
- Restart / Stop Miner
- Remove All (Data, Service, Genesis)
- Firewall and port 30303 TCP/UDP automatically configured

---

## 🛠 Installation
1. just copy paste in your terminal
```
bash <(curl -s https://raw.githubusercontent.com/AirdropLaura/inri-installer/main/installer.sh)
```


2. Follow the menu:



1) Quick Setup (Fr1.esh Install)
2) View Live Logs
3) Restart Miner
4) Stop Miner
5) Remove All
0) Exit

3.. Enter your wallet address during Quick Setup. Example:
0xf94D99A5faCc1094B5254363F4A20b6BE05D439F


4. Wait for DAG generation (5–10 minutes) before mining becomes active.




---

🔌 Menu Description

Menu	Function

1	Quick Setup – Install node, initialize blockchain, setup miner
2	View Live Logs – Run journalctl -fu inri-miner
3	Restart Miner – Restart the miner service
4	Stop Miner – Stop and disable the miner service
5	Remove All – Delete service, blockchain, and genesis file
0	Exit – Exit the installer



---

💻 Minimum Node Requirements

Component	Minimum

CPU	2 cores (1 core for mining)
RAM	4 GB
Storage	100 GB SSD
Network	10 Mbps
OS	Ubuntu 20.04 / Debian 11


> Mining on minimum specs will be slow, suitable for testing / development nodes.




---

🚀 Recommended Node Requirements

Component	Recommended

CPU	4–8 cores (more cores = higher hashrate)
RAM	8–16 GB
Storage	250–500 GB SSD NVMe
Network	50+ Mbps
OS	Ubuntu 20.04 / Debian 11


> Mining will be more stable, DAG generation faster, and synchronization quicker.




---

⚠️ Tips

Use an SSD to avoid I/O bottlenecks

Do not allocate all cores to mining; leave 1–2 cores for the OS

Ensure port 30303 TCP/UDP is open so the node can connect to peers

For RAM < 8 GB, use 4–8 GB swap to prevent crashes during DAG generation

For monitoring, run journalctl -fu inri-miner or check systemctl status inri-miner



---

📌 Disclaimer

This script is made for the INRI Chain network only. Not for Ethereum mainnet or other networks.
Use at your own risk. The author is not responsible for any losses due to hardware configuration or mining.


---

📞 Contact

Website: yarrr-node.com

Telegram Channel: Airdrop Laura


---
