# 🚀 Minecraft Server Bootstrap

A lightweight, automated script to deploy a Dockerized Minecraft server on a Linux VM. This script handles Docker installation, user security (non-root execution), and provides simple management aliases for backups and restores.

### 📋 Prerequisites
* **OS:** Ubuntu 22.04+ (Tested on **DigitalOcean 2GB Droplets**).
* **Hardware:** Minimum **2GB RAM**.
* **Permissions:** Initial run must be as the `root` user.

---

### ⚡ Installation

#### 1. Log in to your VM
```bash
ssh root@your_server_ip
```

#### 2. Run the BootstrapExecute the script directly from this repository:

```bash
curl -sSL [https://raw.githubusercontent.com/SamirTheSage/minecraft-server-bootstrap/main/bootstrap.sh](https://raw.githubusercontent.com/SamirTheSage/minecraft-server-bootstrap/main/bootstrap.sh) | sudo bash
```
#### 3. Log in as Admin & Start

Exit the root session and log in as the newly created `server-admin` user to start the world:

```bash
exit
ssh server-admin@your_server_ip
server-start
```

#### 🛠 Management Commands

Once logged in as server-admin, use these custom aliases to manage your server:

| Command | Action |
| :--- | :--- |
| `server-start` | Launches the Minecraft container in the background. |
| `server-logs` | View the live console/chat (Press `Ctrl+C` to exit logs). |
| `server-stop` | Gracefully shuts down the Minecraft server. |
| `server-backup` | Creates a timestamped `.tar.gz` in `~/minecraft-server-backups`. |
| `server-restore` | **Safety First:** Backs up current state, wipes data, and restores a specific `.tar.gz`. |
