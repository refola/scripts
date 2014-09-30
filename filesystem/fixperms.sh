#!/bin/bash

# Does not work...
#cmds="
#sudo chown -R gaming:gaming /home/gaming
#sudo chmod -R g+u /home/gaming
#sudo chown -R :users /home/shared
#sudo chmod -R go+u /home/shared
#sudo chown -R mark:mark /home/mark
#"

echo "Fixing permissions for proper access to stuff...."

#for cmd in $cmds
#do
#	echo "$cmd"
#	"$cmd"
#done

echo "sudo chown -R gaming:gaming /home/gaming"
sudo chown -R gaming:gaming /home/gaming

echo "sudo chmod -R go=u /home/gaming"
sudo chmod -R go=u /home/gaming

echo "sudo chown -R minecraft:minecraft /home/minecraft"
sudo chown -R minecraft:minecraft /home/minecraft

echo "sudo chmod -R g=u /home/minecraft"
sudo chmod -R g=u /home/minecraft

echo "sudo chown -R :users /home/shared"
sudo chown -R :users /home/shared

echo "sudo chmod -R go=u /home/shared"
sudo chmod -R go=u /home/shared

echo "sudo chown -R mark:mark /home/mark"
sudo chown -R mark:mark /home/mark

echo "sudo chmod -R g=u /home/mark"
sudo chmod -R g=u /home/mark

exit
