# EMDR Application - Production Deployment Guide

## Prerequisites

- **Debian 11/12 or Ubuntu 20.04+** (tested and optimized for Debian)
- Root or sudo access
- Domain name pointing to your server IP (remote-emdr.nl)
- **Minimum:** 2GB RAM, 2 CPU cores, 20GB storage
- **Recommended:** 4GB RAM, 2 CPU cores, 80GB storage (Strato VPS Linux L)

## Quick Deployment

### 1. Prepare the server

```bash
# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Clone or upload your application to the server
cd /tmp
git clone <your-repo-url> EMDR
# OR upload files via scp/sftp
```

### 2. Run deployment script

```bash
cd /tmp/EMDR
chmod +x deploy.sh
sudo ./deploy.sh
```

The script will:
- Install all dependencies (Python, Node.js, Nginx, Certbot, etc.)
- Set up firewall (UFW)
- Configure Fail2Ban for intrusion prevention
- Create Python virtual environment
- Build frontend
- Install and configure systemd service
- Configure Nginx with SSL
- Obtain Let's Encrypt SSL certificate
- Set up automatic certificate renewal

### 3. Verify deployment

```bash
# Run verification script
cd /tmp/EMDR
chmod +x verify-deployment.sh
sudo ./verify-deployment.sh

# Or check manually:
sudo systemctl status emdr
sudo systemctl status nginx
curl https://remote-emdr.nl
```

## Manual Deployment (Alternative)

If you prefer manual deployment or need to customize:

### 1. Install Dependencies

```bash
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv python3-dev build-essential \
    nginx certbot python3-certbot-nginx git ufw fail2ban curl wget

# Install Node.js 18.x LTS
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo bash -
sudo apt-get install -y nodejs
```

### 2. Setup Application

```bash
# Create directory
sudo mkdir -p /var/www/remote-emdr
sudo chown -R $USER:$USER /var/www/remote-emdr

# Copy files
cp -r backend frontend gunicorn.conf.py requirements.txt /var/www/remote-emdr/

# Setup Python environment
cd /var/www/remote-emdr
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
pip install gunicorn
deactivate

# Build frontend
cd frontend
npm install
npm run build
cd ..
```

### 3. Configure Systemd

```bash
# Copy service file
sudo cp systemd/emdr.service /etc/systemd/system/

# Generate secret key and update service file
python3 -c 'import secrets; print(secrets.token_hex(32))'
# Copy the output and edit the service file:
sudo nano /etc/systemd/system/emdr.service
# Replace CHANGE_THIS_TO_RANDOM_SECRET_KEY with your generated key

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable emdr
sudo systemctl start emdr
```

### 4. Configure Nginx

```bash
# Copy nginx config
sudo cp nginx.conf /etc/nginx/sites-available/remote-emdr.nl
sudo ln -s /etc/nginx/sites-available/remote-emdr.nl /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t

# Restart nginx
sudo systemctl restart nginx
```

### 5. Setup SSL

```bash
sudo certbot --nginx -d remote-emdr.nl -d www.remote-emdr.nl
```

### 6. Configure Firewall

```bash
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw enable
```

## Security Features

### DDoS Protection
- **Rate Limiting**: 10 req/s for API, 30 req/s for general traffic
- **Connection Limits**: Max 10 concurrent connections per IP
- **Fail2Ban**: Automatic IP blocking for suspicious activity
- **Firewall**: UFW configured to allow only necessary ports

### SSL/TLS
- **Let's Encrypt** certificates
- **TLS 1.2 and 1.3** only
- **HSTS** enabled (HTTP Strict Transport Security)
- **Auto-renewal** configured

### Security Headers
- X-Frame-Options: SAMEORIGIN
- X-Content-Type-Options: nosniff
- X-XSS-Protection: 1; mode=block
- Referrer-Policy: strict-origin-when-cross-origin

### Application Security
- Session secret from environment variable
- No PHP/WordPress endpoints
- Hidden files blocked
- Gunicorn running as www-data user

## Monitoring & Maintenance

### Check Application Status
```bash
sudo systemctl status emdr
sudo journalctl -u emdr -f  # Follow logs
```

### Check Nginx Logs
```bash
sudo tail -f /var/log/nginx/remote-emdr-access.log
sudo tail -f /var/log/nginx/remote-emdr-error.log
```

### Check Fail2Ban
```bash
sudo fail2ban-client status
sudo fail2ban-client status nginx-limit-req
```

### Update Application
```bash
cd /var/www/remote-emdr

# Update backend
git pull  # or upload new files
sudo systemctl restart emdr

# Update frontend
cd frontend
npm run build
cd ..

# Update nginx config if changed
sudo cp /path/to/new/nginx.conf /etc/nginx/sites-available/remote-emdr.nl
sudo nginx -t && sudo systemctl reload nginx
```

### SSL Certificate Renewal
Automatic renewal is configured, but you can test it:
```bash
sudo certbot renew --dry-run
```

### Backup
Important files to backup:
- `/var/www/remote-emdr/` - Application files
- `/etc/nginx/sites-available/remote-emdr.nl` - Nginx config
- `/etc/systemd/system/emdr.service` - Systemd service
- `/etc/letsencrypt/` - SSL certificates

## Troubleshooting

### App won't start
```bash
# Check logs
sudo journalctl -u emdr -n 50

# Check if port 5000 is available
sudo netstat -tulpn | grep 5000

# Test Flask app manually
cd /var/www/remote-emdr/backend
source ../venv/bin/activate
python app.py
```

### Nginx errors
```bash
# Test configuration
sudo nginx -t

# Check logs
sudo tail -f /var/log/nginx/error.log
```

### SSL certificate issues
```bash
# Renew manually
sudo certbot renew --force-renewal
```

### High traffic/DDoS
```bash
# Check current connections
sudo netstat -an | grep :443 | wc -l

# Check Fail2Ban
sudo fail2ban-client status

# Temporarily block IP
sudo ufw deny from <IP_ADDRESS>
```

## Performance Tuning

For high traffic, consider:

1. **Increase worker processes** in `gunicorn.conf.py`
2. **Add Redis** for session storage
3. **Use CDN** for static files
4. **Database** for session persistence (currently in-memory)
5. **Load balancer** for multiple servers
6. **Monitoring** tools (Prometheus, Grafana, Sentry)

## Support

For issues or questions:
- Email: info@expatpsychologie.nl
- Website: https://expatpsychologie.nl/en/

## License

© 2025 DRP CONSULTING - KVK: 85650595
