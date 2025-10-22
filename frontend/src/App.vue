<template>
  <div class="container" :style="containerStyle">
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
      interval: null,
  ballSize: 30, // px
  backgroundColor: '#888',
  ballColor: '#2196f3',
  isMoving: false,
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
      };
    },
    containerStyle() {
      return {
        background: this.backgroundColor
      };
    }
  },
  methods: {
  // No controls in patient view
    moveBall() {
  const width = window.innerWidth;
  const height = window.innerHeight;
  const minX = 0;
  const minY = 0;
  const maxX = width - this.ballSize;
  const maxY = height - this.ballSize;

      if (this.bounceMode === 'horizontal') {
        // Only move horizontally, keep vertically centered
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
        // Only move vertically, keep horizontally centered (do NOT reset positionY)
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
      axios.get('/api/ball').then(res => {
        this.speed = res.data.speed;
        this.bounceMode = res.data.bounceMode || 'horizontal';
        this.isMoving = res.data.isMoving || false;
        if (res.data.ballSize !== undefined) {
          this.ballSize = res.data.ballSize;
        }
        // Center ball for up-down movement ONLY when bounce mode changes to vertical
        if (this.bounceMode === 'vertical' && typeof this.lastBounceMode !== 'undefined' && this.lastBounceMode !== 'vertical') {
          const width = window.innerWidth;
          this.positionX = Math.floor(width / 2 - this.ballSize / 2);
          this.positionY = 0;
        }
        this.lastBounceMode = this.bounceMode;
      });
      axios.get('/api/background').then(res => {
        this.backgroundColor = res.data.backgroundColor || '#888';
      });
      axios.get('/api/ballcolor').then(res => {
        this.ballColor = res.data.ballColor || '#2196f3';
      });
    },
  },
  mounted() {
    document.title = 'EMDR Patient';
    this.fetchBall();
    this.position = 50;
    this.direction = 'right';
    this.interval = setInterval(() => {
      if (this.isMoving) {
        this.moveBall();
      }
    }, 16);
    this.fetchInterval = setInterval(() => {
      this.fetchBall();
    }, 500);
  },
  beforeDestroy() {
  clearInterval(this.interval);
  clearInterval(this.fetchInterval);
  }
};
</script>

<style>
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
}
.ball {
  transition: left 0.016s linear;
  position: absolute;
}
</style>
