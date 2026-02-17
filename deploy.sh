#!/bin/bash
set -e # Exit immediately if a command fails

SERVER_IP=$1
BOOTSTRAP_URL="https://raw.githubusercontent.com/SamirTheSage/minecraft-server-bootstrap/main/bootstrap.sh"
MINECRAFT_SERVER_DATA_DIR="/home/$USER/minecraft-server"

# 6. Provision via Root
echo "🛠 Running Bootstrap script as root..."
# We use native ssh here for better control over flags
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    root@"$SERVER_IP" "curl -sSL $BOOTSTRAP_URL | sudo bash"

# 7. Hand-off to server-admin
echo "-------------------------------------------------------"
echo "🎉 DEPLOYMENT COMPLETE!"
echo "-------------------------------------------------------"

ssh -t -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    server-admin@"$SERVER_IP" "cd $MINECRAFT_SERVER_DATA_DIR && docker compose up -d && docker compose logs -f"