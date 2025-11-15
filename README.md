
# INRI Chain Installer v2.0 (Simplified)

**Created by Bastiar – [yarrr-node.com](https://yarrr-node.com)**  
Telegram Channel: **Airdrop Laura**

---

## 📌 Deskripsi

INRI Installer v2.0 adalah script bash all-in-one untuk:

- Install **Geth 1.10.26** dengan support **Full PoW**
- Inisialisasi blockchain **INRI Chain**
- Konfigurasi miner otomatis dengan wallet address
- Setup firewall & network
- Memudahkan start/stop/restart miner
- Melihat live logs
- Hapus semua data dan service dengan satu perintah

Versi ini **disederhanakan**, menu "Check Mining Status" dan "Check Balance" dihapus untuk menghindari error `too many arguments`.

---

## ⚡ Fitur

- Quick Setup (Fresh Install)
- Miner Service otomatis
- Live logs monitoring
- Restart / Stop Miner
- Remove All (Data, Service, Genesis)
- Firewall dan port 30303 TCP/UDP otomatis dikonfigurasi

---

## 🛠 Cara Install

1. Download script:

```bash
wget -O inri_installer.sh https://yourdomain.com/inri_installer.sh
chmod +x inri_installer.sh
```
2. Jalankan:



```
 ./inri_installer.sh
```
3. Ikuti menu:



1) Quick Setup (Fresh Install)
2) View Live Logs
3) Restart Miner
4) Stop Miner
5) Remove All
0) Exit

4. Masukkan wallet address saat Quick Setup. Contoh:
0xf94D99A5faCc1094B5254363F4A20b6BE05D439F


5. Tunggu DAG generation (5–10 menit) sebelum mining aktif.




---

🔌 Menu Penjelasan

Menu	Fungsi

1	Quick Setup – Install node, init blockchain, setup miner
2	View Live Logs – Jalankan journalctl -fu inri-miner
3	Restart Miner – Restart service miner
4	Stop Miner – Stop service miner & disable
5	Remove All – Hapus service, blockchain, genesis file
0	Exit – Keluar dari installer



---

💻 Minimum Spek Node

Komponen	Minimum

CPU	2 core (1 core untuk mining)
RAM	4 GB
Storage	100 GB SSD
Network	10 Mbps
OS	Ubuntu 20.04 / Debian 11


> Mining aktif di spek minimum akan lambat, cocok untuk testing / dev node.




---

🚀 Rekomendasi Spek Node

Komponen	Rekomendasi

CPU	4–8 core (lebih banyak = lebih tinggi hashrate)
RAM	8–16 GB
Storage	250–500 GB SSD NVMe
Network	50+ Mbps
OS	Ubuntu 20.04 / Debian 11


> Mining lebih stabil, DAG generation cepat, sinkronisasi lebih cepat.




---

⚠️ Tips

Gunakan SSD untuk menghindari bottleneck I/O

Jangan gunakan semua core untuk miner, sisakan 1–2 core untuk OS

Pastikan port 30303 TCP/UDP terbuka agar node bisa connect ke peers

Untuk RAM < 8GB, gunakan swap 4–8 GB untuk menghindari crash saat DAG generation

Untuk monitoring, jalankan journalctl -fu inri-miner atau cek systemctl status inri-miner



---

📌 Disclaimer

Script ini dibuat untuk jaringan INRI Chain. Tidak untuk Ethereum mainnet atau jaringan lain.
Gunakan dengan risiko sendiri, penulis tidak bertanggung jawab atas kerugian akibat konfigurasi hardware atau mining.


---

📞 Kontak

Website: https://yarrr-node.com

Telegram Channel: https://t.me/AirdropLaura


---
