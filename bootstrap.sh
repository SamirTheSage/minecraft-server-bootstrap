#!/bin/bash

USER="server-admin"
MC_DIR="/home/$USER/mc-server"

echo "🚀 Starting Server Bootstrap"

# Update & Install Docker
apt-get update && apt-get upgrade -y
apt-get install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Create User & Sync SSH Keys
adduser --disabled-password --gecos "" $USER
usermod -aG sudo,docker $USER
mkdir -p /home/$USER/.ssh
cp /root/.ssh/authorized_keys /home/$USER/.ssh/
chown -R $USER:$USER /home/$USER/.ssh
chmod 700 /home/$USER/.ssh
chmod 600 /home/$USER/.ssh/authorized_keys

# Setup Sudoers (Passwordless Docker for the new user)
echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/docker" > /etc/sudoers.d/90-minecraft-admin

# Create Server Directory and Compose File
mkdir -p $MC_DIR
cat <<EOF > $MC_DIR/compose.yaml
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
      - $MC_DIR:/data
    restart: unless-stopped
EOF
chown -R $USER:$USER $MC_DIR

# Add Aliases to the user's .bashrc
cat <<EOF >> /home/$USER/.bashrc

# Minecraft Aliases
alias server-start='docker compose -f $MC_DIR/compose.yaml up -d'
alias server-stop='docker compose -f $MC_DIR/compose.yaml down'
alias server-logs='docker compose -f $MC_DIR/compose.yaml logs -f'
EOF

# 6. Final Instructions
echo "-------------------------------------------------------"
echo "✅ BOOTSTRAP COMPLETE!"
echo "-------------------------------------------------------"
echo "1. Log out of root: 'exit'"
echo "2. Log in as your new user: 'ssh $USER@$(hostname -I | awk '{print $1}')'"
echo "3. Start your Minecraft server with: 'server-start'"
echo "4. Check progress with: 'server-logs'"
echo "5. Start your Minecraft server with: 'server-stop'"
echo "-------------------------------------------------------"
