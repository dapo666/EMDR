# URGENT DEBUGGING INSTRUCTIONS

## Background Color Fixed! ✅

**Root Cause**: CSS had `background: white !important;` which overrode the inline style
**Fix**: Removed the `!important` rule

## Bilateral Sound Toggling Issue

Your logs show the backend is receiving **conflicting commands**:
- ON/OFF/ON/OFF/ON/OFF repeatedly
- Background toggling between `#8a0a0a` and `#ffffff`

### Most Likely Causes:

#### 1. **Multiple Browser Tabs/Windows Open** ⚠️
**CLOSE ALL TABS** and start fresh:
```bash
# On your computer, close ALL browser windows
# Then open fresh:
1. Go to https://remote-emdr.nl
2. Click "Start Therapist Session" (creates session_XXX)
3. Copy the patient link
4. Open patient link in NEW tab
5. DO NOT open any other tabs
```

#### 2. **Multiple Controller Windows**
Check if you have multiple Controller tabs with **different session IDs**:
- Each Controller creates a NEW random session ID
- If you have 2 Controllers open, they write to different sessions
- But if Patient is polling the wrong session → conflict!

#### 3. **Browser Cache Issues**
Old JavaScript might be cached:
```bash
# On your computer:
1. Press Ctrl+Shift+Delete (Windows) or Cmd+Shift+Delete (Mac)
2. Clear "Cached images and files"
3. Close ALL browser tabs
4. Open in Private/Incognito window
```

## Deploy and Test

### On Server:
```bash
cd /srv/emdr/EMDR
git pull
cd frontend
npm run build
sudo rm -rf /var/www/remote-emdr/frontend/dist/*
sudo cp -r dist/* /var/www/remote-emdr/frontend/dist/
cd ..
sudo cp backend/app.py /var/www/remote-emdr/backend/
sudo systemctl restart emdr
sudo systemctl reload nginx
```

### Test Procedure:

#### 1. **Close Everything First**
- Close ALL browser tabs of remote-emdr.nl
- Close ALL browser windows

#### 2. **Open in Incognito/Private Window**
```
Chrome: Ctrl+Shift+N (Windows) or Cmd+Shift+N (Mac)
Firefox: Ctrl+Shift+P (Windows) or Cmd+Shift+P (Mac)
```

#### 3. **Single Controller, Single Patient**
```
1. Go to: https://remote-emdr.nl
2. Click "Start Therapist Session"
3. Note the session ID in URL: ?session=XXXXX
4. Copy patient link
5. Open patient link in NEW TAB (not new window)
6. Verify session ID matches: ?session=XXXXX (SAME!)
```

#### 4. **Test Background Color**
- In Controller: change background color
- In Patient: background should change within 500ms
- Check console: should see "[PATIENT] Background color changed"
- **Background should VISUALLY change now** (CSS fix)

#### 5. **Test Bilateral Sound**
- In Controller: click "Bilateral sound: OFF"
- Button should turn to "ON" (green)
- Patient should start beeping
- Should NOT toggle ON/OFF/ON/OFF
- Check console: should see ONE "Starting bilateral sound" message

### Debug Active Sessions

Visit this URL to see all active sessions:
```
https://remote-emdr.nl/api/debug/sessions
```

Should show something like:
```json
{
  "total": 1,
  "sessions": {
    "session_abc123": {
      "backgroundColor": "#8a0a0a",
      "bilateral": true,
      "isMoving": true
    }
  }
}
```

**If you see multiple sessions → that's your problem!**

### Backend Logs

Watch in real-time:
```bash
sudo journalctl -u emdr -f
```

Should see:
```
[SESSION] Creating new session: session_abc123
[SOUND POST] Session session_abc123 from IP xxx.xxx.xxx.xxx: Setting bilateral to True
[SOUND POST] Session session_abc123: Changed from False to True
[BACKGROUND] Session session_abc123: Setting color to #8a0a0a
```

**If you see different session IDs → multiple controllers/patients conflicting!**

## Success Criteria

✅ Only 1 session active in `/api/debug/sessions`
✅ Background color VISUALLY changes when you pick a color
✅ Bilateral sound starts and doesn't toggle
✅ No repeated "Starting bilateral sound" messages
✅ Session ID matches in Controller and Patient URL

## If Still Toggling

The backend logs will show WHO is sending the conflicting commands:
```
[SOUND POST] Session ABC from IP 1.2.3.4: Setting bilateral to True
[SOUND POST] Session ABC from IP 1.2.3.4: Setting bilateral to False  ← Different request!
```

This means something is sending BOTH True and False.

**Possible causes:**
1. Old tab still open somewhere
2. stopBall() in Controller sending False
3. Race condition in Patient polling

Check Controller console for ANY "stopping bilateral sound" messages when you didn't click anything!

---

**Next Steps:**
1. Deploy the fix (removes CSS `!important`)
2. Close ALL browser tabs
3. Open in Incognito window
4. Test with ONLY 1 Controller + 1 Patient
5. Check `/api/debug/sessions` shows only 1 session
