#!/bin/bash

USER="server-admin"
MINECRAFT_SERVER_DATA_DIR="/home/$USER/minecraft-server"
MINECRAFT_SERVER_DATA_BACKUP_DIR="/home/$USER/minecraft-server-backups"

echo "🚀 Starting Server Bootstrap"

# 1. Update & Install Docker (Non-Interactive Mode)
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y -o Dpkg::Options::="--force-confold"
apt-get install -y -o Dpkg::Options::="--force-confold" ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y -o Dpkg::Options::="--force-confold" docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 2. Create User & Sync SSH Keys
if id "$USER" &>/dev/null; then
    echo "✔ User $USER already exists."
else
    adduser --disabled-password --gecos "" $USER
    usermod -aG sudo,docker $USER
    mkdir -p /home/$USER/.ssh
    cp /root/.ssh/authorized_keys /home/$USER/.ssh/
    chown -R $USER:$USER /home/$USER/.ssh
    chmod 700 /home/$USER/.ssh
    chmod 600 /home/$USER/.ssh/authorized_keys
fi

# 3. Setup Sudoers (Passwordless Docker for the new user)
echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/docker" > /etc/sudoers.d/90-minecraft-admin

# 4. Create Directories
mkdir -p $MINECRAFT_SERVER_DATA_DIR
mkdir -p $MINECRAFT_SERVER_DATA_BACKUP_DIR

# 5. Create Compose File
cat <<EOF > $MINECRAFT_SERVER_DATA_DIR/compose.yaml
services:
  mc:
    image: itzg/minecraft-server
    container_name: mc-server
    ports:
      - "25565:25565"
    environment:
      EULA: "TRUE"
      TYPE: "VANILLA"
      VERSION: "LATEST"
      MEMORY: "2G"
    volumes:
      - $MINECRAFT_SERVER_DATA_DIR:/data
    restart: unless-stopped
EOF

# Fix Ownership
chown -R $USER:$USER $MINECRAFT_SERVER_DATA_DIR
chown -R $USER:$USER $MINECRAFT_SERVER_DATA_BACKUP_DIR

# 6. Add Aliases and Restore Function to .bashrc
cat <<EOF >> /home/$USER/.bashrc

# --- Minecraft Management ---
alias server-start='docker compose -f $MINECRAFT_SERVER_DATA_DIR/compose.yaml up -d'
alias server-stop='docker compose -f $MINECRAFT_SERVER_DATA_DIR/compose.yaml down'
alias server-logs='docker compose -f $MINECRAFT_SERVER_DATA_DIR/compose.yaml logs -f'
alias server-backup='tar -czvf $MINECRAFT_SERVER_DATA_BACKUP_DIR/mc_backup_\$(date +%F_%H-%M).tar.gz -C $MINECRAFT_SERVER_DATA_DIR .'

# --- Restore Command ---
server-restore() {
    if [ -z "\$1" ]; then
        echo "Usage: server-restore /path/to/backup.tar.gz"
        return 1
    fi
    echo "⚠️  Starting Restore: Safety backup first..."
    server-backup
    server-stop
    echo "🧹 Clearing old data..."
    find $MINECRAFT_SERVER_DATA_DIR -mindepth 1 -delete
    echo "📂 Extracting \$1..."
    tar -xzvf "\$1" -C $MINECRAFT_SERVER_DATA_DIR
    echo "✅ Done! Run 'server-start' to go live."
}
EOF

# 7. Final Instructions
IP_ADDR=$(hostname -I | awk '{print $1}')
echo "-------------------------------------------------------"
echo "✅ BOOTSTRAP COMPLETE!"
echo "-------------------------------------------------------"
