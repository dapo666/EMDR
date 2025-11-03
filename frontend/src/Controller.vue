

<template>
  <div class="controller-bg">
    <div class="controller-card">
      <h1>Therapist Controls</h1>
      <div class="patient-link">
        Patient link: <a :href="patientUrl" target="_blank">{{ patientUrl }}</a>
          <button class="copy-btn" @click="copyPatientUrl">Copy</button>
      </div>
      <div v-if="sessionLimitError" class="session-limit-notification">
        <span class="icon">🚫</span>
        <strong>Max session limit reached for free version.</strong><br>
        To allow new connection please subscribe to paid version.<br>
        <span class="icon">✉️</span> Contact: <a href="mailto:info@expatpsychologie.nl">info@expatpsychologie.nl</a>
      </div>
      <div class="controller-buttons">
        <button :class="isMoving ? 'start-btn-active' : 'start-btn'" @click="startBall">Start</button>
        <button :class="!isMoving ? 'stop-btn-active' : 'stop-btn'" @click="stopBall">Stop</button>
      </div>
      <div class="sound-controls" style="margin-bottom:32px;display:flex;flex-direction:column;align-items:center;gap:12px;">
        <button 
          :class="bilateralSoundActive ? 'sound-btn-on' : 'sound-btn-off'" 
          @click="toggleBilateralSound">
          Bilateral sound: {{ bilateralSoundActive ? 'ON' : 'OFF' }}
        </button>
      </div>
  <div class="controls">
        <div class="control-row">
          <label class="control-label">
            <strong>Speed:</strong>
            <input type="range" min="1" max="80" v-model="speed" @input="updateBall" />
          </label>
        </div>
        <div class="control-row">
          <label class="control-label">
            <strong>Bounce Mode:</strong>
            <select v-model="bounceMode" @change="updateBall">
              <option value="horizontal">Left-Right</option>
              <option value="vertical">Up-Down</option>
              <option value="random">Random</option>
              <option value="figure8">8 Shape</option>
            </select>
          </label>
        </div>
        <div class="control-row">
          <label class="control-label">
            <strong>Ball Size:</strong>
            <input type="range" min="10" max="80" v-model="ballSize" @input="updateBallSize" />
          </label>
        </div>
        <div class="control-row">
          <label class="control-label">
            <strong>Background Color:</strong>
            <input type="color" v-model="backgroundColor" @input="updateBackground" />
          </label>
        </div>
        <div class="control-row">
          <label class="control-label">
            <strong>Ball Color:</strong>
            <div class="ball-color-controls">
              <select v-model="ballColorMode" @change="updateBallColorMode">
                <option value="static">Static Color</option>
                <option value="random">Random Colors</option>
              </select>
              <input v-if="ballColorMode === 'static'" type="color" v-model="ballColor" @input="updateBallColor" />
            </div>
          </label>
        </div>
      </div>
    </div>
    <footer class="company-footer">
      <div class="footer-content">
        <div class="company-info">
          <strong>DRP CONSULTING</strong><br>
          KVK: 85650595<br>
          © 2025<br>
          <span class="version">v2025.11.01</span>
        </div>
        <div class="footer-cta">
          Interested in developing your own application? 
          <a href="mailto:info@expatpsychologie.nl" class="contact-link">Contact us now!</a>
          <br><br>
          <a href="https://expatpsychologie.nl/en/" target="_blank" class="contact-link">ExpatPsychologie.nl</a> - Your Psychologist in the Netherlands
        </div>
      </div>
    </footer>
  </div>
</template>

<script>

import axios from 'axios';

export default {
  mounted() {
    document.title = 'EMDR - Therapist';
  },
  data() {
    return {
  speed: 5,
  sessionLimitError: false,
      bounceMode: 'horizontal',
      backgroundColor: '#ffffff',
      ballColor: '#2196f3',
      ballColorMode: 'static',
      isMoving: false,
      sessionId: '',
      ballSize: 30,
      bilateralSoundActive: false
    };
      },
      computed: {
        patientUrl() {
          return `/patient?session=${this.sessionId}`;
        }
      },
      methods: {
        toggleBilateralSound() {
          const sessionParam = this.sessionId ? `?session=${this.sessionId}` : '';
          const newState = !this.bilateralSoundActive;
          axios.post(`/api/sound${sessionParam}`, { bilateral: newState, speed: 500 })
            .then(() => {
              this.bilateralSoundActive = newState;
            })
            .catch(err => console.error('Error toggling bilateral sound:', err));
        },
        startBilateralSound() {
          const sessionParam = this.sessionId ? `?session=${this.sessionId}` : '';
          axios.post(`/api/sound${sessionParam}`, { bilateral: true, speed: 500 })
            .catch(err => console.error('Error starting bilateral sound:', err));
        },
        stopBilateralSound() {
          const sessionParam = this.sessionId ? `?session=${this.sessionId}` : '';
          axios.post(`/api/sound${sessionParam}`, { bilateral: false, speed: 500 })
            .catch(err => console.error('Error stopping bilateral sound:', err));
        },
        updateBallSize() {
          const sessionParam = this.sessionId ? `?session=${this.sessionId}` : '';
          axios.post(`/api/ball${sessionParam}`, { speed: this.speed, bounceMode: this.bounceMode, isMoving: this.isMoving, ballSize: this.ballSize })
            .catch(err => console.error('Error updating ball size:', err));
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
        stopBall() {
          this.isMoving = false;
          const sessionParam = this.sessionId ? `?session=${this.sessionId}` : '';
          axios.post(`/api/ball${sessionParam}`, { speed: this.speed, bounceMode: this.bounceMode, isMoving: false, ballSize: this.ballSize })
            .catch(err => console.error('Error stopping ball:', err));
          // Also stop bilateral sound when stopping ball movement
          this.stopBilateralSound();
        },
        startBall() {
          this.isMoving = true;
          const sessionParam = this.sessionId ? `?session=${this.sessionId}` : '';
          axios.post(`/api/ball${sessionParam}`, { speed: this.speed, bounceMode: this.bounceMode, isMoving: true, ballSize: this.ballSize })
            .catch(err => console.error('Error starting ball:', err));
        },
        updateBall() {
          const sessionParam = this.sessionId ? `?session=${this.sessionId}` : '';
          axios.post(`/api/ball${sessionParam}`, { speed: this.speed, bounceMode: this.bounceMode, isMoving: this.isMoving, ballSize: this.ballSize })
            .catch(err => console.error('Error updating ball:', err));
        },
        updateBackground() {
          const sessionParam = this.sessionId ? `?session=${this.sessionId}` : '';
          axios.post(`/api/background${sessionParam}`, { backgroundColor: this.backgroundColor })
            .catch(err => console.error('Error updating background:', err));
        },
        updateBallColor() {
          const sessionParam = this.sessionId ? `?session=${this.sessionId}` : '';
          axios.post(`/api/ballcolor${sessionParam}`, { ballColor: this.ballColor, randomColor: false })
            .catch(err => console.error('Error updating ball color:', err));
        },
        updateBallColorMode() {
          const sessionParam = this.sessionId ? `?session=${this.sessionId}` : '';
          if (this.ballColorMode === 'random') {
            axios.post(`/api/ballcolor${sessionParam}`, { randomColor: true })
              .catch(err => console.error('Error updating ball color mode:', err));
          } else {
            axios.post(`/api/ballcolor${sessionParam}`, { ballColor: this.ballColor, randomColor: false })
              .catch(err => console.error('Error updating ball color mode:', err));
          }
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
            }
          });
          axios.get(`/api/background${sessionParam}`).then(res => {
            this.backgroundColor = res.data.backgroundColor || '#ffffff';
          });
          axios.get(`/api/ballcolor${sessionParam}`).then(res => {
            this.ballColor = res.data.ballColor || '#2196f3';
            this.ballColorMode = res.data.randomColor ? 'random' : 'static';
          });
          axios.get(`/api/sound${sessionParam}`).then(res => {
            this.bilateralSoundActive = res.data.bilateral || false;
          });
        }
      },
      mounted() {
        this.getSessionIdFromUrl();
        // Only fetch initial state once - don't poll!
        // Controller sends updates, Patient receives them
        this.fetchBall();
      },
      beforeDestroy() {
        // No polling interval to clear
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
  border-radius: 4px;
  border: 1px solid #ddd;
  background: white;
  color: #333;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s ease;
  font-size: 0.9em;
  line-height: 1.3;
}
.preset-btn:hover {
  background: #f5f5f5;
  border-color: #999;
}
/* Copy button styling */
.copy-btn {
  margin-left: 12px;
  padding: 12px 28px;
  font-size: 1em;
  border-radius: 4px;
  border: none;
  background: #4a4a4a;
  color: white;
  font-weight: 500;
  cursor: pointer;
  transition: background 0.3s ease;
}
.copy-btn:hover {
  background: #333;
}
body {
  margin: 0;
  font-family: 'Segoe UI', 'Roboto', Arial, sans-serif;
}
.controller-bg {
  min-height: 100vh;
  background: #f5f5f5;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: space-between;
  padding: 20px 20px 0 20px;
}
.controller-card {
  background: white;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  border-radius: 8px;
  padding: 40px;
  text-align: center;
  min-width: 340px;
  max-width: 900px;
  width: 100%;
  margin-bottom: 20px;
}
.controller-card h1 {
  font-size: 2em;
  margin-bottom: 18px;
  color: #333;
  font-weight: 600;
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
  background: #f0f0f0;
  color: #666;
  border-radius: 6px;
  padding: 12px;
  margin: 18px auto 24px auto;
  text-align: center;
  font-size: 0.95em;
  font-weight: 400;
  max-width: 400px;
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
  padding: 12px 28px;
  font-size: 1em;
  border-radius: 4px;
  border: none;
  background: #4a4a4a;
  color: white;
  font-weight: 500;
  cursor: pointer;
  transition: background 0.3s ease;
}
.start-btn:hover, .stop-btn:hover {
  background: #333;
}
.start-btn-active {
  padding: 12px 28px;
  font-size: 1em;
  border-radius: 4px;
  border: none;
  background: #4caf50;
  color: white;
  font-weight: 500;
  cursor: pointer;
  transition: background 0.3s ease;
  animation: pulse 2s ease-in-out infinite;
}
.start-btn-active:hover {
  background: #45a049;
}
.stop-btn-active {
  padding: 12px 28px;
  font-size: 1em;
  border-radius: 4px;
  border: none;
  background: #f44336;
  color: white;
  font-weight: 500;
  cursor: pointer;
  transition: background 0.3s ease;
}
.stop-btn-active:hover {
  background: #da190b;
}
.controls {
  display: flex;
  flex-direction: column;
  gap: 16px;
  align-items: center;
  margin-bottom: 20px;
  width: 100%;
}
.control-row {
  display: flex;
  width: 100%;
  max-width: 300px;
}
.control-label {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  font-size: 0.95em;
  color: #333;
  width: 100%;
  gap: 8px;
}
.control-label strong {
  display: block;
  margin-bottom: 4px;
}
input[type="range"] {
  width: 100%;
}
select {
  padding: 6px 8px;
  font-size: 0.95em;
  border: 1px solid #ddd;
  border-radius: 4px;
  background: white;
  width: 100%;
}
input[type="color"] {
  width: 50px;
  height: 35px;
  border: 1px solid #ddd;
  border-radius: 4px;
  cursor: pointer;
  flex-shrink: 0;
}
.ball-color-controls {
  display: flex;
  gap: 8px;
  align-items: center;
  width: 100%;
}
.sound-btn-off {
  padding: 12px 28px;
  font-size: 1em;
  border-radius: 4px;
  border: none;
  background: #e0e0e0;
  color: #666;
  font-weight: 500;
  cursor: pointer;
  transition: background 0.3s ease;
}
.sound-btn-off:hover {
  background: #d0d0d0;
}
.sound-btn-on {
  padding: 12px 28px;
  font-size: 1em;
  border-radius: 4px;
  border: none;
  background: #4caf50;
  color: white;
  font-weight: 500;
  cursor: pointer;
  transition: background 0.3s ease;
  animation: pulse 2s ease-in-out infinite;
}
.sound-btn-on:hover {
  background: #45a049;
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
.company-footer {
  width: 100%;
  background: #2c2c2c;
  color: white;
  padding: 30px 20px;
  margin-top: auto;
}
.footer-content {
  max-width: 1200px;
  margin: 0 auto;
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 20px;
}
.company-info {
  text-align: left;
  font-size: 0.9em;
  line-height: 1.6;
}
.company-info strong {
  font-size: 1.1em;
  display: block;
  margin-bottom: 5px;
}
.footer-cta {
  text-align: right;
  font-size: 1em;
}
.contact-link {
  color: #fff;
  text-decoration: none;
  font-weight: 600;
  border-bottom: 2px solid #fff;
  padding-bottom: 2px;
  transition: opacity 0.3s ease;
}
.contact-link:hover {
  opacity: 0.8;
}
.version {
  font-size: 0.8em;
  color: #999;
  margin-top: 5px;
  display: inline-block;
}
@media (max-width: 768px) {
  .footer-content {
    flex-direction: column;
    text-align: center;
  }
  .company-info, .footer-cta {
    text-align: center;
  }
}
.patient-link {
  margin-bottom: 20px;
  font-size: 0.95em;
  color: #333;
}
.patient-link a {
  color: #4a4a4a;
  text-decoration: none;
  border-bottom: 1px solid #4a4a4a;
}
.patient-link a:hover {
  color: #000;
  border-bottom-color: #000;
}
.instructions {
  margin-bottom: 16px;
  color: #666;
  font-size: 0.95em;
}
</style>