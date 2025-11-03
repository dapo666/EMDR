#!/bin/bash
# Quick verification script for Debian deployment
# Run this after deployment to check everything is working

set -e

echo "=== EMDR Deployment Verification for Debian ==="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_service() {
    if systemctl is-active --quiet $1; then
        echo -e "${GREEN}✓${NC} $1 is running"
        return 0
    else
        echo -e "${RED}✗${NC} $1 is not running"
        return 1
    fi
}

check_port() {
    if netstat -tulpn 2>/dev/null | grep -q ":$1 "; then
        echo -e "${GREEN}✓${NC} Port $1 is listening"
        return 0
    else
        echo -e "${RED}✗${NC} Port $1 is not listening"
        return 1
    fi
}

echo -e "${YELLOW}Checking system services...${NC}"
check_service nginx
check_service emdr
check_service fail2ban
check_service ufw

echo ""
echo -e "${YELLOW}Checking ports...${NC}"
check_port 80
check_port 443
check_port 5000

echo ""
echo -e "${YELLOW}Checking SSL certificate...${NC}"
if [ -f "/etc/letsencrypt/live/remote-emdr.nl/fullchain.pem" ]; then
    echo -e "${GREEN}✓${NC} SSL certificate exists"
    openssl x509 -in /etc/letsencrypt/live/remote-emdr.nl/fullchain.pem -noout -dates | head -2
else
    echo -e "${RED}✗${NC} SSL certificate not found"
fi

echo ""
echo -e "${YELLOW}Checking Nginx configuration...${NC}"
if nginx -t 2>&1 | grep -q "successful"; then
    echo -e "${GREEN}✓${NC} Nginx configuration is valid"
else
    echo -e "${RED}✗${NC} Nginx configuration has errors"
fi

echo ""
echo -e "${YELLOW}Checking application files...${NC}"
[ -d "/var/www/remote-emdr" ] && echo -e "${GREEN}✓${NC} App directory exists" || echo -e "${RED}✗${NC} App directory missing"
[ -d "/var/www/remote-emdr/venv" ] && echo -e "${GREEN}✓${NC} Virtual environment exists" || echo -e "${RED}✗${NC} Virtual environment missing"
[ -d "/var/www/remote-emdr/frontend/dist" ] && echo -e "${GREEN}✓${NC} Frontend build exists" || echo -e "${RED}✗${NC} Frontend build missing"

echo ""
echo -e "${YELLOW}Checking Python packages...${NC}"
if /var/www/remote-emdr/venv/bin/pip list | grep -q "Flask"; then
    echo -e "${GREEN}✓${NC} Flask is installed"
else
    echo -e "${RED}✗${NC} Flask is not installed"
fi

echo ""
echo -e "${YELLOW}Checking firewall rules...${NC}"
ufw status | grep -E "80|443|22" || echo -e "${RED}✗${NC} Firewall rules may not be configured"

echo ""
echo -e "${YELLOW}Testing application response...${NC}"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/api/session-count | grep -q "200"; then
    echo -e "${GREEN}✓${NC} Application is responding"
else
    echo -e "${RED}✗${NC} Application is not responding"
fi

echo ""
echo -e "${YELLOW}Recent application logs:${NC}"
journalctl -u emdr -n 5 --no-pager

echo ""
echo -e "${YELLOW}Recent nginx errors:${NC}"
tail -5 /var/log/nginx/remote-emdr-error.log 2>/dev/null || echo "No errors found"

echo ""
echo "=== Verification Complete ==="
echo ""
echo "Useful commands:"
echo "  View app logs:     journalctl -u emdr -f"
echo "  View nginx logs:   tail -f /var/log/nginx/remote-emdr-error.log"
echo "  Restart app:       systemctl restart emdr"
echo "  Check status:      systemctl status emdr"
