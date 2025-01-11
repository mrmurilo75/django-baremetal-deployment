#!/usr/bin/env bash
#
# setup_server.sh
#
# One-stop script to configure a new Ubuntu 22.04 server with best practices,
# minimal third-party tools, and a simple deployment method (SSH + git).
#

set -euo pipefail

# ------------------------------------------------------------------------------
# 0. USER-CONFIGURABLE VARIABLES
# ------------------------------------------------------------------------------

# Change these as you see fit.
NEW_USER="deploy"
SSH_PORT="22"   # If you want to change to a non-default port, set e.g. SSH_PORT="2222"
DOMAIN="example.com"       # Used for the sample Nginx config
DOC_ROOT="/var/www/mywebsite"

# OPTIONAL: Set your SSH PUBLIC KEY here if you want the script to auto-install it
# If left empty, the script will skip automatic copying. You can manually add it later.
SSH_PUBLIC_KEY=""

# ------------------------------------------------------------------------------
# 1. SYSTEM UPDATE & CLEANUP
# ------------------------------------------------------------------------------
echo ">>> Updating and upgrading packages..."
apt update -y
apt upgrade -y
apt autoremove -y

# ------------------------------------------------------------------------------
# 2. CREATE NON-ROOT USER WITH SUDO
# ------------------------------------------------------------------------------
# We demonstrate a non-interactive way to create a user with a default password.
# Adjust or remove if you'd prefer an interactive approach (adduser).

echo ">>> Creating user '$NEW_USER' and granting sudo privileges..."
if ! id -u "$NEW_USER" >/dev/null 2>&1; then
    # Create user with no password set up yet
    adduser --gecos "" --disabled-password "$NEW_USER"

    # Set a default password for the user (change "MySecurePassword"!)
    # or leave commented out if you prefer purely SSH-key-based logins
    echo "$NEW_USER:MySecurePassword" | chpasswd
else
    echo "User '$NEW_USER' already exists. Skipping creation..."
fi

usermod -aG sudo "$NEW_USER"

# ------------------------------------------------------------------------------
# 3. SSH CONFIGURATION & KEY SETUP
# ------------------------------------------------------------------------------
echo ">>> Hardening SSH configuration..."

# 3.1. Copy SSH key if provided
if [ -n "$SSH_PUBLIC_KEY" ]; then
    echo ">>> Adding your SSH key to /home/$NEW_USER/.ssh/authorized_keys..."
    mkdir -p /home/"$NEW_USER"/.ssh
    echo "$SSH_PUBLIC_KEY" >> /home/"$NEW_USER"/.ssh/authorized_keys
    chmod 700 /home/"$NEW_USER"/.ssh
    chmod 600 /home/"$NEW_USER"/.ssh/authorized_keys
    chown -R "$NEW_USER":"$NEW_USER" /home/"$NEW_USER"/.ssh
fi

# 3.2. Update sshd_config
SSHD_CONFIG="/etc/ssh/sshd_config"
cp "$SSHD_CONFIG" "${SSHD_CONFIG}.bak"

# Disable root login, disable password authentication (requires key-based auth), set port
sed -i "s/^#\?PermitRootLogin.*/PermitRootLogin no/g" "$SSHD_CONFIG"
sed -i "s/^#\?PasswordAuthentication.*/PasswordAuthentication no/g" "$SSHD_CONFIG"
sed -i "s/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/g" "$SSHD_CONFIG"

if [ "$SSH_PORT" != "22" ]; then
  sed -i "s/^#\?Port.*/Port $SSH_PORT/g" "$SSHD_CONFIG"
fi

systemctl restart ssh

# ------------------------------------------------------------------------------
# 4. CONFIGURE FIREWALL (UFW)
# ------------------------------------------------------------------------------
echo ">>> Setting up UFW (Uncomplicated Firewall)..."
apt install -y ufw

# Reset and configure
ufw --force reset

# Allow SSH (on custom port if set)
ufw allow "$SSH_PORT"/tcp

# Allow HTTP and HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Enable firewall
ufw --force enable

# ------------------------------------------------------------------------------
# 5. INSTALL NGINX (OR APACHE)
# ------------------------------------------------------------------------------
echo ">>> Installing Nginx..."
apt install -y nginx
systemctl enable nginx
systemctl start nginx

# ------------------------------------------------------------------------------
# 6. SET UP A BASIC SERVER BLOCK
# ------------------------------------------------------------------------------
echo ">>> Setting up Nginx server block..."
if [ ! -d "$DOC_ROOT" ]; then
  mkdir -p "$DOC_ROOT"
fi

cat <<EOF > /etc/nginx/sites-available/mywebsite.conf
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    root $DOC_ROOT;
    index index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

ln -sf /etc/nginx/sites-available/mywebsite.conf /etc/nginx/sites-enabled/mywebsite.conf
nginx -t
systemctl reload nginx

chown -R www-data:www-data "$DOC_ROOT"

# ------------------------------------------------------------------------------
# 7. (OPTIONAL) OBTAIN LET'S ENCRYPT SSL CERT
# ------------------------------------------------------------------------------
# If you want to avoid third-party tools, comment this out. If you want free SSL:
# apt install -y certbot python3-certbot-nginx
# certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN"

# ------------------------------------------------------------------------------
# 8. INSTALL RUNTIME DEPENDENCIES
# ------------------------------------------------------------------------------
echo ">>> Installing common runtimes (Node.js, Python, PHP if needed)..."
# Node.js (LTS) – comment out if not needed
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt install -y nodejs

# Python
apt install -y python3 python3-pip python3-venv

# PHP (with typical modules)
apt install -y php-fpm php-mysql php-xml php-cli

# ------------------------------------------------------------------------------
# 9. OPTIONAL: FAIL2BAN FOR EXTRA SECURITY
# ------------------------------------------------------------------------------
# echo ">>> Installing fail2ban..."
# apt install -y fail2ban
# systemctl enable fail2ban
# systemctl start fail2ban

# ------------------------------------------------------------------------------
# 10. EXAMPLE: BASIC SYSTEMD SERVICE FOR A NODE APP
# ------------------------------------------------------------------------------
# If you have a Node.js app (e.g., /var/www/mywebsite/app.js), you can set up a service:
# cat <<EOF > /etc/systemd/system/myapp.service
# [Unit]
# Description=My Node.js App
# After=network.target
#
# [Service]
# ExecStart=/usr/bin/node $DOC_ROOT/app.js
# Restart=always
# User=$NEW_USER
# Group=$NEW_USER
# Environment=NODE_ENV=production
# WorkingDirectory=$DOC_ROOT
#
# [Install]
# WantedBy=multi-user.target
# EOF
#
# systemctl daemon-reload
# systemctl enable myapp
# systemctl start myapp

# ------------------------------------------------------------------------------
# DONE
# ------------------------------------------------------------------------------
echo ">>> Setup complete!"
echo "----------------------------------------------------------------"
echo "1. You should now connect via SSH with the '$NEW_USER' user, e.g.:"
echo "   ssh -p $SSH_PORT $NEW_USER@<server-ip>"
echo "2. Make sure you've copied your SSH public key into /home/$NEW_USER/.ssh/authorized_keys"
echo "   if you didn't provide it in the script."
echo "3. Nginx is installed and serving a default page from $DOC_ROOT"
echo "----------------------------------------------------------------"


# ------------------------------------------------------------------------------
# NOTE: This script was initially generated using AI. Please, use with caution.
# ------------------------------------------------------------------------------
