#!/bin/bash
# Quick deployment script with comprehensive logging
# Run on server: sudo bash quick-deploy.sh

set -e

echo "=== EMDR v2025.11.01 - Quick Deploy with Debugging ==="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Step 1: Pulling latest code...${NC}"
cd /srv/emdr/EMDR
git pull

echo -e "${YELLOW}Step 2: Building frontend...${NC}"
cd /srv/emdr/EMDR/frontend
npm install
npm run build

echo -e "${YELLOW}Step 3: Copying files to production...${NC}"
sudo rm -rf /var/www/remote-emdr/frontend/dist/*
sudo cp -r dist/* /var/www/remote-emdr/frontend/dist/
sudo cp /srv/emdr/EMDR/backend/app.py /var/www/remote-emdr/backend/

echo -e "${YELLOW}Step 4: Restarting services...${NC}"
sudo systemctl restart emdr
sudo systemctl reload nginx

echo -e "${GREEN}=== Deployment Complete! ===${NC}"
echo ""
echo -e "${YELLOW}Testing Checklist:${NC}"
echo ""
echo "1. Open https://remote-emdr.nl in INCOGNITO/PRIVATE window"
echo "2. Check footer for version: v2025.11.01"
echo "3. Click 'Start Therapist Session'"
echo "4. Copy patient link and open in another tab"
echo ""
echo "=== Controller Tab (Therapist) ==="
echo "5. Open browser console (F12)"
echo "6. Should see: [CONTROLLER] Loaded with session ID: session_xxxxx"
echo "7. Change background color"
echo "8. Should see: [CONTROLLER] Sending background color: #xxxxxx"
echo "9. Should see: [CONTROLLER] Background updated: {backgroundColor: '#xxxxxx'}"
echo ""
echo "=== Patient Tab ===" 
echo "10. Open browser console (F12)"
echo "11. Should see: [PATIENT] Loaded with session ID: session_xxxxx"
echo "12. Should see: [PATIENT] Background color changed from #ffffff to #xxxxxx"
echo "13. Background should actually change color"
echo ""
echo "=== Bilateral Sound Test ==="
echo "14. In Controller, click 'Bilateral sound: OFF'"
echo "15. Controller console should show: [CONTROLLER] toggling bilateral sound to: true"
echo "16. Patient console should show: [PATIENT] Backend says ON, starting bilateral sound"
echo "17. Should hear alternating beeps in left/right ear"
echo "18. Sound should NOT freeze or stutter"
echo ""
echo "=== Backend Logs ==="
echo "19. Watch backend logs with: sudo journalctl -u emdr -f"
echo "20. Should see:"
echo "    [BACKGROUND] Session X: Setting color to #xxxxxx"
echo "    [SOUND] Session X: Setting bilateral to True"
echo ""
echo -e "${GREEN}If any test fails, check the console logs!${NC}"
echo ""
echo "Common issues:"
echo "- Session IDs don't match → Check URL has ?session=xxx in both tabs"
echo "- Background doesn't change → Check backend logs for BACKGROUND messages"
echo "- Sound freezes → Check Patient console for repeated 'Starting bilateral sound' messages"
echo ""
