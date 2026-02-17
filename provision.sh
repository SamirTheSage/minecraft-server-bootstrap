#!/bin/bash
set -e # Exit immediately if a command fails

# --- CONFIGURATION ---
DROPLET_NAME="mc-server-$(date +%s)"
REGION="nyc3"
SIZE="s-1vcpu-2gb"
IMAGE="ubuntu-24-04-x64"

# 1. Check for doctl
if ! command -v doctl &> /dev/null; then
    echo "❌ Error: 'doctl' is not installed."
    exit 1
fi

# 2. Get SSH Keys and force selection
echo "--- DigitalOcean SSH Key Selection ---"

# Fetch IDs and Names into two strings
KEYS_RAW=$(doctl compute ssh-key list --format ID,Name --no-header)
NAMES=$(echo "$KEYS_RAW" | awk '{print $2}')

PS3="Enter the number of your choice: "

# Force vertical list
COLUMNS=1
select SSH_KEY_NAME in $NAMES; do
    if [ -n "$SSH_KEY_NAME" ]; then
        # Find the ID that matches the selected Name
        SSH_KEY_ID=$(echo "$KEYS_RAW" | grep "$SSH_KEY_NAME" | awk '{print $1}')
        echo "✅ Selected: $SSH_KEY_NAME"
        break
    else
        echo "Invalid selection. Please try again."
    fi
done

unset COLUMNS

# 3. Create Droplet
echo "🚀 Creating Droplet: $DROPLET_NAME..."
doctl compute droplet create "$DROPLET_NAME" \
    --region "$REGION" \
    --size "$SIZE" \
    --image "$IMAGE" \
    --ssh-keys "$SSH_KEY_ID" \
    --wait

# 4. Get IP
IP=$(doctl compute droplet list --format Name,PublicIPv4 | grep "$DROPLET_NAME" | awk '{print $2}')
echo "✅ Droplet is LIVE at IP: $IP"

# 5. Wait for SSH to be ready
echo "⏳ Waiting for SSH service to start..."
while ! nc -z -w5 "$IP" 22; do
    printf "."
    sleep 2
done
echo -e "\nSSH is up!"

