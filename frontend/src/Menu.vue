<template>
  <div class="menu-bg">
    <div class="menu-card">
      <h1>EMDR Therapy App</h1>
      <p class="subtitle">Professional bilateral stimulation for EMDR therapy sessions</p>
      <div class="menu-buttons">
        <button 
          :class="['therapist-btn', { 'disabled': limitReached }]" 
          @click="openTherapist"
          :disabled="limitReached">
          {{ limitReached ? 'Maximum sessions limit reached' : 'Start Therapist Session' }}
        </button>
      </div>
      <div class="features">
        <div class="feature-item">
          <span class="feature-icon">✓</span>
          <span>Cross-browser compatibility</span>
        </div>
        <div class="feature-item">
          <span class="feature-icon">✓</span>
          <span>Bilateral audio stimulation</span>
        </div>
        <div class="feature-item">
          <span class="feature-icon">✓</span>
          <span>Customizable visual settings</span>
        </div>
        <div class="feature-item">
          <span class="feature-icon">✓</span>
          <span>Completely free</span>
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
          Interested in developing your own application with us? 
          <a href="mailto:info@expatpsychologie.nl" class="contact-link">Contact now!</a>
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
  data() {
    return {
      limitReached: false
    };
  },
  mounted() {
    this.checkSessionLimit();
    // Check session limit every 5 seconds
    this.intervalId = setInterval(() => {
      this.checkSessionLimit();
    }, 5000);
  },
  beforeDestroy() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
    }
  },
  methods: {
    async checkSessionLimit() {
      try {
        const response = await axios.get('/api/session-count');
        this.limitReached = response.data.limitReached;
      } catch (error) {
        console.error('Error checking session limit:', error);
      }
    },
    openTherapist() {
      if (this.limitReached) return;
      // Generate random session ID
      const sessionId = Math.random().toString(36).substr(2, 9);
      window.open(`/controller?session=${sessionId}`, '_blank');
    }
  }
};
</script>

<style>
body {
  margin: 0;
  font-family: 'Segoe UI', 'Roboto', Arial, sans-serif;
}
.menu-bg {
  min-height: 100vh;
  background: #f5f5f5;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: space-between;
  padding: 20px 20px 0 20px;
}
.menu-card {
  background: white;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  border-radius: 8px;
  padding: 60px 40px;
  text-align: center;
  min-width: 340px;
  max-width: 600px;
  width: 100%;
  margin: auto;
}
.menu-card h1 {
  font-size: 2.5em;
  margin-bottom: 16px;
  color: #333;
  font-weight: 600;
}
.menu-card .subtitle {
  color: #666;
  font-size: 1.1em;
  margin-bottom: 40px;
  line-height: 1.6;
}
.menu-buttons {
  display: flex;
  gap: 24px;
  justify-content: center;
  margin-bottom: 40px;
}
.icon {
  font-size: 1.2em;
  margin-right: 8px;
}
.patient-btn, .therapist-btn {
  padding: 16px 36px;
  font-size: 1.1em;
  border-radius: 4px;
  border: none;
  background: #4a4a4a;
  color: white;
  font-weight: 500;
  cursor: pointer;
  transition: background 0.3s ease;
}
.patient-btn:hover, .therapist-btn:hover {
  background: #333;
}
.therapist-btn.disabled {
  background: #9e9e9e;
  color: #e0e0e0;
  cursor: not-allowed;
  opacity: 0.6;
}
.therapist-btn.disabled:hover {
  background: #9e9e9e;
}
.features {
  display: flex;
  flex-direction: column;
  gap: 16px;
  margin-top: 40px;
  padding-top: 40px;
  border-top: 1px solid #e0e0e0;
}
.feature-item {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  font-size: 1em;
  color: #666;
}
.feature-icon {
  color: #4caf50;
  font-weight: bold;
  font-size: 1.2em;
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
</style>
