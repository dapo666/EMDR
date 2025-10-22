# EMDR Therapy Web App

This is a local web application for EMDR therapy, featuring a moving ball on a gray screen. The ball's speed and direction can be adjusted via controls.

## How to Run

### 1. Clone the Project

Clone the repository from GitHub:
```bash
git clone https://github.com/dapo666/EMDR
cd EMDR
```

### 2. Backend (Flask)

Set up a Python virtual environment and install dependencies:
```bash
python3 -m venv venv
source venv/bin/activate  # On Windows use: venv\Scripts\activate
pip install flask flask-cors
```

Start the backend:
```bash
python3 backend/app.py
```

### 3. Frontend (Vue.js)

Install frontend dependencies and build:
```bash
cd frontend
npm install
npm run build
```

The Flask backend will serve the built frontend at `http://localhost:5000`.

## Features
- Adjustable ball speed and direction
- Responsive gray screen
- Simple controls for EMDR therapy
