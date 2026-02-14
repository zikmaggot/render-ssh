FROM ubuntu:22.04

# Cài đặt hệ thống + SSH + cron + tools
RUN apt-get update && \
    apt-get install -y openssh-server python3 python3-pip curl nano vim htop net-tools git cron && \
    mkdir -p /var/run/sshd && \
    mkdir -p /var/log && \
    echo 'root:admin123' | chpasswd && \
    sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config && \
    # Tạo host keys (rất quan trọng!)
    ssh-keygen -A && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Cài Python app
WORKDIR /app
COPY requirements.txt .
RUN pip3 install -r requirements.txt
COPY app.py .

# Cài Ngrok
RUN curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | \
    tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && \
    echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | \
    tee /etc/apt/sources.list.d/ngrok.list && \
    apt-get update && apt-get install -y ngrok

# Copy script + cron
COPY start.sh /start.sh
COPY cron-keepalive /etc/cron.d/keepalive

RUN chmod +x /start.sh
RUN chmod 0644 /etc/cron.d/keepalive
RUN crontab /etc/cron.d/keepalive

# Tạo log + quyền
RUN touch /var/log/sshd.log && chmod 666 /var/log/sshd.log

EXPOSE 10000 22

CMD ["/start.sh"]
