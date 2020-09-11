#!/bin/bash
# Test
# First check privileges
if [[ $(id -u) -lt 0 ]]; then
  echo Please run as root!
  exit 1
fi

echo Updating package repository
apt update -q

# Check installation of Docker
if dpkg --get-selections | grep docker >/dev/null; then
  # Looks like docker is installed
  echo Found docker
else
  echo Installing Docker, please wait...
  curl https://get.docker.com | /bin/sh
fi
  # Check for nginx
if dpkg --get-selections | grep nginx >/dev/null; then
    # Looks like nginx was found
    echo Found nginx
  else
    apt install nginx -y
    systemctl enable --now nginx
fi
  echo Please enter your FQDN on which to publish the push server.
  read server
  echo Writing nginx conf
  cat <<EOF >>/etc/nginx.conf
  server {

  # Here goes your domain / subdomain
  server_name $server;

  location / {
    # We set up the reverse proxy
    proxy_pass         http://localhost:12345;
    proxy_http_version 1.1;

    # Ensuring it can use websockets
    proxy_set_header   Upgrade \$http_upgrade;
    proxy_set_header   Connection "upgrade";
    proxy_set_header   X-Real-IP \$remote_addr;
    proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header   X-Forwarded-Proto http;
    proxy_redirect     http:// \$scheme://;

    # The proxy must preserve the host because gotify verifies the host with the origin
    # for WebSocket connections
    proxy_set_header   Host \$http_host;

    # These sets the timeout so that the websocket can stay alive
    proxy_connect_timeout   7m;
    proxy_send_timeout      7m;
    proxy_read_timeout      7m;
  }
EOF
  echo Grabbing service template
  wget https://pieterhouwen.info/zooi/servicetemplate.txt -O /tmp/servicetemplate
  set -i 's/dir=""/dir="/opt/projectsentinel"'
  echo Starting server
  docker run -p 12345:80 -v /var/gotify/data:/app/data gotify/server
