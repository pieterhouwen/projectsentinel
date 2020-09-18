#!/bin/bash
echo Use this file if you already have a gotify server up and running.
echo
echo For starters we need to declare some variables
echo
echo Please enter FQDN of the host that is running Gotify
read gotify_server
echo Selected $gotify_server
#echo Please enter port (will default to 443 if left blank)
#read gotify_port
#if [[ -z $gotify_port ]]; then
#  $gotify_addr="https://$gotify_server"
#fi
function readuserinfo() {
  read -p "Username:" gotify_username
  echo
  read -sp Password: gotify_password
  echo
  read -sp "Again to confirm:" gotify_password_conf
  echo
  if [[ $gotify_password != $gotify_password_conf ]];then
    echo Passwords don\'t match!
    echo
    readuserinfo
  fi
}
readuserinfo
echo Trying to login using specified details
response=$(curl -u $gotify_username:$gotify_password https://$gotify_server/application)
if echo $response | grep Unauthorized >/dev/null; then
  echo Wrong username or password!
  echo Please try again.
  readuserinfo
elif echo $response | grep "Could not resolve host" >/dev/null; then
  echo Invalid host selected! Please select a different host!
  exit 1
elif [[ ! echo $response | grep token ]]; then
  echo Unknown error occured
  exit 1
else
  echo Login succesful
fi

# Declare some variables
appid=$(echo $response | cut -d "," -n )

# Now let's make the output prettier, let's build a nice menu to choose from.

function buildmenu () {
echo \#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#
N=0
for i in "$@"
do
N=$(expr $N + 1)
echo Option $N is: $i
done
echo \#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#
}
