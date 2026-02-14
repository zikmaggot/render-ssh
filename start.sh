#!/bin/bash

echo "=== VPS STARTUP ==="

# 1. Khởi động SSHD trực tiếp (background + log)
echo "Starting SSHD..."
/usr/sbin/sshd -D -e >> /var/log/sshd.log 2>&1 &

# Đợi 3 giây để SSHD khởi động
sleep 3

# Kiểm tra SSHD có chạy không
if pgrep sshd > /dev/null; then
    echo "SSHD is RUNNING (PID: $(pgrep sshd))"
else
    echo "SSHD FAILED! Check /var/log/sshd.log"
    cat /var/log/sshd.log
    exit 1
fi

# Kiểm tra port 22
if ss -tlnp | grep -q ":22"; then
    echo "SSH LISTENING on port 22"
else
    echo "PORT 22 NOT OPEN!"
    ss -tlnp
fi

# 2. Khởi động cron
echo "Starting cron..."
cron

# 3. Khởi động Flask
echo "Starting Flask on port 10000..."
gunicorn --bind 0.0.0.0:10000 app:app &

# 4. Khởi động Ngrok TCP tunnel
echo "Starting Ngrok TCP tunnel (port 22)..."
ngrok tcp 22 --log=stdout

# Giữ container chạy
tail -f /dev/null
