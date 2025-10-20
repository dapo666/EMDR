# Dockerfile for Flask + Vue app
FROM python:3.13-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y build-essential npm && rm -rf /var/lib/apt/lists/*

# Copy backend and frontend code
COPY backend/ backend/
COPY frontend/ frontend/
COPY requirements.txt ./

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Build frontend
WORKDIR /app/frontend
RUN npm install && npm run build

# Move built frontend to backend static folder
RUN rm -rf /app/backend/static && mkdir -p /app/backend/static && cp -r /app/frontend/dist/* /app/backend/static/

# Set working directory to backend
WORKDIR /app/backend

# Expose Flask port
EXPOSE 5000

# Run Flask app
CMD ["python", "app.py"]
