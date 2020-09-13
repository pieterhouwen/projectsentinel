#!/bin/bash
echo Use this file if you already have a gotify server up and running.
echo
echo For starters we need to declare some variables
echo
echo Please enter FQDN of the host that is running Gotify
read gotify_server
echo Selected $gotify_server
echo Please enter port (will default to 443 if left blank)
read gotify_port
if [[ -z $gotify_port ]]; then
  $gotify_port = "443"
fi

echo
