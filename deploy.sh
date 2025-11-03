#!/bin/bash
# Deployment script for EMDR application
# Run this script as root or with sudo

set -e

echo "=== EMDR Application Deployment Script ==="
echo ""

# Configuration
APP_DIR="/var/www/remote-emdr"
DOMAIN="remote-emdr.nl"
EMAIL="info@expatpsychologie.nl"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Step 1: Installing system dependencies...${NC}"
# Store the script directory before we change directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

apt-get update
apt-get install -y python3 python3-pip python3-venv python3-dev build-essential \
    nginx certbot python3-certbot-nginx git curl wget

# Install Node.js 18.x LTS (Debian compatible)
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

echo -e "${YELLOW}Step 2: Creating application directory...${NC}"
mkdir -p $APP_DIR
mkdir -p /var/log/gunicorn
mkdir -p /var/run/gunicorn
chown -R www-data:www-data /var/log/gunicorn
chown -R www-data:www-data /var/run/gunicorn

echo -e "${YELLOW}Step 3: Copying application files...${NC}"
# Assuming you're running this from the EMDR directory
cp -r backend $APP_DIR/
cp -r frontend $APP_DIR/
cp gunicorn.conf.py $APP_DIR/
cp requirements-prod.txt $APP_DIR/requirements.txt

echo -e "${YELLOW}Step 4: Setting up Python virtual environment...${NC}"
cd $APP_DIR
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
pip install gunicorn
deactivate

echo -e "${YELLOW}Step 5: Building frontend...${NC}"
cd $APP_DIR/frontend
npm install
npm run build

echo -e "${YELLOW}Step 6: Setting up systemd service...${NC}"
# Copy systemd service file from the original script directory
cp $SCRIPT_DIR/systemd/emdr.service /etc/systemd/system/

systemctl daemon-reload
systemctl enable emdr.service
systemctl start emdr.service

echo -e "${YELLOW}Step 7: Configuring Nginx...${NC}"
# Copy nginx config from the current directory
cp $SCRIPT_DIR/nginx.conf /etc/nginx/sites-available/$DOMAIN
ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test nginx config (but don't fail yet as SSL certs aren't installed)
nginx -t || echo "Nginx config will be valid after SSL setup"

echo -e "${YELLOW}Step 8: Obtaining SSL certificate with Let's Encrypt...${NC}"
mkdir -p /var/www/certbot

# Temporarily use HTTP-only config for certificate verification
cat > /etc/nginx/sites-available/$DOMAIN.temp <<TEMPEOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN www.$DOMAIN;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        root $APP_DIR/frontend/dist;
        try_files \$uri \$uri/ /index.html;
    }
}
TEMPEOF

ln -sf /etc/nginx/sites-available/$DOMAIN.temp /etc/nginx/sites-enabled/$DOMAIN
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl start nginx || systemctl reload nginx

# Obtain certificate
certbot certonly --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email $EMAIL

# Now install the full SSL config
rm -f /etc/nginx/sites-enabled/$DOMAIN
cp $SCRIPT_DIR/nginx.conf /etc/nginx/sites-available/$DOMAIN
ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/

echo -e "${YELLOW}Step 9: Setting up auto-renewal for SSL certificate...${NC}"
systemctl enable certbot.timer
systemctl start certbot.timer

echo -e "${YELLOW}Step 10: Final nginx restart...${NC}"
systemctl restart nginx

echo -e "${YELLOW}Step 11: Setting proper permissions...${NC}"
chown -R www-data:www-data $APP_DIR
chmod -R 755 $APP_DIR

echo -e "${GREEN}=== Deployment Complete! ===${NC}"
echo ""
echo -e "${GREEN}Your EMDR application is now running at:${NC}"
echo -e "${GREEN}https://$DOMAIN${NC}"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo "  Check app status:     systemctl status emdr"
echo "  View app logs:        journalctl -u emdr -f"
echo "  View nginx logs:      tail -f /var/log/nginx/remote-emdr-error.log"
echo "  Restart app:          systemctl restart emdr"
echo "  Restart nginx:        systemctl restart nginx"
echo ""
echo -e "${YELLOW}Security features enabled:${NC}"
echo "  ✓ SSL/TLS encryption (Let's Encrypt)"
echo "  ✓ HTTP to HTTPS redirect"
echo "  ✓ Rate limiting (DDoS protection)"
echo "  ✓ Connection limits"
echo "  ✓ Security headers (HSTS, X-Frame-Options, etc.)"
echo "  ✓ Auto-restart on failure (systemd)"
echo ""
