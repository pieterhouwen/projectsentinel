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
response=$(curl -u $gotify_username:$gotify_password https://$gotify_server/application | jq)
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

# If I make everything a comment no one will see it, right?
# Took me 5 hours to comment below out and move to a different approach.

# appall=$(echo $response | tr "," "\n" | tr -d "\{\}\[\]\"")
# appid=$(echo $response | tr "," "\n" | tr -d "\{\}\[\]\"" | grep id | cut -d ":" -f 2)
# apptoken=$(echo $response | tr "," "\n" | tr -d "\{\}\[\]\"" | grep token | cut -d ":" -f 2)
# appname=$(echo $response | tr "," "\n" | tr -d "\{\}\[\]\"" | grep name | cut -d ":" -f 2)
# appdesc=$(echo $response | tr "," "\n" | tr -d "\{\}\[\]\"" | grep description | cut -d ":" -f 2)

# Now let's make the output prettier, let's build a nice menu to choose from.



function buildmenu () {
echo \#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#
N=0
for i in $(echo $response | tr "," "\n" | tr -d "\{\}\[\]\"" | grep id | cut -d ":" -f 2 | tr " " "\n" )
do
N=$(expr $N + 1)
echo Option $N is: $i
done
echo \#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#
}

function getapptoken() {
echo Your currently active applications are:
curl -u $gotify_username:$gotify_password https://$gotify_server/application | jq
read -p "Please enter your app token: " apptoken
}
getapptoken

function testapptoken() {
echo Apptoken set to $apptoken .
echo Trying to send message using apptoken
testresponse=$(curl -X POST https://$gotify_server/message?token=$apptoken -F "title=Testnotification" -F "message=If you're seeing this the app is correctly configured" -F "priority=8" >/dev/null)
if echo $testresponse | grep "provide a valid access token"; then
echo Invalid token set!
getapptoken
testapptoken
fi
}
testapptoken

# Let's create a menu for our sevices

funciton enablesshnotifications() {

}

buildmenu "SSH login detection" "SMART notifications"
read -p "Please select your desired service" menunumber
case $menunumber in
  1)
#  enablesshnotifications
  ;;
  2)
#  enablesmartnotifications
  ;;
esac
