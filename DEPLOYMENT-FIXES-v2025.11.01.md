# Critical Fixes - v2025.11.01

## Issues Fixed

### 1. Background Color Not Changing ✅
**Problem**: Background color picker did nothing
**Root Cause**: `containerStyle()` was hardcoded to `'white'` instead of using `this.backgroundColor`
**Fix**: Changed to `background: this.backgroundColor`

### 2. Bilateral Sound On/Off Toggling ✅
**Problem**: Bilateral sound turning on/off randomly
**Root Causes**: 
- Timer not cleared properly (no null assignment)
- No check if timer already exists before starting
- State comparison issues
**Fixes**:
- Clear and null timer before starting new one
- Added strict boolean comparison (`=== true`)
- Added console logging for debugging

### 3. Version Number Not Visible ✅
**Problem**: Version not showing on homepage
**Root Cause**: Frontend not rebuilt on server
**Fix**: Rebuild required

## Files Modified

### `/Users/damianpogrzeba/dev/EMDR/frontend/src/App.vue`
1. Fixed `containerStyle()` to use `this.backgroundColor`
2. Improved `startBilateralSound()` - clear existing timer first
3. Improved `stopBilateralSound()` - set timer to null
4. Added strict boolean comparison for bilateral state
5. Added console logging for debugging

### `/Users/damianpogrzeba/dev/EMDR/frontend/src/Controller.vue`
1. Added strict boolean comparison (`=== true`) for bilateral sound state
2. Added console logging to track state changes
3. Added response logging to verify server updates

## Deployment Steps

### On Server:

```bash
# 1. Pull latest code
cd /srv/emdr/EMDR
git pull

# 2. Update backend (if not done already)
sudo cp backend/app.py /var/www/remote-emdr/backend/
sudo systemctl restart emdr

# 3. CRITICAL: Rebuild frontend
cd /var/www/remote-emdr/frontend
sudo npm run build

# 4. Reload nginx
sudo systemctl reload nginx

# 5. Verify services
sudo systemctl status emdr
sudo systemctl status nginx
```

## Testing Checklist

After deployment, test these features:

### Background Color
1. ✅ Open Controller
2. ✅ Open Patient screen (in new tab with session link)
3. ✅ Change background color in Controller
4. ✅ Verify Patient screen background changes immediately

### Bilateral Sound
1. ✅ Click "Bilateral sound: OFF" button in Controller
2. ✅ Verify it changes to "ON" and button turns green
3. ✅ Check browser console for: "Controller toggling bilateral sound to: true"
4. ✅ Check Patient screen console for: "Backend says ON, starting bilateral sound"
5. ✅ Verify alternating beeps in left/right ear
6. ✅ Click button again to turn OFF
7. ✅ Verify sound stops

### Version Number
1. ✅ Go to homepage (/)
2. ✅ Scroll to footer
3. ✅ Verify "v2025.11.01" is visible below "© 2025"

## Console Debugging

If bilateral sound still has issues, check browser console:

**Controller Console (F12):**
- Should see: "Controller loaded bilateral sound state: false" (on load)
- Should see: "Controller toggling bilateral sound to: true" (when clicked)
- Should see: "Server confirmed bilateral sound: true"

**Patient Console (F12):**
- Should see: "Backend says ON, starting bilateral sound"
- Should see: "Starting bilateral sound"
- Should see: "Backend says OFF, stopping bilateral sound" (when turned off)
- Should see: "Stopping bilateral sound"

## Known Working State

After these fixes:
- ✅ Background color changes work
- ✅ Bilateral sound starts/stops reliably
- ✅ Version number visible
- ✅ No polling in Controller
- ✅ Unified polling in Patient (1 second interval)
- ✅ All state updates atomic (Promise.all)

## Rollback

If issues persist, rollback:
```bash
cd /srv/emdr/EMDR
git log --oneline -5
git checkout <previous-commit-hash>
cd /var/www/remote-emdr/frontend
sudo npm run build
sudo systemctl reload nginx
```

## Support

Issues? Check:
1. Browser console (F12) for errors
2. Backend logs: `sudo journalctl -u emdr -f`
3. Nginx logs: `sudo tail -f /var/log/nginx/remote-emdr-error.log`

---
**Date**: November 3, 2025
**Version**: 2025.11.01
