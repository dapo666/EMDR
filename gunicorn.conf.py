# Gunicorn configuration for production
import multiprocessing
import os

# Server socket
bind = "127.0.0.1:5000"
backlog = 2048

# Worker processes - USE 1 WORKER for in-memory session state!
# Multiple workers each have separate memory, breaking session state
# Use threads for concurrency instead
workers = 1  # MUST be 1 for in-memory session_states dict to work
worker_class = "gthread"  # Use threads for concurrency
worker_connections = 1000
timeout = 300  # Longer timeout for polling connections
keepalive = 65  # Keep connections alive longer (matches nginx)
threads = 4  # Use more threads to handle concurrent requests

# Logging
accesslog = "/var/log/gunicorn/access.log"
errorlog = "/var/log/gunicorn/error.log"
loglevel = "info"
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s"'

# Process naming
proc_name = "emdr_app"

# Server mechanics
daemon = False
pidfile = None  # Let systemd handle PID
umask = 0
user = None  # Let systemd handle user
group = None  # Let systemd handle group
tmp_upload_dir = None

# SSL (not needed as nginx handles SSL)
# keyfile = None
# certfile = None

# Security
limit_request_line = 4094
limit_request_fields = 100
limit_request_field_size = 8190
