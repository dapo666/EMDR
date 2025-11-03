<template>
  <div class="container" :style="containerStyle" @click="unlockAudio">
    <div v-if="showAudioPrompt" class="audio-prompt">Click anywhere to start session</div>
    <div class="ball" :style="ballStyle"></div>
  </div>
</template>

<script>
import axios from 'axios';

export default {
  data() {
    return {
      speed: 5,
      bounceMode: 'horizontal',
      positionX: 0,
      positionY: 0,
      directionX: 1,
      directionY: 1,
      animationFrame: null,
      ballSize: 30, // px
      backgroundColor: '#ffffff',
      ballColor: '#2196f3',
      isMoving: false,
      bilateralSoundActive: false,
      soundInterval: null,
      audioCtx: null,
      beepBuffer: null,
      currentSide: 'left',
      audioUnlocked: false,
      showAudioPrompt: true,
      bilateralSpeed: 500,
      fetchInterval: null,
      sessionId: '',
      figure8Time: 0,
      randomColor: false,
      colorChangeInterval: null,
    };
  },
  mounted() {
    document.title = 'EMDR - Patient';
  },
  computed: {
    ballStyle() {
      return {
        left: this.positionX + 'px',
        top: this.positionY + 'px',
        background: this.ballColor,
        width: this.ballSize + 'px',
        height: this.ballSize + 'px',
        borderRadius: '50%',
        position: 'absolute',
        willChange: this.isMoving ? 'transform' : 'auto',
        transform: 'translate3d(0, 0, 0)',
      };
    },
    containerStyle() {
      return {
        background: this.backgroundColor
      };
    }
  },
  methods: {
    unlockAudio() {
      if (!this.audioUnlocked) {
        this.audioUnlocked = true;
        this.showAudioPrompt = false;
        // Create AudioContext on user gesture
        try {
          this.audioCtx = new (window.AudioContext || window.webkitAudioContext)();
          // Generate beep buffer after AudioContext is created
          this.generateBeepBuffer();
        } catch (e) {
          // Audio initialization failed
        }
      }
    },
    generateBeepBuffer() {
      if (!this.audioCtx) return;
      // Generate a short beep sound buffer
      const sampleRate = this.audioCtx.sampleRate;
      const duration = 0.1; // seconds
      const freq = 880; // Hz
      const buffer = this.audioCtx.createBuffer(1, sampleRate * duration, sampleRate);
      const data = buffer.getChannelData(0);
      for (let i = 0; i < data.length; i++) {
        data[i] = Math.sin(2 * Math.PI * freq * (i / sampleRate)) * Math.exp(-30 * i / sampleRate);
      }
      this.beepBuffer = buffer;
    },
    // Ball movement and state
    moveBall() {
      const width = window.innerWidth;
      const height = window.innerHeight;
      const minX = 0;
      const minY = 0;
      const maxX = width - this.ballSize;
      const maxY = height - this.ballSize;
      if (this.bounceMode === 'horizontal') {
        this.positionY = Math.floor(height / 2 - this.ballSize / 2);
        this.positionX += this.speed * this.directionX;
        if (this.positionX >= maxX) {
          this.positionX = maxX;
          this.directionX = -1;
        } else if (this.positionX <= minX) {
          this.positionX = minX;
          this.directionX = 1;
        }
      } else if (this.bounceMode === 'vertical') {
        this.positionX = Math.floor(width / 2 - this.ballSize / 2);
        this.positionY += this.speed * this.directionY;
        if (this.positionY >= maxY) {
          this.positionY = maxY;
          this.directionY = -1;
        } else if (this.positionY <= minY) {
          this.positionY = minY;
          this.directionY = 1;
        }
      } else if (this.bounceMode === 'diagonal') {
        this.positionX += this.speed * this.directionX;
        this.positionY += this.speed * this.directionY;
        if (this.positionX >= maxX) {
          this.positionX = maxX;
          this.directionX = -1;
        } else if (this.positionX <= minX) {
          this.positionX = minX;
          this.directionX = 1;
        }
        if (this.positionY >= maxY) {
          this.positionY = maxY;
          this.directionY = -1;
        } else if (this.positionY <= minY) {
          this.positionY = minY;
          this.directionY = 1;
        }
      } else if (this.bounceMode === 'random') {
        this.positionX += this.speed * this.directionX;
        this.positionY += this.speed * this.directionY;
        if (this.positionX >= maxX || this.positionX <= minX) {
          this.directionX = Math.random() > 0.5 ? 1 : -1;
        }
        if (this.positionY >= maxY || this.positionY <= minY) {
          this.directionY = Math.random() > 0.5 ? 1 : -1;
        }
        this.positionX = Math.max(minX, Math.min(maxX, this.positionX));
        this.positionY = Math.max(minY, Math.min(maxY, this.positionY));
      } else if (this.bounceMode === 'figure8') {
        // Figure-8 (lemniscate) pattern using parametric equations
        // x = a * sin(t), y = a * sin(t) * cos(t)
        const centerX = width / 2;
        const centerY = height / 2;
        const scale = Math.min(width, height) * 0.35; // 35% of smallest dimension
        
        // Increment time based on speed
        this.figure8Time += this.speed * 0.01;
        
        // Parametric equations for figure-8
        const t = this.figure8Time;
        this.positionX = centerX + scale * Math.sin(t) - this.ballSize / 2;
        this.positionY = centerY + scale * Math.sin(t) * Math.cos(t) - this.ballSize / 2;
        
        // Keep within bounds
        this.positionX = Math.max(minX, Math.min(maxX, this.positionX));
        this.positionY = Math.max(minY, Math.min(maxY, this.positionY));
      }
    },
    async fetchBall() {
      const sessionParam = this.sessionId ? `?session=${this.sessionId}` : '';
      
      if (!this.sessionId) {
        console.error('Patient: No session ID!');
        return;
      }
      
      try {
        // Fetch all state in parallel
        const [ballRes, bgRes, colorRes, soundRes] = await Promise.all([
          axios.get(`/api/ball${sessionParam}`),
          axios.get(`/api/background${sessionParam}`),
          axios.get(`/api/ballcolor${sessionParam}`),
          axios.get(`/api/sound${sessionParam}`)
        ]);
        
        // Update ball state
        this.speed = ballRes.data.speed;
        this.bounceMode = ballRes.data.bounceMode || 'horizontal';
        this.isMoving = ballRes.data.isMoving || false;
        if (ballRes.data.ballSize !== undefined) {
          this.ballSize = ballRes.data.ballSize;
        }
        
        // If bounce mode changed, reset position to center
        if (this.bounceMode !== this.lastBounceMode) {
          this.x = window.innerWidth / 2;
          this.y = window.innerHeight / 2;
          this.vx = this.speed;
          this.vy = this.speed;
          this.angle = 0;
        }
        this.lastBounceMode = this.bounceMode;
        
        // Update background
        const newBgColor = bgRes.data.backgroundColor || '#ffffff';
        if (newBgColor !== this.backgroundColor) {
          console.log(`[PATIENT] Background color changed from ${this.backgroundColor} to ${newBgColor}`);
        }
        this.backgroundColor = newBgColor;
        
        // Update ball color
        const newRandomColor = colorRes.data.randomColor || false;
        if (newRandomColor && !this.randomColor) {
          this.randomColor = true;
          this.startRandomColor();
        } else if (!newRandomColor && this.randomColor) {
          this.randomColor = false;
          this.stopRandomColor();
          this.ballColor = colorRes.data.ballColor || '#2196f3';
        } else if (!newRandomColor) {
          this.ballColor = colorRes.data.ballColor || '#2196f3';
        }
        
        // Update bilateral sound
        const backendBilateral = soundRes.data.bilateral === true;
        if (backendBilateral && !this.bilateralSoundActive) {
          console.log('[PATIENT] Backend says ON, starting bilateral sound');
          this.bilateralSoundActive = true;
          this.startBilateralSound();
        } else if (!backendBilateral && this.bilateralSoundActive) {
          console.log('[PATIENT] Backend says OFF, stopping bilateral sound');
          this.bilateralSoundActive = false;
          this.stopBilateralSound();
        }
        // Debug: log every 10th poll to avoid console spam
        if (Math.random() < 0.1) {
          console.log(`[PATIENT] Poll: bilateral=${backendBilateral}, bg=${newBgColor}, moving=${this.isMoving}`);
        }
      } catch (error) {
        console.error('Error fetching state:', error);
      }
    },
    startRandomColor() {
      if (this.colorChangeInterval) return;
      this.colorChangeInterval = setInterval(() => {
        this.ballColor = '#' + Math.floor(Math.random()*16777215).toString(16).padStart(6, '0');
      }, 200); // Change color every 200ms
    },
    stopRandomColor() {
      if (this.colorChangeInterval) {
        clearInterval(this.colorChangeInterval);
        this.colorChangeInterval = null;
      }
    },
    // Bilateral sound logic
    startBilateralSound() {
      if (!this.audioUnlocked || !this.audioCtx || !this.beepBuffer) {
        console.log('[PATIENT] Cannot start bilateral sound - audio not ready');
        return;
      }
      
      // Prevent restarting if already running
      if (this.bilateralSoundTimer) {
        console.log('[PATIENT] Bilateral sound already running, skipping restart');
        return;
      }
      
      console.log('[PATIENT] Starting bilateral sound');
      this.bilateralSoundTimer = setInterval(() => {
        const source = this.audioCtx.createBufferSource();
        source.buffer = this.beepBuffer;
        
        // Create a new panner for each beep (Safari compatibility)
        let panner;
        try {
          // Try modern StereoPanner (Chrome, Firefox, Edge)
          panner = this.audioCtx.createStereoPanner();
          panner.pan.value = this.currentSide === 'left' ? -1 : 1;
        } catch (e) {
          // Fallback to PannerNode for Safari
          panner = this.audioCtx.createPanner();
          panner.panningModel = 'equalpower';
          panner.setPosition(this.currentSide === 'left' ? -1 : 1, 0, 0);
        }
        
        source.connect(panner);
        panner.connect(this.audioCtx.destination);
        source.start();
        
        // Alternate sides
        this.currentSide = this.currentSide === 'left' ? 'right' : 'left';
      }, this.bilateralSpeed);
    },
    stopBilateralSound() {
      console.log('[PATIENT] Stopping bilateral sound');
      if (this.bilateralSoundTimer) {
        clearInterval(this.bilateralSoundTimer);
        this.bilateralSoundTimer = null;
      }
    },
    animate() {
      if (this.isMoving) {
        this.moveBall();
      }
      this.animationFrame = requestAnimationFrame(this.animate);
    }
  },
  mounted() {
    document.title = 'EMDR Patient';
    // Get session ID from URL
    const urlParams = new URLSearchParams(window.location.search);
    this.sessionId = urlParams.get('session') || '';
    console.log(`[PATIENT] Loaded with session ID: ${this.sessionId}`);
    this.fetchBall();
    // Use requestAnimationFrame for smooth animation across all browsers
    this.animate();
    
    // Single unified polling interval - fetch ALL state together
    // 500ms for responsive updates (background color, bilateral sound)
    this.fetchInterval = setInterval(() => {
      this.fetchBall();
    }, 500);
  },
  beforeDestroy() {
    if (this.animationFrame) {
      cancelAnimationFrame(this.animationFrame);
    }
    if (this.fetchInterval) {
      clearInterval(this.fetchInterval);
    }
    if (this.bilateralSoundTimer) {
      clearInterval(this.bilateralSoundTimer);
    }
    if (this.colorChangeInterval) {
      clearInterval(this.colorChangeInterval);
    }
  }
};
</script>

<style>
/* Audio unlock prompt styling */
.audio-prompt {
  position: absolute;
  top: 40%;
  left: 50%;
  transform: translate(-50%, -50%);
  background: #4a4a4a;
  color: #fff;
  padding: 20px 40px;
  border-radius: 4px;
  font-size: 1.2em;
  font-weight: 500;
  z-index: 10;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  cursor: pointer;
  transition: background 0.3s ease;
}
.audio-prompt:hover {
  background: #333;
}
html, body, .container {
  height: 100vh;
  width: 100vw;
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}
.container {
  position: relative;
  overflow: hidden;
  /* Background color controlled by :style binding */
  /* Enable hardware acceleration for better performance */
  -webkit-transform: translateZ(0);
  transform: translateZ(0);
}
.ball {
  position: absolute;
  /* Hardware acceleration for smooth animation across all browsers */
  -webkit-backface-visibility: hidden;
  backface-visibility: hidden;
  -webkit-perspective: 1000;
  perspective: 1000;
}
</style>
