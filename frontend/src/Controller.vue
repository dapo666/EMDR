

<template>
  <div class="controller-bg">
    <div class="controller-card">
      <h1><span class="icon">🩺</span> Therapist Controls</h1>
      <div class="app-info">
        <span class="icon">🆓</span>
        Free version of the app tested in Google Chrome
      </div>
      <div class="instructions">
        <span class="icon">💡</span>
        <span>Please share the patient screen with the patient for the session.</span>
      </div>
      <div class="patient-link">
        <span class="icon">🔗</span>
        Patient link: <a :href="patientUrl" target="_blank">{{ patientUrl }}</a>
          <button class="copy-btn" @click="copyPatientUrl"><span class="icon">📋</span> Copy</button>
      </div>
      <div v-if="sessionLimitError" class="session-limit-notification">
        <span class="icon">🚫</span>
        <strong>Max session limit reached for free version.</strong><br>
        To allow new connection please subscribe to paid version.<br>
        <span class="icon">✉️</span> Contact: <a href="mailto:info@expatpsychologie.nl">info@expatpsychologie.nl</a>
      </div>
      <div v-else>
        <div class="preview-title"><span class="icon">👁️</span> Patient Preview</div>
        <div class="preview-container">
          <div class="preview-bg" :style="previewContainerStyle">
            <div class="preview-ball" :style="previewBallStyle"></div>
          </div>
        </div>
      </div>
      <div class="controller-buttons">
        <button class="start-btn" @click="startBall"><span class="icon">▶️</span> Start</button>
        <button class="stop-btn" @click="stopBall"><span class="icon">⏹️</span> Stop</button>
      </div>
      <div class="sound-controls" style="margin-bottom:32px;display:flex;flex-direction:column;align-items:center;gap:12px;">
        <h2 style="font-size:1.1em;color:#2196f3;margin-bottom:10px;"><span class="icon">🔊</span>Bilateral Sound Controls</h2>
        <div v-if="bilateralSoundActive" class="sound-status-active">
          <span class="icon">✅</span> Sound is ACTIVE on patient side
        </div>
        <div v-else class="sound-status-inactive">
          <span class="icon">❌</span> Sound is OFF
        </div>
        <button class="start-btn" @click="startBilateralSound"><span class="icon">🔊</span> Start Bilateral Sound</button>
        <button class="stop-btn" @click="stopBilateralSound"><span class="icon">🔇</span> Stop Bilateral Sound</button>
      </div>
  <div class="controls">
        <label><span class="icon">⚡</span> Speed:<br>
          <input type="range" min="1" max="40" v-model="speed" @input="updateBall" />
        </label>
        <div class="speed-presets">
          <span class="icon">🚦</span> Presets:
          <button class="preset-btn" @click="setPresetSpeed(45)">BLS Slow<br><small>45 movements/min</small></button>
          <button class="preset-btn" @click="setPresetSpeed(75)">BLS Medium<br><small>75 movements/min</small></button>
          <button class="preset-btn" @click="setPresetSpeed(120)">BLS Fast<br><small>120 movements/min</small></button>
        </div>
        <label><span class="icon">🔀</span> Bounce Mode:<br>
          <select v-model="bounceMode" @change="updateBall">
            <option value="horizontal">Left-Right</option>
            <option value="vertical">Up-Down</option>
            <option value="random">Random</option>
          </select>
        </label>
        <label><span class="icon">🎨</span> Background Color:<br>
          <input type="color" v-model="backgroundColor" @input="updateBackground" />
        </label>
        <label><span class="icon">⚪</span> Ball Color:<br>
          <input type="color" v-model="ballColor" @input="updateBallColor" />
        </label>
        <label style="margin-left: 24px"><span class="icon">🔵</span> Ball Size:<br>
          <input type="range" min="10" max="80" v-model="ballSize" @input="updateBallSize" />
        </label>
      </div>
    </div>
  </div>
</template>

<script>

import axios from 'axios';

export default {
  data() {
    return {
  speed: 5,
  sessionLimitError: false,
      bounceMode: 'horizontal',
      backgroundColor: '#888',
      ballColor: '#2196f3',
      isMoving: false,
      sessionId: '',
      previewX: 0,
      previewY: 0,
      previewDirectionX: 1,
      previewDirectionY: 1,
  previewBallSize: 30,
  ballSize: 30,
      previewInterval: null,
      bilateralSoundActive: false
    };
      },
      computed: {
        patientUrl() {
          return `/patient?session=${this.sessionId}`;
        },
        previewBallStyle() {
          return {
            left: this.previewX + 'px',
            top: this.previewY + 'px',
            background: this.ballColor,
            width: this.ballSize + 'px',
            height: this.ballSize + 'px',
            borderRadius: '50%',
            position: 'absolute',
          };
        },
        previewContainerStyle() {
          return {
            background: this.backgroundColor,
            width: '320px', // 16:9 aspect ratio (width)
            height: '180px', // 16:9 aspect ratio (height)
            position: 'relative',
            borderRadius: '16px',
            overflow: 'hidden',
            margin: '0 auto'
          };
        }
      },
      methods: {
        startBilateralSound() {
          const sessionParam = this.sessionId ? `?session=${this.sessionId}` : '';
          axios.post(`/api/sound${sessionParam}`, { bilateral: true, speed: 500 });
        },
        stopBilateralSound() {
          const sessionParam = this.sessionId ? `?session=${this.sessionId}` : '';
          axios.post(`/api/sound${sessionParam}`, { bilateral: false, speed: 500 });
        },
        setPresetSpeed(movementsPerMin) {
          if (movementsPerMin === 45) this.speed = 8;
          else if (movementsPerMin === 75) this.speed = 14;
          else if (movementsPerMin === 120) this.speed = 24;
          this.updateBall();
        },
        updateBallSize() {
          this.previewBallSize = this.ballSize;
          const sessionParam = this.sessionId ? `?session=${this.sessionId}` : '';
          axios.post(`/api/ball${sessionParam}`, { speed: this.speed, bounceMode: this.bounceMode, isMoving: this.isMoving, ballSize: this.ballSize });
        },
        getSessionIdFromUrl() {
          const params = new URLSearchParams(window.location.search);
          let sessionId = params.get('session');
          if (!sessionId) {
            // Create a new session ID for the therapist
            sessionId = 'session_' + Math.random().toString(36).substr(2, 9);
            // Update URL without reloading
            const newUrl = `${window.location.pathname}?session=${sessionId}`;
            window.history.replaceState({}, '', newUrl);
          }
          this.sessionId = sessionId;
        },
          copyPatientUrl() {
            navigator.clipboard.writeText(window.location.origin + this.patientUrl);
            this.$emit('show-toast', 'Patient link copied!');
          },
        movePreviewBall() {
          const width = 320; // therapist preview width (matches previewContainerStyle)
          const height = 180; // therapist preview height (matches previewContainerStyle)
          const minX = 0;
          const minY = 0;
          const maxX = width - this.previewBallSize;
          const maxY = height - this.previewBallSize;
          if (this.bounceMode === 'horizontal') {
            this.previewY = Math.floor(height / 2 - this.previewBallSize / 2);
            this.previewX += this.speed * this.previewDirectionX;
            if (this.previewX > maxX) {
              this.previewX = maxX;
              this.previewDirectionX = -1;
            } else if (this.previewX < minX) {
              this.previewX = minX;
              this.previewDirectionX = 1;
            }
          } else if (this.bounceMode === 'vertical') {
            this.previewX = Math.floor(width / 2 - this.previewBallSize / 2);
            this.previewY += this.speed * this.previewDirectionY;
            if (this.previewY > maxY) {
              this.previewY = maxY;
              this.previewDirectionY = -1;
            } else if (this.previewY < minY) {
              this.previewY = minY;
              this.previewDirectionY = 1;
            }
          } else if (this.bounceMode === 'diagonal') {
            this.previewX += this.speed * this.previewDirectionX;
            this.previewY += this.speed * this.previewDirectionY;
            if (this.previewX >= maxX) {
              this.previewX = maxX;
              this.previewDirectionX = -1;
            } else if (this.previewX <= minX) {
              this.previewX = minX;
              this.previewDirectionX = 1;
            }
            if (this.previewY >= maxY) {
              this.previewY = maxY;
              this.previewDirectionY = -1;
            } else if (this.previewY <= minY) {
              this.previewY = minY;
              this.previewDirectionY = 1;
            }
          } else if (this.bounceMode === 'random') {
            this.previewX += this.speed * this.previewDirectionX;
            this.previewY += this.speed * this.previewDirectionY;
            if (this.previewX >= maxX || this.previewX <= minX) {
              this.previewDirectionX = Math.random() > 0.5 ? 1 : -1;
            }
            if (this.previewY >= maxY || this.previewY <= minY) {
              this.previewDirectionY = Math.random() > 0.5 ? 1 : -1;
            }
            this.previewX = Math.max(minX, Math.min(maxX, this.previewX));
            this.previewY = Math.max(minY, Math.min(maxY, this.previewY));
          }
        },
        stopBall() {
          this.isMoving = false;
          const sessionParam = this.sessionId ? `?session=${this.sessionId}` : '';
          axios.post(`/api/ball${sessionParam}`, { speed: this.speed, bounceMode: this.bounceMode, isMoving: false, ballSize: this.ballSize });
          // Also stop bilateral sound when stopping ball movement
          this.stopBilateralSound();
        },
        startBall() {
          this.isMoving = true;
          const sessionParam = this.sessionId ? `?session=${this.sessionId}` : '';
          axios.post(`/api/ball${sessionParam}`, { speed: this.speed, bounceMode: this.bounceMode, isMoving: true, ballSize: this.ballSize });
        },
        updateBall() {
          const sessionParam = this.sessionId ? `?session=${this.sessionId}` : '';
          axios.post(`/api/ball${sessionParam}`, { speed: this.speed, bounceMode: this.bounceMode, isMoving: this.isMoving, ballSize: this.ballSize });
        },
        updateBackground() {
          const sessionParam = this.sessionId ? `?session=${this.sessionId}` : '';
          axios.post(`/api/background${sessionParam}`, { backgroundColor: this.backgroundColor });
        },
        updateBallColor() {
          const sessionParam = this.sessionId ? `?session=${this.sessionId}` : '';
          axios.post(`/api/ballcolor${sessionParam}`, { ballColor: this.ballColor });
        },
        fetchBall() {
          const sessionParam = this.sessionId ? `?session=${this.sessionId}` : '';
          axios.get(`/api/ball${sessionParam}`).then(res => {
            if (res.data.error && res.data.message) {
              this.sessionLimitError = true;
              return;
            }
            this.sessionLimitError = false;
            this.speed = res.data.speed;
            this.bounceMode = res.data.bounceMode || 'horizontal';
            this.isMoving = res.data.isMoving || false;
            if (res.data.ballSize !== undefined) {
              this.ballSize = res.data.ballSize;
              this.previewBallSize = res.data.ballSize;
            }
          });
          axios.get(`/api/background${sessionParam}`).then(res => {
            this.backgroundColor = res.data.backgroundColor || '#888';
          });
          axios.get(`/api/ballcolor${sessionParam}`).then(res => {
            this.ballColor = res.data.ballColor || '#2196f3';
          });
          axios.get(`/api/sound${sessionParam}`).then(res => {
            this.bilateralSoundActive = res.data.bilateral || false;
          });
        },
        handlePreviewResize() {
          // Re-center preview ball if window size changes
          if (this.bounceMode === 'horizontal') {
            this.previewY = Math.floor(200 / 2 - this.previewBallSize / 2);
          } else if (this.bounceMode === 'vertical') {
            this.previewX = Math.floor(340 / 2 - this.previewBallSize / 2);
          }
        }
      },
      mounted() {
        this.getSessionIdFromUrl();
        this.fetchBall();
        this.previewX = 0;
        this.previewY = 0;
        this.previewDirectionX = 1;
        this.previewDirectionY = 1;
        this.previewInterval = setInterval(() => {
          if (this.isMoving) {
            this.movePreviewBall();
          }
        }, 30);
        // Poll for state updates
        this.fetchInterval = setInterval(() => {
          this.fetchBall();
        }, 500);
        window.addEventListener('resize', this.handlePreviewResize);
      },
      beforeDestroy() {
        clearInterval(this.previewInterval);
        if (this.fetchInterval) {
          clearInterval(this.fetchInterval);
        }
        window.removeEventListener('resize', this.handlePreviewResize);
      }
}
</script>
<style>
.speed-presets {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 10px;
  margin-top: 8px;
  font-size: 1em;
}
.preset-btn {
  padding: 8px 16px;
  border-radius: 8px;
  border: none;
  background: linear-gradient(90deg, #e3f2fd 60%, #64b5f6 100%);
  color: #1769aa;
  font-weight: 600;
  cursor: pointer;
  box-shadow: 0 2px 8px rgba(33,150,243,0.10);
  transition: background 0.2s, transform 0.2s;
  font-size: 0.95em;
  line-height: 1.1;
}
.preset-btn:hover {
  background: linear-gradient(90deg, #2196f3 60%, #64b5f6 100%);
  color: white;
  transform: translateY(-2px) scale(1.04);
}
/* Copy button styling */
.copy-btn {
  margin-left: 12px;
  padding: 8px 18px;
  font-size: 1em;
  border-radius: 8px;
  border: none;
  background: linear-gradient(90deg, #64b5f6 60%, #e3f2fd 100%);
  color: #1769aa;
  font-weight: 600;
  cursor: pointer;
  box-shadow: 0 2px 8px rgba(33,150,243,0.10);
  transition: background 0.2s, transform 0.2s;
}
.copy-btn:hover {
  background: linear-gradient(90deg, #2196f3 60%, #64b5f6 100%);
  color: white;
  transform: translateY(-2px) scale(1.04);
}
body {
  margin: 0;
  font-family: 'Segoe UI', 'Roboto', Arial, sans-serif;
}
.controller-bg {
  min-height: 100vh;
  background: linear-gradient(135deg, #2196f3 0%, #e3f2fd 100%);
  display: flex;
  align-items: center;
  justify-content: center;
}
.controller-card {
  background: white;
  box-shadow: 0 8px 32px rgba(33,150,243,0.15);
  border-radius: 24px;
  padding: 48px 40px 32px 40px;
  text-align: center;
  min-width: 340px;
}
.controller-card h1 {
  font-size: 2em;
  margin-bottom: 18px;
  color: #2196f3;
  font-weight: 700;
}
.controller-buttons {
  display: flex;
  gap: 24px;
  justify-content: center;
  margin-bottom: 32px;
}
.icon {
  font-size: 1.2em;
  margin-right: 8px;
}
.app-info {
  background: linear-gradient(90deg, #e3f2fd 0%, #bbdefb 100%);
  color: #1769aa;
  border-radius: 12px;
  padding: 12px;
  margin: 18px auto 24px auto;
  text-align: center;
  font-size: 1.05em;
  font-weight: 500;
  box-shadow: 0 2px 8px rgba(33,150,243,0.08);
  max-width: 340px;
}
.session-limit-notification {
  background: linear-gradient(90deg, #f44336 0%, #ff9800 100%);
  color: #fff;
  border-radius: 16px;
  padding: 24px;
  margin: 24px auto;
  text-align: center;
  font-size: 1.2em;
  box-shadow: 0 2px 8px rgba(0,0,0,0.12);
  max-width: 400px;
}
.session-limit-notification a {
  color: #fff;
  text-decoration: underline;
  font-weight: bold;
}
.start-btn, .stop-btn {
  padding: 14px 32px;
  font-size: 1.1em;
  border-radius: 12px;
  border: none;
  background: linear-gradient(90deg, #2196f3 60%, #64b5f6 100%);
  color: white;
  font-weight: 600;
  cursor: pointer;
  box-shadow: 0 2px 8px rgba(33,150,243,0.10);
  transition: background 0.2s, transform 0.2s;
}
.start-btn:hover, .stop-btn:hover {
  background: linear-gradient(90deg, #1769aa 60%, #2196f3 100%);
  transform: translateY(-2px) scale(1.04);
}
.controls {
  display: flex;
  flex-wrap: wrap;
  gap: 24px;
  justify-content: center;
  margin-bottom: 20px;
}
label {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  font-size: 1em;
  color: #1769aa;
  font-weight: 500;
}
input[type="range"] {
  width: 120px;
}
.sound-status-active {
  background: linear-gradient(90deg, #4caf50 0%, #81c784 100%);
  color: white;
  padding: 12px 24px;
  border-radius: 12px;
  font-size: 1.1em;
  font-weight: 600;
  box-shadow: 0 2px 8px rgba(76, 175, 80, 0.3);
  animation: pulse 2s ease-in-out infinite;
}
.sound-status-inactive {
  background: linear-gradient(90deg, #9e9e9e 0%, #bdbdbd 100%);
  color: white;
  padding: 12px 24px;
  border-radius: 12px;
  font-size: 1.1em;
  font-weight: 600;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}
@keyframes pulse {
  0%, 100% {
    transform: scale(1);
    box-shadow: 0 2px 8px rgba(76, 175, 80, 0.3);
  }
  50% {
    transform: scale(1.05);
    box-shadow: 0 4px 16px rgba(76, 175, 80, 0.5);
  }
}
</style>