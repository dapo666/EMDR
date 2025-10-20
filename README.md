# EMDR Therapy Web App

This is a local web application for EMDR therapy, featuring a moving ball on a gray screen. The ball's speed and direction can be adjusted via controls.

## How to Run

### Backend (Flask)
1. Install dependencies:
   ```bash
   pip install flask flask-cors
   ```
2. Start the backend:
   ```bash
   python backend/app.py
   ```

### Frontend (Vue.js)
1. Install dependencies:
   ```bash
   cd frontend
   npm install
   ```
2. Build the frontend:
   ```bash
   npm run build
   ```

The Flask backend will serve the built frontend at `http://localhost:5000`.

## Features
- Adjustable ball speed and direction
- Responsive gray screen
- Simple controls for EMDR therapy
