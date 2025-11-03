# Gunicorn configuration for production
import multiprocessing
import os

# Server socket
bind = "127.0.0.1:5000"
backlog = 2048

# Worker processes - limit for VPS
# On small VPS (2 cores), use fewer workers
cpu_count = multiprocessing.cpu_count()
workers = min(cpu_count * 2 + 1, 5)  # Max 5 workers for resource efficiency
worker_class = "sync"
worker_connections = 1000
timeout = 60
keepalive = 5

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
