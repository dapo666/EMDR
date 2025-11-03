# Session Conflict Bug Fix

## Problem
The application was experiencing strange behavior where:
- Ball movement type changed by itself
- Ball started/stopped automatically
- Bilateral sounds toggled randomly
- It seemed like old clicks from the therapist control screen were being replayed

## Root Cause
**Cookie-based session fallback** was causing multiple browser tabs/windows to share the same session state. When the backend didn't receive a session ID in the URL query parameter, it would fall back to using Flask's cookie-based session, which is shared across all tabs in the same browser.

### The Issue Flow:
1. User opens multiple tabs of the controller or patient screen
2. Some tabs don't properly pass the session ID in the URL
3. Backend falls back to cookie-based session for those tabs
4. All tabs without URL session ID now share the same cookie session
5. Changes from one tab affect all other tabs sharing the cookie
6. Result: Random state changes as different tabs poll and update the shared session

## Solution
**Two-part fix:**
1. **Removed cookie-based session fallback** and made session ID in URL query parameter **required**
2. **Removed Controller polling** - Controller should only send updates, not constantly fetch state

### Changes Made:

#### 1. `/Users/damianpogrzeba/dev/EMDR/backend/app.py`
- **Removed**: `session` import from Flask (no longer using cookies)
- **Removed**: `secrets` import (no longer generating secret keys)
- **Removed**: `app.secret_key` configuration (not needed without cookies)
- **Modified**: `get_session_id()` now returns `None` if no session ID in URL
- **Modified**: `get_session_state()` now returns 400 error if session ID is missing
- **Result**: Every request MUST include `?session=<session_id>` in the URL

#### 2. `/Users/damianpogrzeba/dev/EMDR/systemd/emdr.service`
- **Removed**: `SESSION_SECRET` environment variable (no longer needed)

#### 3. `/Users/damianpogrzeba/dev/EMDR/deploy.sh`
- **Removed**: Secret key generation code
- **Removed**: `sed` command to replace secret key in service file

#### 4. `/Users/damianpogrzeba/dev/EMDR/frontend/src/Controller.vue`
- **Removed**: 500ms polling interval in `mounted()` hook
- **Changed**: Controller now only fetches state once on load
- **Result**: Controller sends commands, Patient receives updates (one-way flow)

## Why Controller Polling Caused Issues

The Controller was polling every 500ms and overwriting its own UI state with backend data:
- User clicks a button → sends POST to backend → backend updates state
- 500ms later → Controller polls backend → fetches OLD state → overwrites UI
- Result: Buttons appear to toggle themselves, settings change randomly

**The fix**: Controller is now **write-only** (sends updates), Patient is **read-only** (receives updates).

## How It Works Now

### Session Creation Flow:
1. User clicks "Start Therapist Session" in Menu
2. Menu generates a random session ID: `Math.random().toString(36).substr(2, 9)`
3. Menu opens Controller with URL: `/controller?session=<random_id>`
4. Controller reads session ID from URL and stores it
5. Controller provides Patient link: `/patient?session=<same_id>`
6. All API calls include the session ID: `/api/ball?session=<id>`

### Session Isolation:
- Each therapist-patient pair has a unique session ID
- Sessions are completely isolated - no cross-talk between different sessions
- Multiple sessions can run simultaneously (up to 50)
- Each session maintains its own state independently

## Testing
To verify the fix works:

1. Open multiple therapist control panels (different tabs)
2. Each should have a different session ID in the URL
3. Changes in one tab should NOT affect other tabs
4. Each patient screen should only respond to its paired therapist

## Benefits
✅ Complete session isolation  
✅ No more random state changes  
✅ Predictable behavior  
✅ Simpler codebase (no cookie management)  
✅ Better security (no session cookies to hijack)  
✅ Easier debugging (session ID visible in URL)

## Deployment
```bash
# On server
cd /srv/emdr/EMDR
git pull

# Update backend
sudo cp backend/app.py /var/www/remote-emdr/backend/
sudo cp systemd/emdr.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl restart emdr

# Rebuild frontend with Controller fix
cd /var/www/remote-emdr/frontend
npm run build
sudo systemctl reload nginx
```

## Additional Changes
- Added version number to footer: **v2025.11.01** (YYYY.MM.VV format)
- Version appears on all pages: Menu, Controller, and Patient

## Additional Fixes (v2025.11.01)

### Issue: Background color not updating, sound freezing, buttons acting randomly
**Root Causes**:
1. Patient screen making 4 separate API calls every 500ms (causing race conditions)
2. Patient had 2 separate polling intervals (fetchBall + checkBilateralSound)
3. Backend `get_session_state()` could return error tuple, but endpoints didn't check for it
4. No error handling in Controller POST requests

**Solutions**:
1. ✅ Consolidated all 4 API calls into single `Promise.all()` in Patient
2. ✅ Removed separate sound polling interval - now part of unified fetch
3. ✅ Increased polling from 500ms to 1000ms (reduced server load by 50%)
4. ✅ Added `isinstance(state, tuple)` checks in all backend endpoints
5. ✅ Added `.catch()` error handlers to all Controller axios calls
6. ✅ Changed bilateral sound toggle to only update UI after successful POST

### Files Modified:
- `frontend/src/App.vue` - Unified polling, Promise.all for parallel fetches
- `backend/app.py` - Added error response checks to all endpoints
- `frontend/src/Controller.vue` - Added error handling to all POST requests

## Date Fixed
November 3, 2025
