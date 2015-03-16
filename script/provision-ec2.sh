#!/bin/bash

# Boot an hvm-ssd instance:
# Browse to https://cloud-images.ubuntu.com/utopic/current/
# And choose to "Launch" the us-east-1 / 64-bit / hvm-ssd instance
#
# Choose:
# * t2.micro
# * "plugins" VPC, "plugin-stupid-entities" subnet (for instance)
# * Tag: "plugin-stupid-entities"
# * Shutdown behavior: terminate
#
# Security group:
# * SSH from anywhere
# * HTTPS from anywhere
# * HTTP from anywhere
#
# Choose your own keypair. (Each plugin will have its own keys.)
#
# Then scp this script in and run it!

sudo apt-get update -q
sudo apt-get -q -yy install nodejs-legacy npm git haproxy
sudo useradd -d /opt/pm2 -s /bin/bash -mrU pm2
sudo mkdir -p /opt/pm2/.ssh
sudo cp ~/.ssh/authorized_keys /opt/pm2/.ssh/
sudo chown pm2:pm2 /opt/pm2 -R

cat <<EOT | sudo tee /etc/haproxy/haproxy.cfg
global
  log /dev/log  local0
  log /dev/log  local1 notice
  chroot /var/lib/haproxy
  stats socket /run/haproxy/admin.sock mode 660 level admin
  stats timeout 30s
  user haproxy
  group haproxy
  daemon

  # Default SSL material locations
  ca-base /etc/ssl/certs
  crt-base /etc/ssl/private

  # Default ciphers to use on SSL-enabled listening sockets.
  # For more information, see ciphers(1SSL).
  ssl-default-bind-ciphers ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:ECDH+3DES:DH+3DES:RSA+AESGCM:RSA+AES:RSA+3DES:!aNULL:!MD5:!DSS
  tune.ssl.default-dh-param 2048

defaults
  log global
  mode  http
  option  httplog
  option  dontlognull
  timeout connect 5000
  timeout client  50000
  timeout server  50000
  errorfile 400 /etc/haproxy/errors/400.http
  errorfile 403 /etc/haproxy/errors/403.http
  errorfile 408 /etc/haproxy/errors/408.http
  errorfile 500 /etc/haproxy/errors/500.http
  errorfile 502 /etc/haproxy/errors/502.http
  errorfile 503 /etc/haproxy/errors/503.http
  errorfile 504 /etc/haproxy/errors/504.http

backend plugin-backend
  option forwardfor
  http-request add-header X-Forwarded-Proto https if { ssl_fc }
  server plugin-server localhost:9001

frontend http-frontend
  bind *:80
  redirect scheme https code 301 if !{ ssl_fc }

frontend https-frontend
  bind *:443 ssl crt /etc/haproxy/ssl-cert.pem
  default_backend plugin-backend
EOT

cat <<EOT | sudo tee /etc/default/haproxy
ENABLED=1
EOT
sudo /etc/init.d/haproxy start

# Then, on the server:
#
# 1. Copy the SSL certificate and chain (all one big file) to
#    /etc/haproxy/ssl-cert.pem owned by root/root, chmod 600
# 2. sudo /etc/init.d/haproxy restart
# 3. Add deployers /opt/pm2/.ssh/authorized_keys
#
# Then, on a development machine:
#
# 1. npm install -g pm2 (once per dev machine)
# 2. pm2 deploy ecosystem.json production setup (once per EC2 instance)
# 3. pm2 deploy ecosystem.json production (once per deploy)
