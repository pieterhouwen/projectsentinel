#!/bin/bash

sendnotification() {
echo "$@"
    /usr/bin/sendpush "$@"
}

while read line;do
    case "$line" in
        *"Accepted"* )
            user=$(echo $line | cut -d " " -f 9)
            ip=$(echo $line | cut -d " " -f 11)
            sendnotification login $user $ip
            ;;
    esac
  done < <(journalctl -ft sshd)
