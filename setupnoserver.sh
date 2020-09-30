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
else
  echo Login succesful
fi

# Declare some variables
appall=$(echo $response | tr "," "\n" | tr -d "\{\}\[\]\"")
appid=$(echo $response | tr "," "\n" | tr -d "\{\}\[\]\"" | grep id | cut -d ":" -f 2)
apptoken=$(echo $response | tr "," "\n" | tr -d "\{\}\[\]\"" | grep token | cut -d ":" -f 2)
appname=$(echo $response | tr "," "\n" | tr -d "\{\}\[\]\"" | grep name | cut -d ":" -f 2)
appdesc=$(echo $response | tr "," "\n" | tr -d "\{\}\[\]\"" | grep description | cut -d ":" -f 2)

# Now let's make the output prettier, let's build a nice menu to choose from.


echo \#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#
N=0
for i in "${appall[@]}"
do
echo Option $N is: $i
echo Application name: $appname[$N]
echo Application description: $appdesc[$N]
echo Application token: $apptoken[$N]
N=$(expr $N + 1)
done
echo \#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#
