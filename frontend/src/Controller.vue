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
      <div class="controls">
        <label><span class="icon">⚡</span> Speed:<br>
          <input type="range" min="1" max="20" v-model="speed" @input="updateBall" />
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
      previewInterval: null
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
        setPresetSpeed(movementsPerMin) {
          if (movementsPerMin === 45) this.speed = 4;
          else if (movementsPerMin === 75) this.speed = 7;
          else if (movementsPerMin === 120) this.speed = 12;
          this.updateBall();
        },
        updateBallSize() {
          this.previewBallSize = this.ballSize;
          axios.post('/api/ball', { speed: this.speed, bounceMode: this.bounceMode, isMoving: this.isMoving, ballSize: this.ballSize });
        },
        setPresetSpeed(movementsPerMin) {
          // Map 45 -> 4, 75 -> 7, 120 -> 12
          if (movementsPerMin === 45) this.speed = 4;
          else if (movementsPerMin === 75) this.speed = 7;
          else if (movementsPerMin === 120) this.speed = 12;
          this.updateBall();
        },
        setPresetSpeed(movementsPerMin) {
          // Map 45 -> 4, 75 -> 7, 120 -> 12
          if (movementsPerMin === 45) this.speed = 4;
          else if (movementsPerMin === 75) this.speed = 7;
          else if (movementsPerMin === 120) this.speed = 12;
          this.updateBall();
        },
        getSessionIdFromUrl() {
          const params = new URLSearchParams(window.location.search);
          this.sessionId = params.get('session') || '';
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
          axios.post('/api/ball', { speed: this.speed, bounceMode: this.bounceMode, isMoving: false, ballSize: this.ballSize });
        },
        startBall() {
          this.isMoving = true;
          axios.post('/api/ball', { speed: this.speed, bounceMode: this.bounceMode, isMoving: true, ballSize: this.ballSize });
        },
        updateBall() {
          axios.post('/api/ball', { speed: this.speed, bounceMode: this.bounceMode, isMoving: this.isMoving, ballSize: this.ballSize });
        },
        updateBackground() {
          axios.post('/api/background', { backgroundColor: this.backgroundColor });
        },
        updateBallColor() {
          axios.post('/api/ballcolor', { ballColor: this.ballColor });
        },
        fetchBall() {
          axios.get('/api/ball').then(res => {
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
          axios.get('/api/background').then(res => {
            this.backgroundColor = res.data.backgroundColor || '#888';
          });
          axios.get('/api/ballcolor').then(res => {
            this.ballColor = res.data.ballColor || '#2196f3';
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
        this.previewX = 0;
        this.previewY = 0;
        this.previewDirectionX = 1;
        this.previewDirectionY = 1;
        this.previewInterval = setInterval(() => {
          if (this.isMoving) {
            this.movePreviewBall();
          }
        }, 30);
        window.addEventListener('resize', this.handlePreviewResize);
      },
      beforeDestroy() {
        clearInterval(this.previewInterval);
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
</style>


