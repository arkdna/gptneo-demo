#cloud-config
users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ${ssh_public_key}

package_update: true
package_upgrade: true

packages:
  - python3
  - python3-pip
  - python3-venv
  - nginx
  - supervisor
  - git

write_files:
  - path: /home/ubuntu/app/requirements.txt
    content: |
      flask==2.0.1
      torch==2.5.1
      transformers==4.30.2
      requests==2.31.0
      numpy==1.24.3

  - path: /home/ubuntu/app/config/nginx/gptneo
    content: |
      server {
          listen 80;
          server_name _;
          location / {
              proxy_pass http://localhost:5000;
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
          }
      }

  - path: /home/ubuntu/app/config/supervisor/gptneo.conf
    content: |
      [program:gptneo]
      directory=/home/ubuntu/app
      command=/home/ubuntu/app/venv/bin/python src/app.py
      user=ubuntu
      autostart=true
      autorestart=true

runcmd:
  # Clone the application repository
  - su - ubuntu -c "git clone https://github.com/arkdna/gptneo-demo.git /home/ubuntu/app"
  
  # Set up Python environment and install dependencies
  - su - ubuntu -c "cd /home/ubuntu/app && python3 -m venv venv"
  - su - ubuntu -c "cd /home/ubuntu/app && . venv/bin/activate && pip install --upgrade pip"
  - su - ubuntu -c "cd /home/ubuntu/app && . venv/bin/activate && pip install -r requirements.txt"
  
  # Configure nginx and supervisor
  - cp /home/ubuntu/app/config/nginx/gptneo /etc/nginx/sites-available/
  - ln -s /etc/nginx/sites-available/gptneo /etc/nginx/sites-enabled/
  - rm -f /etc/nginx/sites-enabled/default
  - cp /home/ubuntu/app/config/supervisor/gptneo.conf /etc/supervisor/conf.d/
  
  # Set permissions
  - chown -R ubuntu:ubuntu /home/ubuntu/app
  
  # Start services
  - systemctl restart nginx
  - systemctl enable supervisor
  - systemctl restart supervisor
  
  # Configure UFW (firewall)
  - ufw allow 22/tcp
  - ufw allow 80/tcp
  - ufw --force enable