#!/bin/bash

# First check privileges
if [[ $(id -u) -gt 0 ]]; then
  echo Please run as root!
  exit 1
fi

function RTFM() {
  echo Usage: setup.sh -w [webserver] -s [ssl] -n [hostname] -h [help]
  echo
  printf "-w        Use specified webserver. Accepted inputs are: apache2 or nginx"
  printf "-s        Use SSL"
  printf "-n        Use specified hostname, this needs to be a internet-reachable FQDN"
  printf "-h        Show this help"
  echo
  echo "This program will check for (and install if necessery) the following programs:"
  echo
  echo "- Docker \(will be installed from the official repository\)"
  echo "- Apache2/nginx"
  echo "- JQ"
  echo "- bind \(used for nslookup\)"
  echo "- Certbot \(if SSL is used\)"
  exit 1
}

while getopts ":w:sn:h" args
do
case $args in
  w)
  if [[ $OPTARG == "apache2" ]]; then
    webserver=apache2
  elif [[ $OPTARG == "nginx" ]]; then
    webserver=nginx
  else
    echo Invalid input!
    exit 1
  fi
  ;;
  s)
  usessl=true
  ;;
  n)
  server=$OPTARG
  ;;
  h)
  RTFM
  exit 1
  ;;
  *)
  echo Invalid input! Please RTFM.
  RFTM
  exit 1
  ;;
esac
done

# Check what system we are running on
if [[ -e /usr/bin/apt ]]; then
installpkg='apt install -y'
elif [[ -e /usr/bin/pacman ]]; then
  querypkg="pacman -Q"
  installpkg="pacman -S"
fi

# Check installation of Docker
if [[ -e /usr/bin/docker ]]; then
  echo Found docker
else
  echo Installing Docker, please wait...
  curl https://get.docker.com | /bin/sh
fi

# Check for installation of net-utils
if [[ -e /usr/bin/nslookup ]]; then
  echo Found nslookup
else
  $installpkg bind
fi

# Check for JQ
echo installing JQ.
$installpkg jq

if [[ $webserver == "nginx" ]]; then
  # Check for nginx
  if $querypkg nginx >/dev/null; then
    # Looks like nginx was found
    echo Found nginx
  else
    $installpkg nginx
    # Arch Linux does not create these dirs by default
    mkdir /etc/nginx/sites-available 2>/dev/null
    mkdir /etc/nginx/sites-enabled 2>/dev/null
    systemctl enable --now nginx
  fi
elif [[ $webserver == "apache2" ]]; then
  # Check for Apache2
  if [[ -d /etc/apache2 ]]; then 
    echo Found Apache2
  else
    $installpkg apache2
  fi
fi

if [[ -n $server ]]; then
  echo Please enter your FQDN on which to publish the push server.
  read server
fi

if nslookup $server >/dev/null; then
  echo Found domain.
else
  echo Domain not found, please try again.
  exit 1
fi

if [[ $webserver == "nginx" ]]; then
  echo Writing nginx conf
  cat <<EOF >/etc/nginx/sites-available/$server.conf
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
  ln -s /etc/nginx/sites-available/$server.conf /etc/nginx/sites-enabled/$server.conf
  systemctl restart nginx
elif [[ $webserver == "apache2" ]]; then
  echo Writing apache conf
  cat <<EOF >/etc/apache2/sites-available/$server.conf
  <VirtualHost $server:80>
      # The ServerName directive sets the request scheme, hostname and port that
      # the server uses to identify itself. This is used when creating
      # redirection URLs. In the context of virtual hosts, the ServerName
      # specifies what hostname must appear in the request's Host: header to
      # match this virtual host. For the default virtual host (this file) this
      # value is not decisive as it is used as a last resort host regardless.
      # However, you must set it for any further virtual host explicitly.
      ServerName $server

      ServerAdmin webmaster@localhost
      DocumentRoot /var/www/html

      # Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
      # error, crit, alert, emerg.
      # It is also possible to configure the loglevel for particular
      # modules, e.g.
      #LogLevel info ssl:warn

      ErrorLog \${APACHE_LOG_DIR}/error.log
      CustomLog \${APACHE_LOG_DIR}/access.log combined

      # For most configuration files from conf-available/, which are
      # enabled or disabled at a global level, it is possible to
      # include a line for only one particular virtual host. For example the                                                                                                                                                                       # following line enables the CGI configuration for this host only                                                                                                                                                                            # after it has been globally disabled with "a2disconf".                                                                                                                                                                                      #Include conf-available/serve-cgi-bin.conf
</VirtualHost>
EOF
ln -s /etc/apache2/sites-available/$server.conf /etc/apache2/sites-enabled/$server.conf
service apache2 restart
fi

if [[ $usessl == "true" ]] && [[ $webserver == "apache2" ]] ; then
  if [[ -e /usr/bin/certbot ]]; then
    echo Found certbot
    echo Running certbot
    if certbot --apache; then
      sslsuccess="true"
    else
      sslsuccess="false"
    fi
  else
    echo Installing certbot for apache2
    if [[ -e /usr/bin/apt ]]; then
      # Check for existence of snap
      $installpkg snapd
    snap install core
    snap refresh core
    snap install --classic certbot
    ln -s /snap/bin/certbot /usr/bin/certbot
    if certbot --apache; then
      sslsuccess="true"
    else
      sslsuccess="false"
    fi
  else
    cd /opt
    git clone https://aur.archlinux.org/snapd.git
    cd snapd
    makepkg -si
    systemctl enable --now snapd.socket
    ln -s /var/lib/snapd/snap /snap
    source /etc/bash.bashrc
    snap install core
    snap refresh core
    snap install --classic certbot
    ln -s /snap/bin/certbot /usr/bin/certbot
    if certbot --apache; then
      sslsuccess="true"
    else
      sslsuccess="false"
    fi
  fi
  elif [[ $usessl == "true" ]] && [[ $webserver == "nginx" ]]; then
    if [[ -e /usr/bin/apt ]]; then
    # Check for existence of snap
      $installpkg snapd
    install core
    snap refresh core
    snap install --classic certbot
    ln -s /snap/bin/certbot /usr/bin/certbot
    if certbot --nginx; then
      sslsuccess="true"
    else
      sslsuccess="false"
    fi
  else
    cd /opt
    git clone https://aur.archlinux.org/snapd.git
    cd snapd
    makepkg -si
    systemctl enable --now snapd.socket
    ln -s /var/lib/snapd/snap /snap
    source /etc/bash.bashrc
    snap install core
    snap refresh core
    snap install --classic certbot
    ln -s /snap/bin/certbot /usr/bin/certbot
    if certbot --nginx; then
      sslsuccess="true"
    else
      sslsuccess="false"
    fi
  fi
fi

echo Starting server
docker run -p 12345:80 -d -v /opt/projectsentinel/data:/app/data --restart=always gotify/server
echo Sleeping 30 seconds to fully start gotify.
sleep 30
echo Grabbing service template

if [[ -e /usr/bin/systemd ]]; then
    wget https://pieterhouwen.info/zooi/servicetemplate.txt -O /tmp/servicetemplate
    sed -i 's/dir=""/dir=\/opt\/projectsentinel/' /tmp/servicetemplate
    sed -i 's/cmd=""/cmd=\/opt\/projectsentinel\/accepted.sh/' /tmp/servicetemplate
    sed -i 's/user=""/user=root/' /tmp/servicetemplate
    sed -i 's/shortdesc/Login Notifications/' /tmp/servicetemplate
    sed -i 's/longdesc/Sends login notifications to mobile phone/' /tmp/servicetemplate
    echo Installing and enabling service
    mv /tmp/servicetemplate /etc/init.d/loginpush
    chmod +x /etc/init.d/loginpush
    update-rc.d loginpush defaults
    service loginpush start
    echo If all was well the daemon should be active and started at boot.

elif [[ -d /lib/systemd/system ]]; then
    wget https://pieterhouwen.info/zooi/systemctltemplate.txt -O /tmp/systemctltemplate
    sed -i 's/command/\/opt\/projectsentinel\/accepted.sh' /tmp/systemctltemplate
    sed -i 's/desk/Sends push notifications to phone' /tmp/systemctltemplate
    echo Installing and enabling service
    mv /tmp/systemctltemplate /lib/systemd/system/loginpush
    systemctl enable loginpush

fi

# Begin Gotify configuration
# Update default Password
newpass=$RANDOM$RANDOM$RANDOM
if [[ $sslsuccess = "true" ]]; then
curl -u admin:admin https://$server/current/user/password -F "pass=$newpass"
echo Admin password has changed to $newpass.
echo Creating a default application
curl -u admin:$newpass -X POST https://$server/application -F "description=Sends login notifications to your phone" -F "name=loginpush" | jq
echo To link your phone with the server, open your gotify app and login to $server
elif [[ $sslsuccess = "false" ]]; then
  curl -u admin:admin http://$server/current/user/password -F "pass=$newpass"
  echo Admin password has changed to $newpass.
  echo Creating a default application
  curl -u admin:$newpass -X POST http://$server/application -F "description=Sends login notifications to your phone" -F "name=loginpush" | jq
  echo To link your phone with the server, open your gotify app and login to $server
fi
