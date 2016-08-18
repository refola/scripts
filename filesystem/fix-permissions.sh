#!/bin/bash

cmds="
sudo chmod -R g=u /home/kelci
sudo chown -R kelci:kelci /home/kelci
sudo chmod -R g=u /home/mark
sudo chown -R mark:mark /home/mark
sudo chmod -R g=u /home/minecraft
sudo chown -R mark:mark /home/minecraft
sudo chmod -R go=u /shared
sudo chown -R :users /shared
"

echo "Fixing permissions for proper access to stuff...."

IFS=$'\n'
for cmd in $cmds; do
    echo "$cmd"
    eval "$cmd"
done
