<template>
  <div class="container" :style="containerStyle" @click="unlockAudio">
    <div v-if="showAudioPrompt" class="audio-prompt">Click anywhere to enable sound</div>
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
      backgroundColor: '#888',
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
    };
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
      }
    },
    fetchBall() {
      const sessionParam = this.sessionId ? `?session=${this.sessionId}` : '';
      axios.get(`/api/ball${sessionParam}`).then(res => {
        this.speed = res.data.speed;
        this.bounceMode = res.data.bounceMode || 'horizontal';
        this.isMoving = res.data.isMoving || false;
        if (res.data.ballSize !== undefined) {
          this.ballSize = res.data.ballSize;
        }
        if (this.bounceMode === 'vertical' && typeof this.lastBounceMode !== 'undefined' && this.lastBounceMode !== 'vertical') {
          const width = window.innerWidth;
          this.positionX = Math.floor(width / 2 - this.ballSize / 2);
          this.positionY = 0;
        }
        this.lastBounceMode = this.bounceMode;
      });
      axios.get(`/api/background${sessionParam}`).then(res => {
        this.backgroundColor = res.data.backgroundColor || '#888';
      });
      axios.get(`/api/ballcolor${sessionParam}`).then(res => {
        this.ballColor = res.data.ballColor || '#2196f3';
      });
    },
    // Bilateral sound logic
    checkBilateralSound() {
      const sessionParam = this.sessionId ? `?session=${this.sessionId}` : '';
      axios.get(`/api/sound${sessionParam}`)
        .then(res => {
          if (res.data.bilateral && !this.bilateralSoundActive) {
            this.bilateralSoundActive = true;
            this.startBilateralSound();
          } else if (!res.data.bilateral && this.bilateralSoundActive) {
            this.bilateralSoundActive = false;
            this.stopBilateralSound();
          }
        });
    },
    startBilateralSound() {
      if (!this.audioUnlocked || !this.audioCtx || !this.beepBuffer) return;
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
      clearInterval(this.bilateralSoundTimer);
      // No need to pause, as beep is short and played via buffer
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
    this.fetchBall();
    // Use requestAnimationFrame for smooth animation across all browsers
    this.animate();
    this.fetchInterval = setInterval(() => {
      this.fetchBall();
    }, 500);

    // Bilateral sound polling
    this.soundInterval = setInterval(() => {
      this.checkBilateralSound();
    }, 500);
  },
  beforeDestroy() {
    if (this.animationFrame) {
      cancelAnimationFrame(this.animationFrame);
    }
    clearInterval(this.fetchInterval);
    clearInterval(this.soundInterval);
    if (this.bilateralSoundTimer) {
      clearInterval(this.bilateralSoundTimer);
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
  background: rgba(33,150,243,0.95);
  color: #fff;
  padding: 24px 40px;
  border-radius: 16px;
  font-size: 1.3em;
  font-weight: 600;
  z-index: 10;
  box-shadow: 0 4px 24px rgba(33,150,243,0.18);
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
