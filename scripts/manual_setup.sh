#!/bin/bash

# Exit on any error
set -e

echo "Starting manual setup..."

# Update system packages
echo "Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install required packages
echo "Installing required packages..."
sudo apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-setuptools \
    python3-distutils-extra \
    build-essential \
    nginx \
    supervisor \
    git

# Create app directory if it doesn't exist
echo "Setting up application directory..."
APP_DIR="/home/ubuntu/app"
mkdir -p $APP_DIR

# Clone the repository
echo "Cloning application repository..."
if [ -d "$APP_DIR/.git" ]; then
    echo "Git repository already exists, pulling latest changes..."
    cd $APP_DIR
    git pull
else
    echo "Cloning fresh repository..."
    git clone https://github.com/arkdna/gptneo-demo.git $APP_DIR
fi

# Set up Python virtual environment
echo "Setting up Python virtual environment..."
cd $APP_DIR
python3 -m venv venv --without-pip
source venv/bin/activate
curl https://bootstrap.pypa.io/get-pip.py | python3
pip install --upgrade pip setuptools wheel
pip install -r app/requirements.txt

# Configure Nginx
echo "Configuring Nginx..."
sudo tee /etc/nginx/sites-available/gptneo << EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable Nginx site
sudo ln -sf /etc/nginx/sites-available/gptneo /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Configure Supervisor
echo "Configuring Supervisor..."
sudo tee /etc/supervisor/conf.d/gptneo.conf << EOF
[program:gptneo]
directory=/home/ubuntu/app
command=/home/ubuntu/app/venv/bin/python src/app.py
user=ubuntu
autostart=true
autorestart=true
stderr_logfile=/var/log/gptneo.err.log
stdout_logfile=/var/log/gptneo.out.log
EOF

# Set correct permissions
echo "Setting permissions..."
sudo chown -R ubuntu:ubuntu $APP_DIR

# Configure firewall
echo "Configuring firewall..."
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw --force enable

# Restart services
echo "Restarting services..."
sudo systemctl restart nginx
sudo systemctl enable supervisor
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl restart all

# Final status check
echo "Checking service status..."
sudo systemctl status nginx --no-pager
sudo supervisorctl status

echo "Setup complete! You can check the application logs at:"
echo "- Nginx error log: /var/log/nginx/error.log"
echo "- Application logs: /var/log/gptneo.{err,out}.log"
echo "- Supervisor logs: /var/log/supervisor/supervisord.log"

# Print the IP address for easy access
echo "Your server IP address is:"
hostname -I | awk '{print $1}' 