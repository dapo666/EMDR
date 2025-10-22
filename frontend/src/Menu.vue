<template>
  <div class="menu-bg">
    <div class="menu-card">
      <h1><span class="icon">🧠</span> EMDR Therapy App</h1>
      <p class="subtitle">Start a new EMDR session</p>
      <div class="menu-buttons">
        <button class="therapist-btn" @click="openTherapist"><span class="icon">🩺</span> Therapist Screen</button>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  methods: {
    openTherapist() {
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
  background: linear-gradient(135deg, #2196f3 0%, #e3f2fd 100%);
  display: flex;
  align-items: center;
  justify-content: center;
}
.menu-card {
  background: white;
  box-shadow: 0 8px 32px rgba(33,150,243,0.15);
  border-radius: 24px;
  padding: 48px 40px 32px 40px;
  text-align: center;
  min-width: 340px;
}
.menu-card h1 {
  font-size: 2.2em;
  margin-bottom: 10px;
  color: #2196f3;
  font-weight: 700;
}
.menu-card .subtitle {
  color: #1769aa;
  font-size: 1.1em;
  margin-bottom: 32px;
}
.menu-buttons {
  display: flex;
  gap: 24px;
  justify-content: center;
}
.icon {
  font-size: 1.3em;
  margin-right: 8px;
}
.patient-btn, .therapist-btn {
  padding: 16px 36px;
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
.patient-btn:hover, .therapist-btn:hover {
  background: linear-gradient(90deg, #1769aa 60%, #2196f3 100%);
  transform: translateY(-2px) scale(1.04);
}
</style>
