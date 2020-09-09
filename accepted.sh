#!/bin/bash

sendnotification() {
echo "$@"
    /usr/bin/sendpush "$@"
}

while read line;do
    case "$line" in
        *"Accepted"* )
            user=$(echo $line | cut -d " " -f 4)
            ip=$(echo $line | cut -d " " -f 6)
            sendnotification login $user $ip
            ;;
    esac
  done < <(journalctl -ft sshd)
